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
    developer.log('--- DB SYNC START ---', name: 'AuthRepo');
    
    if (_client.auth.currentSession == null) {
      throw AppException('Your session has expired. Please sign in again.');
    }

    try {
      // 1. Try secure RPC first
      developer.log('Attempting RPC confirm_payment...', name: 'AuthRepo');
      await _client.rpc('confirm_payment', params: {'user_id_input': userId}).timeout(const Duration(seconds: 12));
      developer.log('RPC update SUCCESS', name: 'AuthRepo');
      
    } on PostgrestException catch (e) {
      developer.log('DB ERROR: ${e.message} (Code: ${e.code})', name: 'AuthRepo');
      
      // If the RPC fails because it doesn't exist, try direct update as fallback
      if (e.message.contains('function') && e.message.contains('does not exist')) {
        developer.log('RPC not found, trying direct update fallback...', name: 'AuthRepo');
        await _client
            .from('profiles')
            .update({'has_paid': true})
            .eq('id', userId)
            .timeout(const Duration(seconds: 10));
      } else if (e.code == 'P0001' || e.message.contains('Not allowed to modify payment status')) {
        throw AppException('Account unlock blocked by database trigger. Please remove the restriction trigger from the "profiles" table in Supabase.');
      } else {
        rethrow;
      }
    }

    // 2. Log Payment record (non-fatal)
    if (transactionId != null) {
      _client.from('payments').insert({
        'user_id': userId,
        'amount': amount?.toInt() ?? 500,
        'purpose': 'account_unlock',
        'transaction_id': transactionId,
        'status': 'completed',
      }).timeout(const Duration(seconds: 5)).catchError((e) {
        developer.log('Payment logging non-fatal error: $e', name: 'AuthRepo');
      });
    }
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
