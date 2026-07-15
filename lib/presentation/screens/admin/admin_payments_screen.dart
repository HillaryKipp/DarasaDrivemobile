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
    final dateFmt = DateFormat('MMM d, yyyy • HH:mm');

    return AdminScaffold(
      title: 'Payments',
      body: paymentsAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
            error: e,
            onRetry: () => ref.invalidate(adminPaymentsProvider)),
        data: (payments) => ListView(
          children: [
            AdminBanner(
              icon: Icons.payments_outlined,
              title: 'Payments',
              subtitle: '${payments.length} transaction${payments.length == 1 ? '' : 's'} recorded',
              trailingIcon: Icons.receipt_long_outlined,
            ),
            if (payments.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: Text('No payment records found')),
              )
            else ...[
              const AdminSectionLabel(text: 'Transactions'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    for (int i = 0; i < payments.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      AdminListTile(
                        icon: Icons.receipt_outlined,
                        title: 'Ksh ${payments[i].amount} · ${payments[i].status}',
                        subtitle: [
                          if (payments[i].email != null) payments[i].email!,
                          if (payments[i].phone != null) payments[i].phone!,
                          if (payments[i].mpesaReceipt != null)
                            payments[i].mpesaReceipt!,
                          if (payments[i].createdAt != null)
                            dateFmt.format(payments[i].createdAt!),
                        ].join(' · '),
                        trailing: _StatusBadge(status: payments[i].status),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final isSuccess = status.toLowerCase() == 'success' ||
        status.toLowerCase() == 'completed';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isSuccess ? const Color(0xFFDCFCE7) : const Color(0xFFFEF9C3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isSuccess ? kAdminGreen : const Color(0xFF92400E),
        ),
      ),
    );
  }
}