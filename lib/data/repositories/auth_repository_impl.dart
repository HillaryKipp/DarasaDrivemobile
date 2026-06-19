import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/model_parsers.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    developer.log('SignIn attempt for $email', name: 'AuthRepo');
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      developer.log(
        'SignIn success userId=${response.user?.id} '
        'emailConfirmed=${response.user?.emailConfirmedAt != null}',
        name: 'AuthRepo',
      );
      if (response.user == null) {
        throw AppException('Sign in failed');
      }
    } on AuthException catch (e) {
      developer.log(
        'SignIn AuthException status=${e.statusCode} message=${e.message}',
        name: 'AuthRepo',
      );
      throw AppException(_mapAuthError(e));
    } catch (e) {
      developer.log('SignIn error: $e', name: 'AuthRepo');
      if (e is AppException) rethrow;
      throw AppException('Sign in failed. Please try again.');
    }
  }

  @override
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    developer.log('SignUp attempt for $email', name: 'AuthRepo');
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'phone': phone},
        emailRedirectTo: 'darasadrive://login-callback',
      );
      developer.log(
        'SignUp response userId=${response.user?.id} '
        'session=${response.session != null} '
        'message=${response.user?.identities?.length ?? 0} identities',
        name: 'AuthRepo',
      );
      if (response.user == null) {
        throw AppException('Sign up failed');
      }
      // No session means Supabase requires email confirmation first.
      final requiresConfirmation = response.session == null;
      developer.log(
        'SignUp requiresEmailConfirmation=$requiresConfirmation',
        name: 'AuthRepo',
      );
      return requiresConfirmation;
    } on AuthException catch (e) {
      developer.log(
        'SignUp AuthException status=${e.statusCode} message=${e.message}',
        name: 'AuthRepo',
      );
      throw AppException(_mapAuthError(e));
    } catch (e) {
      developer.log('SignUp error: $e', name: 'AuthRepo');
      if (e is AppException) rethrow;
      throw AppException('Sign up failed. Please try again.');
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    developer.log('ResetPassword for $email', name: 'AuthRepo');
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'darasadrive://login-callback',
      );
      developer.log('ResetPassword email sent', name: 'AuthRepo');
    } on AuthException catch (e) {
      developer.log(
        'ResetPassword AuthException status=${e.statusCode} message=${e.message}',
        name: 'AuthRepo',
      );
      throw AppException(_mapAuthError(e));
    } catch (e) {
      developer.log('ResetPassword error: $e', name: 'AuthRepo');
      throw AppException('Failed to send reset link. Please try again.');
    }
  }

  @override
  Future<void> signOut() {
    developer.log('SignOut', name: 'AuthRepo');
    return _client.auth.signOut();
  }

  @override
  Future<UserProfile> getProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return profileFromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<bool> isAdmin(String userId) async {
    final roles = await _client
        .from('user_roles')
        .select('role')
        .eq('user_id', userId);
    return (roles as List).any((r) => r['role'] == 'admin');
  }

  @override
  Stream<UserProfile> watchProfile(String userId) {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((rows) {
          if (rows.isEmpty) {
            throw AppException('Profile not found');
          }
          return profileFromJson(Map<String, dynamic>.from(rows.first));
        });
  }

  @override
  Future<void> markAsPaid(String userId, {String? transactionId, double? amount}) async {
    developer.log('markAsPaid: START userId=$userId txId=$transactionId', name: 'AuthRepo');
    
    // 1. Update Profile has_paid status (Essential)
    try {
      await _client
          .from('profiles')
          .update({'has_paid': true})
          .eq('id', userId)
          .select() 
          .single()
          .timeout(const Duration(seconds: 20));
      developer.log('markAsPaid: Profile update SUCCESS', name: 'AuthRepo');
    } catch (e) {
      developer.log('markAsPaid: Profile update ERROR: $e', name: 'AuthRepo');
      // This failure prevents the app from unlocking. Throw to show error.
      throw AppException('Failed to update account status. (Error: $e)');
    }

    // 2. Log the Payment Record (Non-fatal record keeping)
    if (transactionId != null) {
      try {
        developer.log('markAsPaid: Inserting payment log...', name: 'AuthRepo');
        await _client.from('payments').insert({
          'user_id': userId,
          'amount': amount?.toInt() ?? 500,
          'purpose': 'account_unlock',
          'checkout_request_id': transactionId, 
          'mpesa_receipt': transactionId,      
          'transaction_id': transactionId, // Requires the SQL fix above
          'status': 'completed',
        }).timeout(const Duration(seconds: 15));
        developer.log('markAsPaid: Payment log SUCCESS', name: 'AuthRepo');
      } catch (e) {
        developer.log('markAsPaid: Payment log ERROR (Ignoring): $e', name: 'AuthRepo');
        // We don't throw because the profile was already updated successfully.
      }
    }
    
    developer.log('markAsPaid: FINISHED', name: 'AuthRepo');
  }

  @override
  Future<void> deleteAccount(String userId) async {
    developer.log('Deleting account for: $userId', name: 'AuthRepo');
    try {
      // Calls the SECURITY DEFINER function to delete auth.users
      await _client.rpc('delete_user');
      // Sign out to clear the local app session
      await signOut();
      developer.log('Account deletion success', name: 'AuthRepo');
    } catch (e) {
      developer.log('Error deleting account: $e', name: 'AuthRepo');
      throw AppException('Failed to delete account. (Error: $e)');
    }
  }

  String _mapAuthError(AuthException e) {
    final message = e.message.toLowerCase();
    final code = e.statusCode?.toLowerCase() ?? '';

    if (message.contains('email not confirmed') ||
        code.contains('email_not_confirmed')) {
      return 'Please verify your email first. Check your inbox for the confirmation link, then sign in.';
    }
    if (message.contains('invalid login credentials') ||
        message.contains('invalid credentials')) {
      return 'Incorrect email or password. If you just signed up, verify your email first.';
    }
    if (message.contains('user already registered') ||
        message.contains('already been registered')) {
      return 'An account with this email already exists. Sign in or reset your password.';
    }
    if (message.contains('password')) {
      return e.message;
    }
    return e.message.isNotEmpty ? e.message : 'Authentication failed. Please try again.';
  }
}
