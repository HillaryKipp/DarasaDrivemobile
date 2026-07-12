import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/material_item.dart';
import '../../providers/data_providers.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import 'admin_helpers.dart';

class AdminMaterialsScreen extends ConsumerWidget {
  const AdminMaterialsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materialsAsync = ref.watch(materialsProvider);

    return AdminScaffold(
      title: 'Materials',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context, ref),
        backgroundColor: kAdminGreen,
        child: const Icon(Icons.add),
      ),
      body: materialsAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(materialsProvider)),
        data: (materials) => ListView(
          children: [
            AdminBanner(
              icon: Icons.menu_book_outlined,
              title: 'Materials',
              subtitle: '${materials.length} items · notes, videos & diagrams',
            ),
            const AdminSectionLabel(text: 'All Materials'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (int i = 0; i < materials.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    AdminListTile(
                      icon: materials[i].type == 'video'
                          ? Icons.play_circle_outline
                          : Icons.description_outlined,
                      title: materials[i].title,
                      subtitle:
                      '${materials[i].type.replaceAll('_', ' ')}${materials[i].unitTitle != null ? ' · ${materials[i].unitTitle}' : ''}',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (materials[i].isFree)
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
                                _openForm(context, ref, material: materials[i]),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 18, color: Colors.redAccent),
                            onPressed: () =>
                                _delete(context, ref, materials[i]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref,
      {MaterialItem? material}) async {
    final saved =
    await context.push<bool>('/admin/materials/form', extra: material);
    if (saved == true) ref.invalidate(materialsProvider);
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, MaterialItem m) async {
    if (!await confirmDelete(context, m.title)) return;
    try {
      await ref.read(adminRepositoryProvider).deleteMaterial(m.id);
      ref.invalidate(materialsProvider);
      if (context.mounted) showAdminSuccess(context, 'Material deleted');
    } catch (e) {
      if (context.mounted) showAdminError(context, e);
    }
  }
}

// ── Form ──────────────────────────────────────────────────────────────────────

class AdminMaterialFormScreen extends ConsumerStatefulWidget {
  const AdminMaterialFormScreen({super.key, this.material});
  final MaterialItem? material;

  @override
  ConsumerState<AdminMaterialFormScreen> createState() =>
      _AdminMaterialFormScreenState();
}

class _AdminMaterialFormScreenState
    extends ConsumerState<AdminMaterialFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _urlCtrl;
  late final TextEditingController _thumbCtrl;
  late String _type;
  late bool _isFree;
  String? _unitId;
  bool _saving = false;

  static const _types = ['notes', 'pdf', 'video', 'diagram', 'road_signs'];

  @override
  void initState() {
    super.initState();
    final m = widget.material;
    _titleCtrl = TextEditingController(text: m?.title ?? '');
    _descCtrl = TextEditingController(text: m?.description ?? '');
    _urlCtrl = TextEditingController(text: m?.url ?? '');
    _thumbCtrl = TextEditingController(text: m?.thumbnailUrl ?? '');

    // Normalize + defensively match the incoming type against the known
    // list. Handles case differences, stray whitespace, or a type value
    // that no longer exists in _types (e.g. legacy/removed type).
    final rawType = (m?.type ?? '').trim().toLowerCase();
    _type = _types.firstWhere(
          (t) => t == rawType,
      orElse: () => 'notes',
    );

    _isFree = m?.isFree ?? false;

    // Note: MaterialItem doesn't expose a unitId getter (only unitTitle),
    // so on edit we can't pre-select the unit from the entity alone.
    // _unitId stays null (defaults to "None") unless the user picks one.
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _urlCtrl.dispose();
    _thumbCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      if (widget.material == null) {
        await repo.createMaterial(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          type: _type,
          url: _urlCtrl.text.trim(),
          isFree: _isFree,
          thumbnailUrl: _thumbCtrl.text.trim().isEmpty ? null : _thumbCtrl.text.trim(),
          unitId: _unitId,
        );
      } else {
        await repo.updateMaterial(
          id: widget.material!.id,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          type: _type,
          url: _urlCtrl.text.trim(),
          isFree: _isFree,
          thumbnailUrl: _thumbCtrl.text.trim().isEmpty ? null : _thumbCtrl.text.trim(),
          unitId: _unitId,
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
    final unitsAsync = ref.watch(unitsProvider);
    return AdminScaffold(
      title: widget.material == null ? 'Add Material' : 'Edit Material',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                // Belt-and-braces: even though _type is normalized in
                // initState, re-validate against the current items list
                // right here so a bad value can never reach the widget.
                value: _types.contains(_type) ? _type : 'notes',
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Type'),
                items: _types
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? 'notes'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _urlCtrl,
                decoration: const InputDecoration(labelText: 'URL'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _thumbCtrl,
                decoration: const InputDecoration(labelText: 'Thumbnail URL (optional)'),
              ),
              const SizedBox(height: 12),
              unitsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
                data: (units) {
                  // If the currently selected unit id doesn't exist in the
                  // fetched list (deleted unit, stale draft, id-format
                  // mismatch, etc.) fall back to "None" for display rather
                  // than crashing. We don't mutate _unitId here directly
                  // during build; onChanged is the only place state changes.
                  final validIds = units.map((u) => u.id).toSet();
                  final displayValue =
                  (_unitId != null && validIds.contains(_unitId))
                      ? _unitId
                      : null;

                  return DropdownButtonFormField<String?>(
                    value: displayValue,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Unit (optional)'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('None')),
                      ...units.map((u) => DropdownMenuItem(
                        value: u.id,
                        child: Text('Unit ${u.unitNumber}: ${u.title}',
                            overflow: TextOverflow.ellipsis),
                      )),
                    ],
                    onChanged: (v) => setState(() => _unitId = v),
                  );
                },
              ),
              SwitchListTile(
                title: const Text('Free access'),
                value: _isFree,
                activeColor: kAdminGreen,
                onChanged: (v) => setState(() => _isFree = v),
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