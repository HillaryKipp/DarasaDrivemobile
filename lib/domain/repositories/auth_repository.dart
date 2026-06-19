import 'package:supabase_flutter/supabase_flutter.dart';

import '../entities/profile.dart';

abstract class AuthRepository {
  Stream<AuthState> get authStateChanges;
  User? get currentUser;

  Future<void> signIn({required String email, required String password});
  /// Returns `true` when the user must confirm their email before signing in.
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  });
  Future<void> signOut();

  Future<UserProfile> getProfile(String userId);
  Future<bool> isAdmin(String userId);
  Stream<UserProfile> watchProfile(String userId);

  Future<void> resetPassword(String email);

  /// Updates the user's profile to reflect they have paid.
  Future<void> markAsPaid(String userId, {String? transactionId, double? amount});

  /// Permanently deletes the user's account and data.
  Future<void> deleteAccount(String userId);
}
