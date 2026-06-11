import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/auth_providers.dart';
import '../../providers/data_providers.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/loading_view.dart';
import '../home/home_shell.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = ref.watch(currentUserProvider);

    if (authState.isLoading) {
      return const Scaffold(body: LoadingView());
    }

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sign in to view your profile',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/auth'),
                child: const Text('Sign in'),
              ),
            ],
          ),
        ),
      );
    }

    final profileAsync = ref.watch(userProfileProvider);
    final bookingsAsync = ref.watch(userBookingsProvider);
    final hasPaid = ref.watch(hasPaidProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: profileAsync.when(
              loading: () => const GradientHeader(title: 'Profile'),
              error: (_, _) => const GradientHeader(title: 'Profile'),
              data: (profile) => GradientHeader(
                title: profile?.fullName ?? 'Student',
                subtitle: user.email,
                badge: hasPaid ? 'Full Access' : 'Free account',
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                profileAsync.when(
                  loading: () => const Card(child: Padding(padding: EdgeInsets.all(20), child: LoadingView())),
                  error: (e, _) => Text(e.toString()),
                  data: (profile) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _InfoRow(
                            icon: Icons.phone,
                            label: 'Phone',
                            value: profile?.phone ?? '—',
                          ),
                          const Divider(),
                          _InfoRow(
                            icon: Icons.calendar_today,
                            label: 'Joined',
                            value: profile?.createdAt != null
                                ? DateFormat.yMMMd().format(profile!.createdAt!)
                                : '—',
                          ),
                          const Divider(),
                          _InfoRow(
                            icon: Icons.credit_card,
                            label: 'Plan',
                            value: hasPaid ? 'Full Access' : 'Free',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (!hasPaid)
                  ElevatedButton(
                    onPressed: () => context.push('/unlock'),
                    child: const Text('Unlock with M-Pesa'),
                  ),
                ListTile(
                  leading: const Icon(Icons.bar_chart),
                  title: const Text('Test statistics'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/profile/statistics'),
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text('Sign out'),
                  onTap: () async {
                    await ref.read(authRepositoryProvider).signOut();
                    if (context.mounted) context.go('/auth');
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'My bookings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                bookingsAsync.when(
                  loading: () => const LoadingView(),
                  error: (e, _) => Text(e.toString()),
                  data: (bookings) {
                    if (bookings.isEmpty) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const Text('No bookings yet.'),
                              TextButton(
                                onPressed: () => context.go('/booking'),
                                child: const Text('Book a school'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: bookings.map((b) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(b.schoolName ?? 'School'),
                            subtitle: Text(
                              'Cat ${b.vehicleCategory} • ${b.scheduledDate}',
                            ),
                            trailing: Chip(
                              label: Text(b.status),
                              backgroundColor: b.status == 'confirmed'
                                  ? AppColors.primary.withValues(alpha: 0.12)
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}
