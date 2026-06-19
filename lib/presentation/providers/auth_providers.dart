import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/profile.dart';
import 'repository_providers.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.session?.user;
});

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.watch(authRepositoryProvider).getProfile(user.id);
});

final hasPaidProvider = Provider<bool>((ref) {
  return ref.watch(userProfileProvider).valueOrNull?.hasPaid ?? false;
});

final isAdminProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return ref.watch(authRepositoryProvider).isAdmin(user.id);
});

/// Tracks if the user has dismissed the unlock screen for the current session.
final unlockSkippedProvider = StateProvider<bool>((ref) => false);
