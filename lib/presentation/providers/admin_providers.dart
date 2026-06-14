import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/admin_user.dart';
import '../../domain/entities/payment_record.dart';
import '../../domain/entities/question.dart';
import 'data_providers.dart';
import 'repository_providers.dart';

final adminUsersProvider = FutureProvider<List<AdminUser>>((ref) {
  return ref.watch(adminRepositoryProvider).getAllUsers();
});

final adminPaymentsProvider = FutureProvider<List<PaymentRecord>>((ref) {
  return ref.watch(adminRepositoryProvider).getPayments();
});

final adminQuestionsProvider =
    FutureProvider.family<List<Question>, String>((ref, unitId) {
  return ref.watch(adminRepositoryProvider).getQuestions(unitId);
});
