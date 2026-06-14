import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/school.dart';
import '../../providers/data_providers.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import 'admin_helpers.dart';

class AdminSchoolsScreen extends ConsumerWidget {
  const AdminSchoolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schoolsAsync = ref.watch(schoolsProvider);

    return AdminScaffold(
      title: 'Schools',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context, ref),
        backgroundColor: const Color(0xFF065F2F),
        child: const Icon(Icons.add),
      ),
      body: schoolsAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(schoolsProvider)),
        data: (schools) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: schools.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final s = schools[index];
            return Card(
              child: ListTile(
                title: Text(s.name),
                subtitle: Text('${s.town}, ${s.county} • Ksh ${s.priceFrom}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _openForm(context, ref, school: s),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => _delete(context, ref, s),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref, {School? school}) async {
    final saved = await context.push<bool>('/admin/schools/form', extra: school);
    if (saved == true) ref.invalidate(schoolsProvider);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, School s) async {
    if (!await confirmDelete(context, s.name)) return;
    try {
      await ref.read(adminRepositoryProvider).deleteSchool(s.id);
      ref.invalidate(schoolsProvider);
      if (context.mounted) showAdminSuccess(context, 'School deleted');
    } catch (e) {
      if (context.mounted) showAdminError(context, e);
    }
  }
}

class AdminSchoolFormScreen extends ConsumerStatefulWidget {
  const AdminSchoolFormScreen({super.key, this.school});

  final School? school;

  @override
  ConsumerState<AdminSchoolFormScreen> createState() => _AdminSchoolFormScreenState();
}

class _AdminSchoolFormScreenState extends ConsumerState<AdminSchoolFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _countyCtrl;
  late final TextEditingController _townCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _logoCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _ratingCtrl;
  late final TextEditingController _reviewsCtrl;
  late final TextEditingController _instructorsCtrl;
  late final TextEditingController _categoriesCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.school;
    _nameCtrl = TextEditingController(text: s?.name ?? '');
    _countyCtrl = TextEditingController(text: s?.county ?? '');
    _townCtrl = TextEditingController(text: s?.town ?? '');
    _descCtrl = TextEditingController(text: s?.description ?? '');
    _phoneCtrl = TextEditingController(text: s?.contactPhone ?? '');
    _logoCtrl = TextEditingController(text: s?.logoUrl ?? '');
    _priceCtrl = TextEditingController(text: s?.priceFrom.toString() ?? '0');
    _ratingCtrl = TextEditingController(text: s?.rating?.toString() ?? '');
    _reviewsCtrl = TextEditingController(text: s?.reviewCount?.toString() ?? '');
    _instructorsCtrl = TextEditingController(text: s?.instructorsCount.toString() ?? '0');
    _categoriesCtrl = TextEditingController(
      text: s?.vehicleCategories.join(', ') ?? 'B, C',
    );
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _countyCtrl, _townCtrl, _descCtrl, _phoneCtrl,
      _logoCtrl, _priceCtrl, _ratingCtrl, _reviewsCtrl, _instructorsCtrl, _categoriesCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      final categories = _categoriesCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final payload = (
        name: _nameCtrl.text.trim(),
        county: _countyCtrl.text.trim(),
        town: _townCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        contactPhone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        logoUrl: _logoCtrl.text.trim().isEmpty ? null : _logoCtrl.text.trim(),
        priceFrom: int.parse(_priceCtrl.text.trim()),
        rating: _ratingCtrl.text.trim().isEmpty ? null : double.tryParse(_ratingCtrl.text.trim()),
        reviewCount: _reviewsCtrl.text.trim().isEmpty ? null : int.tryParse(_reviewsCtrl.text.trim()),
        instructorsCount: int.parse(_instructorsCtrl.text.trim()),
        vehicleCategories: categories,
      );
      if (widget.school == null) {
        await repo.createSchool(
          name: payload.name,
          county: payload.county,
          town: payload.town,
          description: payload.description,
          contactPhone: payload.contactPhone,
          logoUrl: payload.logoUrl,
          priceFrom: payload.priceFrom,
          rating: payload.rating,
          reviewCount: payload.reviewCount,
          instructorsCount: payload.instructorsCount,
          vehicleCategories: payload.vehicleCategories,
        );
      } else {
        await repo.updateSchool(
          id: widget.school!.id,
          name: payload.name,
          county: payload.county,
          town: payload.town,
          description: payload.description,
          contactPhone: payload.contactPhone,
          logoUrl: payload.logoUrl,
          priceFrom: payload.priceFrom,
          rating: payload.rating,
          reviewCount: payload.reviewCount,
          instructorsCount: payload.instructorsCount,
          vehicleCategories: payload.vehicleCategories,
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
      title: widget.school == null ? 'Add School' : 'Edit School',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Name'), validator: _req),
              const SizedBox(height: 12),
              TextFormField(controller: _countyCtrl, decoration: const InputDecoration(labelText: 'County'), validator: _req),
              const SizedBox(height: 12),
              TextFormField(controller: _townCtrl, decoration: const InputDecoration(labelText: 'Town'), validator: _req),
              const SizedBox(height: 12),
              TextFormField(controller: _descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 12),
              TextFormField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Contact phone')),
              const SizedBox(height: 12),
              TextFormField(controller: _logoCtrl, decoration: const InputDecoration(labelText: 'Logo URL')),
              const SizedBox(height: 12),
              TextFormField(controller: _priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price from (Ksh)'), validator: _req),
              const SizedBox(height: 12),
              TextFormField(controller: _ratingCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Rating')),
              const SizedBox(height: 12),
              TextFormField(controller: _reviewsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Review count')),
              const SizedBox(height: 12),
              TextFormField(controller: _instructorsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Instructors count'), validator: _req),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoriesCtrl,
                decoration: const InputDecoration(labelText: 'Vehicle categories (comma-separated)', hintText: 'B, C'),
                validator: _req,
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
