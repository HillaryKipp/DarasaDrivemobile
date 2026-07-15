import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/test_attempt.dart';
import '../../providers/data_providers.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attemptsAsync = ref.watch(testAttemptsProvider);
    final unitsAsync = ref.watch(unitsProvider);

    // True only while data already exists and a new fetch is happening
    // quietly in the background (e.g. right after login).
    final isRefreshing = attemptsAsync.isRefreshing || unitsAsync.isRefreshing;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'STATISTICS',
          style: TextStyle(
            color: Color(0xFF065F2F),
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 1.1,
          ),
        ),
        centerTitle: true,
        bottom: isRefreshing
            ? const PreferredSize(
          preferredSize: Size.fromHeight(2),
          child: LinearProgressIndicator(
            minHeight: 2,
            backgroundColor: Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF065F2F)),
          ),
        )
            : null,
      ),
      body: attemptsAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(testAttemptsProvider),
        ),
        data: (attempts) {
          return unitsAsync.when(
            loading: () => const LoadingView(),
            error: (e, _) => ErrorView(
              error: e,
              onRetry: () => ref.invalidate(unitsProvider),
            ),
            data: (units) {
              // ── 1. Map LATEST attempt for each unit ──────────────────────
              final latestAttemptsMap = <String, TestAttempt>{};
              final sortedAttempts = [...attempts]
                ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

              for (final a in sortedAttempts) {
                if (!latestAttemptsMap.containsKey(a.unitId)) {
                  latestAttemptsMap[a.unitId] = a;
                }
              }

              // ── 2. Summary Statistics (Calculated strictly from Latest) ──
              final totalUnitsCount = units.length;
              final unitsDoneCount = latestAttemptsMap.length;

              int totalQuestionsDone = 0;
              int totalCorrectDone = 0;
              int sumPercentages = 0;

              for (final attempt in latestAttemptsMap.values) {
                totalQuestionsDone += attempt.total;
                totalCorrectDone += attempt.score;
                sumPercentages += attempt.percentage;
              }

              final avgPct = unitsDoneCount == 0 ? 0 : (sumPercentages / unitsDoneCount).round();
              final sortedUnits = [...units]..sort((a, b) => a.unitNumber.compareTo(b.unitNumber));

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(testAttemptsProvider);
                  ref.invalidate(unitsProvider);
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    const _SectionHeader(title: 'Overall Performance'),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          _ProgressCircle(percentage: avgPct),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              children: [
                                _StatRow(label: 'Units Done', value: '$unitsDoneCount / $totalUnitsCount'),
                                const Divider(height: 16),
                                _StatRow(label: 'Questions Done', value: '$totalQuestionsDone'),
                                const Divider(height: 16),
                                _StatRow(label: 'Correct Answers', value: '$totalCorrectDone'),
                                const Divider(height: 16),
                                _StatRow(label: 'Avg Score (Latest)', value: '$avgPct%'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    const _SectionHeader(title: 'Latest Performance by Unit'),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _LegendItem(color: Color(0xFF065F2F), label: 'Passed (70%+)'),
                              SizedBox(width: 12),
                              _LegendItem(color: Colors.orange, label: 'Attempted'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 160,
                            child: sortedUnits.isEmpty
                                ? const Center(child: Text('No units found'))
                                : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: sortedUnits.map((unit) {
                                  final score = latestAttemptsMap[unit.id]?.percentage ?? 0;
                                  return _BarChartItem(
                                    score: score,
                                    label: 'U${unit.unitNumber}',
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const _SectionHeader(title: 'Recent Unit Tests'),
                        _ResponsiveViewAllButton(onTap: () => context.go('/tests')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _RecentAttemptsList(attempts: attempts),
                    const SizedBox(height: 32),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ProgressCircle extends StatelessWidget {
  final int percentage;
  const _ProgressCircle({required this.percentage});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: 90,
          width: 90,
          child: CircularProgressIndicator(
            value: percentage / 100,
            strokeWidth: 10,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF065F2F)),
          ),
        ),
        Text(
          '$percentage%',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
      ],
    );
  }
}

class _BarChartItem extends StatelessWidget {
  final int score;
  final String label;
  const _BarChartItem({required this.score, required this.label});

  @override
  Widget build(BuildContext context) {
    final isPassed = score >= 70;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (score > 0)
            Text('$score', style: const TextStyle(fontSize: 8, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: 16,
            height: (score / 100) * 110 + 2, // 2px min visible base
            decoration: BoxDecoration(
              color: score == 0
                  ? const Color(0xFFF1F5F9)
                  : (isPassed ? const Color(0xFF065F2F) : Colors.orange),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _ResponsiveViewAllButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ResponsiveViewAllButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF065F2F).withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF065F2F).withOpacity(0.1)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'View All',
                style: TextStyle(
                  color: Color(0xFF065F2F),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              SizedBox(width: 6),
              Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xFF065F2F)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentAttemptsList extends StatelessWidget {
  final List<dynamic> attempts;
  const _RecentAttemptsList({required this.attempts});

  @override
  Widget build(BuildContext context) {
    if (attempts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No test history available', style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: attempts.take(5).map((attempt) {
          final index = attempts.indexOf(attempt);
          final isLast = index == attempts.length - 1 || index == 4;
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                title: Text(
                  attempt.unitTitle ?? 'Unit ${attempt.unitNumber} Test',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                subtitle: Text(
                  DateFormat('MMM d, y • HH:mm').format(attempt.completedAt),
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                trailing: _AttemptScore(percentage: attempt.percentage, score: '${attempt.score}/${attempt.total}'),
                onTap: () => context.go('/tests/${attempt.unitId}'),
              ),
              if (!isLast) const Divider(height: 1, indent: 20, endIndent: 20),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _AttemptScore extends StatelessWidget {
  final int percentage;
  final String score;
  const _AttemptScore({required this.percentage, required this.score});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$percentage%',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: percentage >= 70
                ? const Color(0xFF059669)
                : (percentage >= 50 ? Colors.orange : Colors.red),
          ),
        ),
        Text(score, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
      ],
    );
  }
}