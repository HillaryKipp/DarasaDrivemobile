import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/supabase_client_provider.dart';
import '../../data/repositories/admin_repository_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/materials_repository_impl.dart';
import '../../data/repositories/payment_repository_impl.dart';
import '../../data/repositories/schools_repository_impl.dart';
import '../../data/repositories/units_repository_impl.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/materials_repository.dart';
import '../../domain/repositories/payment_repository.dart';
import '../../domain/repositories/schools_repository.dart';
import '../../domain/repositories/units_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(supabaseClientProvider));
});

final unitsRepositoryProvider = Provider<UnitsRepository>((ref) {
  return UnitsRepositoryImpl(ref.watch(supabaseClientProvider));
});

final schoolsRepositoryProvider = Provider<SchoolsRepository>((ref) {
  return SchoolsRepositoryImpl(ref.watch(supabaseClientProvider));
});

final materialsRepositoryProvider = Provider<MaterialsRepository>((ref) {
  return MaterialsRepositoryImpl(ref.watch(supabaseClientProvider));
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepositoryImpl(ref.watch(supabaseClientProvider));
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepositoryImpl(ref.watch(supabaseClientProvider));
});
