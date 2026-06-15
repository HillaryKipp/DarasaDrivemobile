import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/data_providers.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attemptsAsync = ref.watch(testAttemptsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black, size: 28),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
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
      ),
      body: attemptsAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(testAttemptsProvider),
        ),
        data: (attempts) {
          // Calculate stats
          final avgPct = attempts.isEmpty
              ? 0
              : (attempts.map((a) => a.percentage).reduce((a, b) => a + b) /
                      attempts.length)
                  .round();
          
          final unitsCompleted = attempts.length; // Simplified for mock
          final totalQuestions = attempts.isEmpty ? 0 : attempts.map((a) => a.total).reduce((a, b) => a + b);
          final correctAnswers = attempts.isEmpty ? 0 : attempts.map((a) => a.score).reduce((a, b) => a + b);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Overall Performance Section
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
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 100,
                          width: 100,
                          child: CircularProgressIndicator(
                            value: avgPct / 100,
                            strokeWidth: 10,
                            backgroundColor: const Color(0xFFF1F5F9),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF065F2F)),
                          ),
                        ),
                        Text(
                          '$avgPct%',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        children: [
                          _StatRow(label: 'Units Completed', value: '$unitsCompleted / 19'),
                          const Divider(height: 16),
                          _StatRow(label: 'Questions Attempted', value: '$totalQuestions'),
                          const Divider(height: 16),
                          _StatRow(label: 'Correct Answers', value: '$correctAnswers'),
                          const Divider(height: 16),
                          _StatRow(label: 'Average Score', value: '$avgPct%'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Performance by Unit Section
              const _SectionHeader(title: 'Performance by Unit'),
              Container(
                height: 220,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF065F2F),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('Score (%)', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(10, (index) {
                          // Mock bar heights
                          final scores = [94, 88, 82, 65, 65, 68, 65, 65, 65, 62];
                          final score = scores[index];
                          final isHigh = score > 70;
                          
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                width: 18,
                                height: (score / 100) * 120,
                                decoration: BoxDecoration(
                                  color: isHigh ? const Color(0xFF065F2F) : const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('${index + 1}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                            ],
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Recent Mock Tests Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _SectionHeader(title: 'Recent Unit Tests'),
                  TextButton(
                    onPressed: () {},
                    child: const Text('View All', style: TextStyle(color: Color(0xFF065F2F), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: attempts.take(3).map((attempt) {
                    final isLast = attempts.indexOf(attempt) == 2 || attempts.indexOf(attempt) == attempts.length - 1;
                    return Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          title: Text(
                            attempt.unitTitle ?? 'Mock Test - Unit ${attempt.unitNumber}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                          subtitle: Text(
                            DateFormat('MMMM d, y').format(attempt.completedAt),
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                          trailing: Text(
                            '${attempt.percentage}%',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: attempt.percentage >= 70 
                                  ? const Color(0xFF059669) 
                                  : (attempt.percentage >= 50 ? Colors.orange : Colors.red),
                            ),
                          ),
                        ),
                        if (!isLast) const Divider(height: 1, indent: 20, endIndent: 20),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 30),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
