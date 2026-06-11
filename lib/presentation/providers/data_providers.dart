import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/booking.dart';
import '../../domain/entities/material_item.dart';
import '../../domain/entities/school.dart';
import '../../domain/entities/test_attempt.dart';
import '../../domain/entities/unit.dart';
import 'auth_providers.dart';
import 'repository_providers.dart';

final unitsProvider = FutureProvider<List<Unit>>((ref) {
  return ref.watch(unitsRepositoryProvider).getUnits();
});

final unitProvider = FutureProvider.family<Unit, String>((ref, id) {
  return ref.watch(unitsRepositoryProvider).getUnit(id);
});

final schoolsProvider = FutureProvider<List<School>>((ref) {
  return ref.watch(schoolsRepositoryProvider).getSchools();
});

final schoolProvider = FutureProvider.family<School, String>((ref, id) {
  return ref.watch(schoolsRepositoryProvider).getSchool(id);
});

final materialsProvider = FutureProvider<List<MaterialItem>>((ref) {
  return ref.watch(materialsRepositoryProvider).getMaterials();
});

final userBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(schoolsRepositoryProvider).getUserBookings(user.id);
});

final testAttemptsProvider = FutureProvider<List<TestAttempt>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(unitsRepositoryProvider).getTestAttempts(user.id);
});
