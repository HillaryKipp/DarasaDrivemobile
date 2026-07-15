import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/school.dart';
import '../../providers/data_providers.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';

class SchoolsScreen extends ConsumerStatefulWidget {
  const SchoolsScreen({super.key});

  @override
  ConsumerState<SchoolsScreen> createState() => _SchoolsScreenState();
}

class _SchoolsScreenState extends ConsumerState<SchoolsScreen> {
  String _query = '';
  String _county = 'all';

  @override
  Widget build(BuildContext context) {
    final schoolsAsync = ref.watch(schoolsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black, size: 28),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'PRACTICAL LESSONS',
          style: TextStyle(
            color: Color(0xFF065F2F),
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 1.1,
          ),
        ),
        centerTitle: true,
      ),
      body: schoolsAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(schoolsProvider),
        ),
        data: (schools) {
          final filtered = schools.where(_matchesFilter).toList();

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              const SizedBox(height: 10),
              // Top Banner Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF065F2F),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.directions_car, color: Colors.white, size: 40),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Book Your\nPractical Lessons',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Learn from certified instructors at our partner driving schools.',
                            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // How It Works
              const Text(
                'How It Works',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StepItem(
                    number: 1,
                    icon: Icons.store_outlined,
                    title: 'Choose a School',
                    subtitle: 'Select a partner driving school near you.',
                    color: Colors.green.shade50,
                    iconColor: Colors.green,
                  ),
                  _StepItem(
                    number: 2,
                    icon: Icons.directions_car_outlined,
                    title: 'Choose Package',
                    subtitle: 'Select number of lessons that suits you.',
                    color: Colors.blue.shade50,
                    iconColor: Colors.blue,
                  ),
                  _StepItem(
                    number: 3,
                    icon: Icons.calendar_month_outlined,
                    title: 'Book & Learn',
                    subtitle: 'Book your lessons and start your training.',
                    color: Colors.indigo.shade50,
                    iconColor: Colors.indigo,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Find a Driving School
              const Text(
                'Find a Driving School',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 16),
              
              // Location Picker
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFF059669), size: 24),
                    const SizedBox(width: 12),
                    Text(
                      _county == 'all' ? 'Nairobi, Kenya' : '$_county, Kenya',
                      style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _showLocationPicker(context, schools),
                      child: const Text('Change', style: TextStyle(color: Color(0xFF065F2F), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // School List
              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: Text('No schools found matching your filters.')),
                )
              else
                ...filtered.map((school) => _SchoolCard(
                  school: school,
                  onTap: () => context.go('/booking/${school.id}'),
                )),
              const SizedBox(height: 30),
            ],
          );
        },
      ),
    );
  }

  bool _matchesFilter(School school) {
    if (_query.isNotEmpty &&
        !school.name.toLowerCase().contains(_query.toLowerCase()) &&
        !school.town.toLowerCase().contains(_query.toLowerCase())) {
      return false;
    }
    if (_county != 'all' && school.county != _county) return false;
    return true;
  }

  void _showLocationPicker(BuildContext context, List<School> schools) {
    final counties = schools.map((s) => s.county).toSet().toList()..sort();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('All Locations'),
                onTap: () {
                  setState(() => _county = 'all');
                  Navigator.pop(context);
                },
              ),
              ...counties.map((c) => ListTile(
                title: Text(c),
                onTap: () {
                  setState(() => _county = c);
                  Navigator.pop(context);
                },
              )),
            ],
          ),
        );
      },
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.number,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.iconColor,
  });

  final int number;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            '$number. $title',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted, height: 1.3),
          ),
        ],
      ),
    );
  }
}

class _SchoolCard extends StatelessWidget {
  const _SchoolCard({required this.school, required this.onTap});

  final School school;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // School Logo Placeholder/Image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAF9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: school.logoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          school.logoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.business, color: Color(0xFF94A3B8), size: 30),
                        ),
                      )
                    : const Icon(Icons.business, color: Color(0xFF94A3B8), size: 30),
              ),
              const SizedBox(width: 16),
              // School Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      school.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${school.town}, ${school.county}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${school.rating ?? 4.5}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${school.reviewCount ?? 120})',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Price and Chevron
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('From', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                  Text(
                    'KSh ${school.priceFrom}',
                    style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
