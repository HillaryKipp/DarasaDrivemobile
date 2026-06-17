import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/question.dart';
import '../../providers/auth_providers.dart';
import '../../providers/data_providers.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';

final questionsProvider =
FutureProvider.family<List<Question>, String>((ref, unitId) {
  return ref.watch(unitsRepositoryProvider).getQuestions(unitId);
});

class TestRunnerScreen extends ConsumerStatefulWidget {
  const TestRunnerScreen({super.key, required this.unitId});

  final String unitId;

  @override
  ConsumerState<TestRunnerScreen> createState() => _TestRunnerScreenState();
}

class _TestRunnerScreenState extends ConsumerState<TestRunnerScreen> {
  int _index = 0;
  final Map<String, String> _answers = {};
  bool _submitted = false;
  List<Question>? _shuffled;

  @override
  Widget build(BuildContext context) {
    final unitAsync = ref.watch(unitProvider(widget.unitId));
    final questionsAsync = ref.watch(questionsProvider(widget.unitId));
    final hasPaid = ref.watch(hasPaidProvider);

    return unitAsync.when(
      loading: () => const Scaffold(body: LoadingView(message: 'Loading unit…')),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(message: e.toString()),
      ),
      data: (unit) {
        if (!unit.isAccessible(hasPaid)) {
          return Scaffold(
            appBar: AppBar(title: Text('Unit ${unit.unitNumber}')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'This unit is locked',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('Unlock all units with a one-time payment.'),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.push(
                          '/unlock?from=${Uri.encodeComponent('/tests/${widget.unitId}')}',
                        ),
                        child: const Text('Unlock now'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return questionsAsync.when(
          loading: () => Scaffold(
            appBar: AppBar(title: Text(unit.title)),
            body: const LoadingView(message: 'Loading questions…'),
          ),
          error: (e, _) => Scaffold(
            appBar: AppBar(title: Text(unit.title)),
            body: ErrorView(
              message: e.toString(),
              onRetry: () => ref.invalidate(questionsProvider(widget.unitId)),
            ),
          ),
          data: (questions) {
            // Persist the shuffled order so it doesn't change on every rebuild
            _shuffled ??= [...questions]..shuffle();
            final shuffled = _shuffled!;

            if (shuffled.isEmpty) {
              return Scaffold(
                appBar: AppBar(title: Text(unit.title)),
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('No questions yet for this unit.'),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => context.go('/tests'),
                        child: const Text('Back to units'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (_submitted) {
              return _ResultsView(
                unitTitle: unit.title,
                questions: shuffled,
                answers: _answers,
                onRetry: () => setState(() {
                  _index = 0;
                  _answers.clear();
                  _submitted = false;
                  _shuffled = null; // Clear shuffled order to get a new one on retry
                  ref.invalidate(questionsProvider(widget.unitId));
                }),
                onBack: () => context.go('/tests'),
              );
            }

            final current = shuffled[_index];
            final progress = ((_index + 1) / shuffled.length);

            return Scaffold(
              appBar: AppBar(
                title: Text('Unit ${unit.unitNumber}'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => context.go('/tests'),
                ),
              ),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Progress bar ────────────────────────────────────────
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    color: AppColors.primary,
                  ),
                  // ── Scrollable question area ─────────────────────────────
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Question ${_index + 1} of ${shuffled.length}',
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            current.questionText,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          // ── Diagram / image (only when present) ───────────
                          if (current.imageUrl != null &&
                              current.imageUrl!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                current.imageUrl!,
                                fit: BoxFit.contain,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return Container(
                                    height: 180,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: progress.expectedTotalBytes != null
                                            ? progress.cumulativeBytesLoaded /
                                            progress.expectedTotalBytes!
                                            : null,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stack) =>
                                    Container(
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.broken_image_outlined,
                                                size: 36, color: Colors.grey),
                                            SizedBox(height: 6),
                                            Text(
                                              'Image could not be loaded',
                                              style: TextStyle(color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          // ── Answer options ──────────────────────────────
                          for (final entry in current.options.entries)
                            _OptionTile(
                              label: entry.key,
                              text: entry.value,
                              selected: _answers[current.id] == entry.key,
                              onTap: () => setState(
                                    () => _answers[current.id] = entry.key,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // ── Navigation bar ──────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        if (_index > 0)
                          SizedBox(
                            width: 100,
                            child: OutlinedButton(
                              onPressed: () => setState(() => _index--),
                              child: const Text('Back'),
                            ),
                          ),
                        const Spacer(),
                        SizedBox(
                          width: 120,
                          child: ElevatedButton(
                            onPressed: _answers[current.id] == null
                                ? null
                                : () {
                              if (_index < shuffled.length - 1) {
                                setState(() => _index++);
                              } else {
                                _submit(shuffled);
                              }
                            },
                            child: Text(
                              _index < shuffled.length - 1 ? 'Next' : 'Submit',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submit(List<Question> questions) async {
    setState(() => _submitted = true);

    var score = 0;
    final wrongIds = <String>[];
    for (final q in questions) {
      if (_answers[q.id] == q.correctOption) {
        score++;
      } else {
        wrongIds.add(q.id);
      }
    }

    final user = ref.read(currentUserProvider);
    if (user != null) {
      await ref.read(unitsRepositoryProvider).saveTestAttempt(
        userId: user.id,
        unitId: widget.unitId,
        score: score,
        total: questions.length,
        wrongQuestionIds: wrongIds,
      );
      ref.invalidate(testAttemptsProvider);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Option tile
// ─────────────────────────────────────────────────────────────────────────────

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: selected ? AppColors.primary.withValues(alpha: 0.08) : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
          selected ? AppColors.primary : Colors.grey.shade200,
          foregroundColor: selected ? Colors.white : Colors.black87,
          child: Text(label),
        ),
        title: Text(text),
        onTap: onTap,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Results view
// ─────────────────────────────────────────────────────────────────────────────

class _ResultsView extends StatelessWidget {
  const _ResultsView({
    required this.unitTitle,
    required this.questions,
    required this.answers,
    required this.onRetry,
    required this.onBack,
  });

  final String unitTitle;
  final List<Question> questions;
  final Map<String, String> answers;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    var score = 0;
    final wrong = <Question>[];
    for (final q in questions) {
      if (answers[q.id] == q.correctOption) {
        score++;
      } else {
        wrong.add(q);
      }
    }
    final pct = ((score / questions.length) * 100).round();
    final passed = pct >= 70;

    return Scaffold(
      appBar: AppBar(title: Text(unitTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Score card ─────────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    passed ? Icons.emoji_events : Icons.school,
                    size: 56,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You scored $score / ${questions.length}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$pct% — ${passed ? "Great work, you passed!" : "Keep practising — you\'ll get there."}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onRetry,
                          child: const Text('Retry test'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onBack,
                          child: const Text('Back to units'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // ── Wrong answers review ────────────────────────────────────────
          if (wrong.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Questions you got wrong',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            for (final q in wrong)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        q.questionText,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      // Show image in review if the question had one
                      if (q.imageUrl != null && q.imageUrl!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            q.imageUrl!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'Correct: ${q.correctOption} — ${q.optionLabel(q.correctOption)}',
                        style: const TextStyle(color: AppColors.primary),
                      ),
                      if (q.explanation != null &&
                          q.explanation!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          q.explanation!,
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
