import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/auth_providers.dart';
import '../../widgets/stat_card.dart';
import 'home_shell.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPaid = ref.watch(hasPaidProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: GradientHeader(
              badge: 'DarasaDrive',
              title: 'Pass your NTSA theory test',
              subtitle: profile?.fullName != null
                  ? 'Welcome back, ${profile!.fullName}'
                  : '16 units · 950+ questions · Partner schools',
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const Row(
                  children: [
                    Expanded(child: StatCard(label: 'Units', value: '16')),
                    SizedBox(width: 12),
                    Expanded(child: StatCard(label: 'Questions', value: '950+')),
                  ],
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Expanded(child: StatCard(label: 'Per unit', value: '50+')),
                    SizedBox(width: 12),
                    Expanded(child: StatCard(label: 'Pass rate', value: '92%')),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Quick actions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _ActionTile(
                  icon: Icons.quiz,
                  title: 'Start theory tests',
                  subtitle: 'Practise all 16 NTSA units',
                  onTap: () => context.go('/tests'),
                ),
                _ActionTile(
                  icon: Icons.menu_book,
                  title: 'Learning materials',
                  subtitle: 'PDFs and videos per unit',
                  onTap: () => context.go('/materials'),
                ),
                _ActionTile(
                  icon: Icons.directions_car,
                  title: 'Book practical lessons',
                  subtitle: 'Partner driving schools across Kenya',
                  onTap: () => context.go('/booking'),
                ),
                if (!hasPaid) ...[
                  const SizedBox(height: 20),
                  Card(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            'Unlock all 16 units',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'One-time M-Pesa payment unlocks tests, materials & booking.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => context.push('/unlock'),
                            child: const Text('Unlock with M-Pesa'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
