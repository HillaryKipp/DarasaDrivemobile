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
                    ElevatedButton(
                      onPressed: () => context.push('/unlock'),
                      child: const Text('Unlock now'),
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
            if (questions.isEmpty) {
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
                questions: questions,
                answers: _answers,
                onRetry: () => setState(() {
                  _index = 0;
                  _answers.clear();
                  _submitted = false;
                  ref.invalidate(questionsProvider(widget.unitId));
                }),
                onBack: () => context.go('/tests'),
              );
            }

            final current = questions[_index];
            final progress = ((_index + 1) / questions.length);

            return Scaffold(
              appBar: AppBar(
                title: Text('Unit ${unit.unitNumber}'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => context.go('/tests'),
                ),
              ),
              body: Column(
                children: [
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    color: AppColors.primary,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Question ${_index + 1} of ${questions.length}',
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
                          const SizedBox(height: 20),
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
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        if (_index > 0)
                          OutlinedButton(
                            onPressed: () => setState(() => _index--),
                            child: const Text('Back'),
                          ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: _answers[current.id] == null
                              ? null
                              : () {
                                  if (_index < questions.length - 1) {
                                    setState(() => _index++);
                                  } else {
                                    _submit(questions);
                                  }
                                },
                          child: Text(
                            _index < questions.length - 1
                                ? 'Next'
                                : 'Submit',
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
                    '$pct% — ${passed ? "Great work, you passed!" : "Keep practising — you'll get there."}',
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
                      Text(q.questionText, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(
                        'Correct: ${q.correctOption} — ${q.optionLabel(q.correctOption)}',
                        style: const TextStyle(color: AppColors.primary),
                      ),
                      if (q.explanation != null) ...[
                        const SizedBox(height: 8),
                        Text(q.explanation!, style: const TextStyle(color: AppColors.textMuted)),
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
