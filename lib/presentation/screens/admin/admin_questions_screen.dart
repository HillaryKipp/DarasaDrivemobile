import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/question.dart';
import '../../providers/admin_providers.dart';
import '../../providers/data_providers.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import 'admin_helpers.dart';

class AdminQuestionsScreen extends ConsumerStatefulWidget {
  const AdminQuestionsScreen({super.key});

  @override
  ConsumerState<AdminQuestionsScreen> createState() => _AdminQuestionsScreenState();
}

class _AdminQuestionsScreenState extends ConsumerState<AdminQuestionsScreen> {
  String? _selectedUnitId;

  @override
  Widget build(BuildContext context) {
    final unitsAsync = ref.watch(unitsProvider);

    return AdminScaffold(
      title: 'Questions',
      floatingActionButton: _selectedUnitId == null
          ? null
          : FloatingActionButton(
              onPressed: () => _openForm(context, unitId: _selectedUnitId!),
              backgroundColor: const Color(0xFF065F2F),
              child: const Icon(Icons.add),
            ),
      body: unitsAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(unitsProvider)),
        data: (units) {
          _selectedUnitId ??= units.isNotEmpty ? units.first.id : null;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<String>(
                  value: _selectedUnitId,
                  decoration: const InputDecoration(
                    labelText: 'Select unit',
                    border: OutlineInputBorder(),
                  ),
                  items: units
                      .map((u) => DropdownMenuItem(
                            value: u.id,
                            child: Text('Unit ${u.unitNumber}: ${u.title}'),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedUnitId = v),
                ),
              ),
              Expanded(
                child: _selectedUnitId == null
                    ? const Center(child: Text('No units available'))
                    : _QuestionsList(unitId: _selectedUnitId!),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openForm(BuildContext context, {required String unitId, Question? question}) async {
    final saved = await context.push<bool>(
      '/admin/questions/form',
      extra: {'unitId': unitId, 'question': question},
    );
    if (saved == true) ref.invalidate(adminQuestionsProvider(unitId));
  }
}

class _QuestionsList extends ConsumerWidget {
  const _QuestionsList({required this.unitId});

  final String unitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(adminQuestionsProvider(unitId));

    return questionsAsync.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(adminQuestionsProvider(unitId)),
      ),
      data: (questions) {
        if (questions.isEmpty) {
          return const Center(child: Text('No questions for this unit'));
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: questions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final q = questions[index];
            return Card(
              child: ListTile(
                title: Text(q.questionText, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text('Answer: ${q.correctOption}'),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => context.push<bool>(
                        '/admin/questions/form',
                        extra: {'unitId': unitId, 'question': q},
                      ).then((saved) {
                        if (saved == true) ref.invalidate(adminQuestionsProvider(unitId));
                      }),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => _delete(context, ref, q),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Question q) async {
    if (!await confirmDelete(context, q.questionText)) return;
    try {
      await ref.read(adminRepositoryProvider).deleteQuestion(q.id);
      ref.invalidate(adminQuestionsProvider(unitId));
      if (context.mounted) showAdminSuccess(context, 'Question deleted');
    } catch (e) {
      if (context.mounted) showAdminError(context, e);
    }
  }
}

class AdminQuestionFormScreen extends ConsumerStatefulWidget {
  const AdminQuestionFormScreen({super.key, required this.unitId, this.question});

  final String unitId;
  final Question? question;

  @override
  ConsumerState<AdminQuestionFormScreen> createState() => _AdminQuestionFormScreenState();
}

class _AdminQuestionFormScreenState extends ConsumerState<AdminQuestionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _textCtrl;
  late final TextEditingController _imageCtrl;
  late final TextEditingController _optACtrl;
  late final TextEditingController _optBCtrl;
  late final TextEditingController _optCCtrl;
  late final TextEditingController _optDCtrl;
  late final TextEditingController _explanationCtrl;
  late String _correctOption;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final q = widget.question;
    _textCtrl = TextEditingController(text: q?.questionText ?? '');
    _imageCtrl = TextEditingController(text: q?.imageUrl ?? '');
    _optACtrl = TextEditingController(text: q?.optionA ?? '');
    _optBCtrl = TextEditingController(text: q?.optionB ?? '');
    _optCCtrl = TextEditingController(text: q?.optionC ?? '');
    _optDCtrl = TextEditingController(text: q?.optionD ?? '');
    _explanationCtrl = TextEditingController(text: q?.explanation ?? '');
    _correctOption = q?.correctOption ?? 'A';
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _imageCtrl.dispose();
    _optACtrl.dispose();
    _optBCtrl.dispose();
    _optCCtrl.dispose();
    _optDCtrl.dispose();
    _explanationCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      final payload = (
        unitId: widget.unitId,
        questionText: _textCtrl.text.trim(),
        imageUrl: _imageCtrl.text.trim().isEmpty ? null : _imageCtrl.text.trim(),
        optionA: _optACtrl.text.trim(),
        optionB: _optBCtrl.text.trim(),
        optionC: _optCCtrl.text.trim(),
        optionD: _optDCtrl.text.trim(),
        correctOption: _correctOption,
        explanation: _explanationCtrl.text.trim().isEmpty ? null : _explanationCtrl.text.trim(),
      );
      if (widget.question == null) {
        await repo.createQuestion(
          unitId: payload.unitId,
          questionText: payload.questionText,
          imageUrl: payload.imageUrl,
          optionA: payload.optionA,
          optionB: payload.optionB,
          optionC: payload.optionC,
          optionD: payload.optionD,
          correctOption: payload.correctOption,
          explanation: payload.explanation,
        );
      } else {
        await repo.updateQuestion(
          id: widget.question!.id,
          unitId: payload.unitId,
          questionText: payload.questionText,
          imageUrl: payload.imageUrl,
          optionA: payload.optionA,
          optionB: payload.optionB,
          optionC: payload.optionC,
          optionD: payload.optionD,
          correctOption: payload.correctOption,
          explanation: payload.explanation,
        );
      }
      if (mounted) context.pop(true);
    } catch (e) {
      if (mounted) showAdminError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: widget.question == null ? 'Add Question' : 'Edit Question',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _textCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Question text'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageCtrl,
                decoration: const InputDecoration(labelText: 'Image URL (optional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _optACtrl, decoration: const InputDecoration(labelText: 'Option A'), validator: _req),
              const SizedBox(height: 8),
              TextFormField(controller: _optBCtrl, decoration: const InputDecoration(labelText: 'Option B'), validator: _req),
              const SizedBox(height: 8),
              TextFormField(controller: _optCCtrl, decoration: const InputDecoration(labelText: 'Option C'), validator: _req),
              const SizedBox(height: 8),
              TextFormField(controller: _optDCtrl, decoration: const InputDecoration(labelText: 'Option D'), validator: _req),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _correctOption,
                decoration: const InputDecoration(labelText: 'Correct option'),
                items: const ['A', 'B', 'C', 'D']
                    .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                    .toList(),
                onChanged: (v) => setState(() => _correctOption = v ?? 'A'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _explanationCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Explanation (optional)'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving…' : 'Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _req(String? v) => v == null || v.isEmpty ? 'Required' : null;
}
