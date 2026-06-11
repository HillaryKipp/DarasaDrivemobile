import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/unit.dart';
import '../../providers/auth_providers.dart';
import '../../providers/data_providers.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../home/home_shell.dart';

class UnitsScreen extends ConsumerWidget {
  const UnitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsAsync = ref.watch(unitsProvider);
    final hasPaid = ref.watch(hasPaidProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: GradientHeader(
              badge: 'Tests',
              title: 'NTSA Theory Tests',
              subtitle: 'Pick a unit and practise. 50+ questions per unit.',
            ),
          ),
          unitsAsync.when(
            loading: () => const SliverFillRemaining(child: LoadingView()),
            error: (e, _) => SliverFillRemaining(
              child: ErrorView(
                message: e.toString(),
                onRetry: () => ref.invalidate(unitsProvider),
              ),
            ),
            data: (units) => SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == units.length && !hasPaid) {
                      return _UnlockBanner(onTap: () => context.push('/unlock'));
                    }
                    if (index >= units.length) return null;
                    return _UnitCard(
                      unit: units[index],
                      hasPaid: hasPaid,
                      onTap: () {
                        final unit = units[index];
                        if (!unit.isAccessible(hasPaid)) {
                          context.push('/unlock');
                          return;
                        }
                        context.go('/tests/${unit.id}');
                      },
                    );
                  },
                  childCount: units.length + (hasPaid ? 0 : 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitCard extends StatelessWidget {
  const _UnitCard({
    required this.unit,
    required this.hasPaid,
    required this.onTap,
  });

  final Unit unit;
  final bool hasPaid;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locked = !unit.isAccessible(hasPaid);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Unit ${unit.unitNumber}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      unit.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      locked ? 'Unlock to access' : '50 questions',
                      style: TextStyle(
                        color: locked ? Colors.orange : AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                locked ? Icons.lock_outline : Icons.chevron_right,
                color: locked ? AppColors.textMuted : AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnlockBanner extends StatelessWidget {
  const _UnlockBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primary.withValues(alpha: 0.08),
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Unlock all 16 units and 950+ questions',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'One-time payment of KSh 1 via M-Pesa.',
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onTap, child: const Text('Unlock now')),
          ],
        ),
      ),
    );
  }
}
