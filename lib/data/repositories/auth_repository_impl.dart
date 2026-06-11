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
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.user == null) {
      throw AppException('Sign in failed');
    }
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName, 'phone': phone},
    );
    if (response.user == null) {
      throw AppException('Sign up failed');
    }
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

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
}
