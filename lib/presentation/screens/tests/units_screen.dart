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
            // Top Green Banner
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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '19 Units',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Practice with over 950 questions',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 48,
                          width: 48,
                          child: CircularProgressIndicator(
                            value: 0.16,
                            strokeWidth: 4,
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const Text(
                          '16%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
                Tab(text: 'All Units'),
                Tab(text: 'My Progress'),
              ],
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

            Expanded(
              child: TabBarView(
                children: [
                  unitsAsync.when(
                    loading: () => const LoadingView(),
                    error: (e, _) => ErrorView(
                      message: e.toString(),
                      onRetry: () => ref.invalidate(unitsProvider),
                    ),
                    data: (units) => ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: units.length + (hasPaid ? 0 : 1),
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index == units.length && !hasPaid) {
                          return _UnlockBanner(onTap: () => context.push('/unlock'));
                        }
                        if (index >= units.length) return null;

                        final unit = units[index];
                        // Mock progress for matching UI (Top items show some progress)
                        double? progress;
                        if (index == 0) progress = 1.0;
                        else if (index == 1) progress = 0.8;
                        else if (index == 2) progress = 0.6;
                        else if (index == 3) progress = 0.4;
                        else if (index == 4) progress = 0.2;

                        return _UnitListItem(
                          unit: unit,
                          hasPaid: hasPaid,
                          progress: progress,
                          onTap: () {
                            if (!unit.isAccessible(hasPaid)) {
                              context.push('/unlock');
                              return;
                            }
                            context.go('/tests/${unit.id}');
                          },
                        );
                      },
                    ),
                  ),
                  const Center(child: Text('Progress tracking coming soon')),
                ],
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
                color: const Color(0xFF065F2F),
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
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    '50 Questions',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            // Status Icon / Progress
            if (locked)
              const Icon(Icons.lock_outline, color: Color(0xFF94A3B8), size: 20)
            else if (progress != null)
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
              backgroundColor: const Color(0xFF065F2F),
              elevation: 0,
            ),
            child: const Text('Unlock now'),
          ),
        ],
      ),
    );
  }
}
