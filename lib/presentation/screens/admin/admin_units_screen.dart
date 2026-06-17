import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/unit.dart';
import '../../providers/data_providers.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import 'admin_helpers.dart';

class AdminUnitsScreen extends ConsumerWidget {
  const AdminUnitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsAsync = ref.watch(unitsProvider);

    return AdminScaffold(
      title: 'Units',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context, ref),
        backgroundColor: kAdminGreen,
        child: const Icon(Icons.add),
      ),
      body: unitsAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(unitsProvider)),
        data: (units) => ListView(
          children: [
            AdminBanner(
              icon: Icons.library_books_outlined,
              title: 'Test Units',
              subtitle: '${units.length} unit${units.length == 1 ? '' : 's'} · theory & practical',
              trailingIcon: Icons.checklist_outlined,
            ),
            if (units.isEmpty)
              const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: Text('No units yet')))
            else ...[
              const AdminSectionLabel(text: 'All Units'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    for (int i = 0; i < units.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      AdminListTile(
                        icon: Icons.library_books_outlined,
                        title: 'Unit ${units[i].unitNumber}: ${units[i].title}',
                        subtitle: units[i].isFreePreview
                            ? 'Free preview'
                            : 'Premium',
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (units[i].isFreePreview)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text('Free',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: kAdminGreen)),
                              ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  size: 18, color: kAdminMuted),
                              onPressed: () =>
                                  _openForm(context, ref, unit: units[i]),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 18, color: Colors.redAccent),
                              onPressed: () => _delete(context, ref, units[i]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref,
      {Unit? unit}) async {
    final saved = await context.push<bool>('/admin/units/form', extra: unit);
    if (saved == true) ref.invalidate(unitsProvider);
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, Unit unit) async {
    if (!await confirmDelete(context, unit.title)) return;
    try {
      await ref.read(adminRepositoryProvider).deleteUnit(unit.id);
      ref.invalidate(unitsProvider);
      if (context.mounted) showAdminSuccess(context, 'Unit deleted');
    } catch (e) {
      if (context.mounted) showAdminError(context, e);
    }
  }
}

// ── Form ──────────────────────────────────────────────────────────────────────

class AdminUnitFormScreen extends ConsumerStatefulWidget {
  const AdminUnitFormScreen({super.key, this.unit});
  final Unit? unit;

  @override
  ConsumerState<AdminUnitFormScreen> createState() =>
      _AdminUnitFormScreenState();
}

class _AdminUnitFormScreenState extends ConsumerState<AdminUnitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _numberCtrl;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late bool _isFreePreview;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _numberCtrl = TextEditingController(text: widget.unit?.unitNumber.toString() ?? '');
    _titleCtrl = TextEditingController(text: widget.unit?.title ?? '');
    _descCtrl = TextEditingController(text: widget.unit?.description ?? '');
    _isFreePreview = widget.unit?.isFreePreview ?? false;
  }

  @override
  void dispose() {
    _numberCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      final number = int.parse(_numberCtrl.text.trim());
      if (widget.unit == null) {
        await repo.createUnit(
          unitNumber: number,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          isFreePreview: _isFreePreview,
        );
      } else {
        await repo.updateUnit(
          id: widget.unit!.id,
          unitNumber: number,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          isFreePreview: _isFreePreview,
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
      title: widget.unit == null ? 'Add Unit' : 'Edit Unit',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _numberCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Unit number'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Free preview'),
                value: _isFreePreview,
                activeColor: kAdminGreen,
                onChanged: (v) => setState(() => _isFreePreview = v),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAdminGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(_saving ? 'Saving…' : 'Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}