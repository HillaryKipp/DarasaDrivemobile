import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/school.dart';
import '../../providers/data_providers.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../home/home_shell.dart';

class SchoolsScreen extends ConsumerStatefulWidget {
  const SchoolsScreen({super.key});

  @override
  ConsumerState<SchoolsScreen> createState() => _SchoolsScreenState();
}

class _SchoolsScreenState extends ConsumerState<SchoolsScreen> {
  String _query = '';
  String _county = 'all';
  String _category = 'all';

  @override
  Widget build(BuildContext context) {
    final schoolsAsync = ref.watch(schoolsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: GradientHeader(
              badge: 'Practical lessons',
              title: 'Book a driving school',
              subtitle: 'Compare top-rated partner schools across Kenya.',
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search by school or town',
                        ),
                        onChanged: (v) => setState(() => _query = v.toLowerCase()),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          schoolsAsync.when(
            loading: () => const SliverFillRemaining(child: LoadingView()),
            error: (e, _) => SliverFillRemaining(
              child: ErrorView(
                message: e.toString(),
                onRetry: () => ref.invalidate(schoolsProvider),
              ),
            ),
            data: (schools) {
              final counties = schools.map((s) => s.county).toSet().toList()..sort();
              final filtered = schools.where(_matchesFilter).toList();

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: ValueKey('county-$_county'),
                            initialValue: _county,
                            decoration: const InputDecoration(labelText: 'County'),
                            items: [
                              const DropdownMenuItem(value: 'all', child: Text('All counties')),
                              ...counties.map(
                                (c) => DropdownMenuItem(value: c, child: Text(c)),
                              ),
                            ],
                            onChanged: (v) => setState(() => _county = v ?? 'all'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: ValueKey('category-$_category'),
                            initialValue: _category,
                            decoration: const InputDecoration(labelText: 'Category'),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('All')),
                              DropdownMenuItem(value: 'A', child: Text('A — Motorcycle')),
                              DropdownMenuItem(value: 'B', child: Text('B — Saloon')),
                              DropdownMenuItem(value: 'C', child: Text('C — Commercial')),
                            ],
                            onChanged: (v) => setState(() => _category = v ?? 'all'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (filtered.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('No schools match your filters.')),
                      )
                    else
                      ...filtered.map(
                        (school) => _SchoolCard(
                          school: school,
                          onTap: () => context.go('/booking/${school.id}'),
                        ),
                      ),
                  ]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  bool _matchesFilter(School school) {
    if (_query.isNotEmpty &&
        !school.name.toLowerCase().contains(_query) &&
        !school.town.toLowerCase().contains(_query)) {
      return false;
    }
    if (_county != 'all' && school.county != _county) return false;
    if (_category != 'all' && !school.vehicleCategories.contains(_category)) {
      return false;
    }
    return true;
  }
}

class _SchoolCard extends StatelessWidget {
  const _SchoolCard({required this.school, required this.onTap});

  final School school;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      school.name,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (school.rating != null)
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: AppColors.gold),
                        Text(' ${school.rating!.toStringAsFixed(1)}'),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${school.town}, ${school.county}',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: school.vehicleCategories
                    .map((c) => Chip(label: Text('Cat $c'), visualDensity: VisualDensity.compact))
                    .toList(),
              ),
              const SizedBox(height: 8),
              Text(
                'From KSh ${school.priceFrom}',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
