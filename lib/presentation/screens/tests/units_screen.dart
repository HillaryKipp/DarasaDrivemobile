import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/unit.dart';
import '../../providers/auth_providers.dart';
import '../../providers/data_providers.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';

class UnitsScreen extends ConsumerWidget {
  const UnitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsAsync = ref.watch(unitsProvider);
    final hasPaid = ref.watch(hasPaidProvider);
    final attemptsAsync = ref.watch(testAttemptsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.black, size: 28),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'TESTS',
            style: TextStyle(
              color: Color(0xFF065F2F),
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 1.1,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.black),
              onPressed: () {},
            ),
          ],
        ),
        body: Column(
          children: [
            // Top Course Progress Banner
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF065F2F),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.description, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Course Progress',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          unitsAsync.when(
                            data: (units) => Text(
                              '${units.length} Units • 100+ Questions',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            loading: () => const Text('Loading...', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    unitsAsync.when(
                      data: (units) {
                        if (units.isEmpty) return const SizedBox.shrink();
                        final attempts = attemptsAsync.valueOrNull ?? [];

                        final bestScores = <String, double>{};
                        for (final a in attempts) {
                          final p = a.total == 0 ? 0.0 : a.score / a.total;
                          if (p > (bestScores[a.unitId] ?? 0.0)) {
                            bestScores[a.unitId] = p;
                          }
                        }

                        final sum = bestScores.values.fold(0.0, (a, b) => a + b);
                        final overallProgress = sum / units.length;
                        final overallPct = (overallProgress * 100).toInt();

                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              height: 48,
                              width: 48,
                              child: CircularProgressIndicator(
                                value: overallProgress,
                                strokeWidth: 4,
                                backgroundColor: Colors.white.withValues(alpha: 0.1),
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            Text(
                              '$overallPct%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const SizedBox(width: 48, height: 48),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),

            // Tab Bar
            const TabBar(
              indicatorColor: Color(0xFF065F2F),
              labelColor: Color(0xFF065F2F),
              unselectedLabelColor: Colors.grey,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: [
                Tab(text: 'Free Units'),
                Tab(text: 'All Units'),
              ],
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

            Expanded(
              child: unitsAsync.when(
                loading: () => const LoadingView(),
                error: (e, _) => ErrorView(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(unitsProvider),
                ),
                data: (units) {
                  final attempts = attemptsAsync.valueOrNull ?? [];

                  final bestScores = <String, double>{};
                  for (final a in attempts) {
                    final p = a.total == 0 ? 0.0 : a.score / a.total;
                    if (p > (bestScores[a.unitId] ?? 0.0)) {
                      bestScores[a.unitId] = p;
                    }
                  }

                  final freeUnits = units.where((u) => u.isAccessible(false)).toList();
                  final allUnits = units;

                  return TabBarView(
                    children: [
                      // ── Free Units tab ──────────────────────────────────
                      freeUnits.isEmpty
                          ? const Center(child: Text('No free units available'))
                          : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: freeUnits.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final unit = freeUnits[index];
                          final progress = bestScores[unit.id];
                          return _UnitListItem(
                            unit: unit,
                            hasPaid: hasPaid,
                            progress: progress,
                            onTap: () => context.go('/tests/${unit.id}'),
                          );
                        },
                      ),

                      // ── All Units tab ───────────────────────────────────
                      ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: allUnits.length + (hasPaid ? 0 : 1),
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          if (index == allUnits.length && !hasPaid) {
                            return _UnlockBanner(
                              onTap: () => context.push(
                                '/unlock?from=${Uri.encodeComponent('/tests')}',
                              ),
                            );
                          }
                          if (index >= allUnits.length) return const SizedBox.shrink();

                          final unit = allUnits[index];
                          final progress = bestScores[unit.id];
                          return _UnitListItem(
                            unit: unit,
                            hasPaid: hasPaid,
                            progress: progress,
                            onTap: () {
                              final target = '/tests/${unit.id}';
                              if (!unit.isAccessible(hasPaid)) {
                                context.push('/unlock?from=${Uri.encodeComponent(target)}');
                                return;
                              }
                              context.go(target);
                            },
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnitListItem extends StatelessWidget {
  const _UnitListItem({
    required this.unit,
    required this.hasPaid,
    required this.onTap,
    this.progress,
  });

  final Unit unit;
  final bool hasPaid;
  final VoidCallback onTap;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final locked = !unit.isAccessible(hasPaid);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            // Number Box
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: locked ? const Color(0xFF94A3B8) : const Color(0xFF065F2F),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(
                '${unit.unitNumber}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Title and Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unit.title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: locked ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    locked ? 'Unlock to access' : 'Practice Quiz',
                    style: TextStyle(
                      color: locked ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            // Status Icon / Progress
            if (locked)
              const Icon(Icons.lock_outline, color: Color(0xFF94A3B8), size: 20)
            else if (progress != null && progress! > 0)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(progress! * 100).toInt()}%',
                    style: const TextStyle(
                      color: Color(0xFF059669),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (progress == 1.0)
                    const Icon(Icons.check_circle_outline, color: Color(0xFF059669), size: 20)
                  else
                    SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 2,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
                      ),
                    ),
                ],
              )
            else
              const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20),
          ],
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          const Text(
            'Unlock all 19 units and 950+ questions',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF065F2F)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Master the NTSA theory test today.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Unlock Full Access'),
          ),
        ],
      ),
    );
  }
}
