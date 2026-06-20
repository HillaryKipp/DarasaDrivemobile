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
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      throw AppException(_mapAuthError(e));
    } catch (e) {
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
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'phone': phone},
        emailRedirectTo: 'darasadrive://login-callback',
      );
      return response.session == null;
    } on AuthException catch (e) {
      throw AppException(_mapAuthError(e));
    } catch (e) {
      throw AppException('Sign up failed. Please try again.');
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email, redirectTo: 'darasadrive://login-callback');
    } catch (e) {
      throw AppException('Failed to send reset link.');
    }
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<UserProfile> getProfile(String userId) async {
    final data = await _client.from('profiles').select().eq('id', userId).single();
    return profileFromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<bool> isAdmin(String userId) async {
    final roles = await _client.from('user_roles').select('role').eq('user_id', userId);
    return (roles as List).any((r) => r['role'] == 'admin');
  }

  @override
  Stream<UserProfile> watchProfile(String userId) {
    return _client.from('profiles').stream(primaryKey: ['id']).eq('id', userId).map((rows) {
      if (rows.isEmpty) throw AppException('Profile not found');
      return profileFromJson(Map<String, dynamic>.from(rows.first));
    });
  }

  @override
  Future<void> markAsPaid(String userId, {String? transactionId, double? amount}) async {
    developer.log('markAsPaid: START userId=$userId txId=$transactionId', name: 'AuthRepo');
    
    // Check session first
    if (_client.auth.currentSession == null) {
      developer.log('markAsPaid: ERROR - No active session', name: 'AuthRepo');
      throw AppException('Your session has expired. Please sign in again.');
    }

    try {
      // 1. Update Profile has_paid status
      // We use a simple update and check if it worked. 
      // Avoiding .select().single() because it can hang if RLS results in 0 rows.
      developer.log('markAsPaid: Attempting profile update...', name: 'AuthRepo');
      
      final result = await _client
          .from('profiles')
          .update({'has_paid': true})
          .eq('id', userId)
          .select('id, has_paid')
          .timeout(const Duration(seconds: 15));
      
      if (result.isEmpty) {
        developer.log('markAsPaid: ERROR - No profile updated (empty result)', name: 'AuthRepo');
        throw AppException('Profile not found or you do not have permission to update it.');
      }
      
      developer.log('markAsPaid: Profile update SUCCESS', name: 'AuthRepo');

      // 2. Log Payment (Non-fatal, but we try anyway)
      if (transactionId != null) {
        developer.log('markAsPaid: Logging payment record...', name: 'AuthRepo');
        await _client.from('payments').insert({
          'user_id': userId,
          'amount': amount?.toInt() ?? 500,
          'purpose': 'account_unlock',
          'transaction_id': transactionId,
          'status': 'completed',
        }).timeout(const Duration(seconds: 10));
        developer.log('markAsPaid: Payment record SUCCESS', name: 'AuthRepo');
      }
    } on AppException {
      rethrow;
    } catch (e) {
      developer.log('markAsPaid: UNEXPECTED ERROR: $e', name: 'AuthRepo');
      throw AppException('Failed to sync payment status. Please try again. ($e)');
    }
    
    developer.log('markAsPaid: FINISHED', name: 'AuthRepo');
  }

  @override
  Future<void> deleteAccount(String userId) async {
    await _client.rpc('delete_user');
    await signOut();
  }

  String _mapAuthError(AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('email not confirmed')) return 'Please verify your email first.';
    if (message.contains('invalid login credentials')) return 'Incorrect email or password.';
    return e.message;
  }
}
