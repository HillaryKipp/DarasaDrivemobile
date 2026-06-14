import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/admin_providers.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import 'admin_helpers.dart';

class AdminPaymentsScreen extends ConsumerWidget {
  const AdminPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(adminPaymentsProvider);

    return AdminScaffold(
      title: 'Payments',
      body: paymentsAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(adminPaymentsProvider),
        ),
        data: (payments) {
          if (payments.isEmpty) {
            return const Center(child: Text('No payment records found'));
          }
          final dateFmt = DateFormat('MMM d, yyyy • HH:mm');
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final p = payments[index];
              return Card(
                child: ListTile(
                  title: Text('Ksh ${p.amount} • ${p.status}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (p.email != null) Text(p.email!),
                      if (p.phone != null) Text(p.phone!),
                      if (p.purpose != null) Text('Purpose: ${p.purpose}'),
                      if (p.mpesaReceipt != null) Text('Receipt: ${p.mpesaReceipt}'),
                      if (p.createdAt != null) Text(dateFmt.format(p.createdAt!)),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
