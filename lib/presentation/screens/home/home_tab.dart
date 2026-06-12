import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/auth_providers.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPaid = ref.watch(hasPaidProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Top Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 12, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      'assets/images/ntsalogo.png',
                      height: 44,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.directions_car, color: AppColors.primary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_none_outlined, size: 28),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),

            // Welcome Text Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?.fullName != null
                          ? 'Hello, ${profile!.fullName?.split(' ').first}! 👋'
                          : 'Hello, Driver! 👋',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Welcome to\nDarasaDrive Academy',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Learn. Practice. Pass. Drive with Confidence.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

            // Main Grid Menu
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Column(
                      children: [
                        IntrinsicHeight(
                          child: Row(
                            children: [
                              Expanded(
                                child: _GridItem(
                                  icon: Icons.description_outlined,
                                  title: 'Tests',
                                  subtitle: '19 Units\nPractice & Pass',
                                  onTap: () => context.go('/tests'),
                                ),
                              ),
                              const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                              Expanded(
                                child: _GridItem(
                                  icon: Icons.menu_book_outlined,
                                  title: 'Learning Materials',
                                  subtitle: 'Study Notes,\nVideos & More',
                                  onTap: () => context.go('/materials'),
                                ),
                              ),
                              const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                              Expanded(
                                child: _GridItem(
                                  icon: Icons.bar_chart_outlined,
                                  title: 'Statistics',
                                  subtitle: 'Track Your\nProgress',
                                  onTap: () => context.go('/profile/stats'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                        IntrinsicHeight(
                          child: Row(
                            children: [
                              Expanded(
                                child: _GridItem(
                                  icon: Icons.directions_car_outlined,
                                  title: 'Practical Lessons',
                                  subtitle: 'Book & Manage\nDriving Lessons',
                                  onTap: () => context.go('/booking'),
                                ),
                              ),
                              const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                              Expanded(
                                child: _GridItem(
                                  icon: Icons.calendar_month_outlined,
                                  title: 'My Bookings',
                                  subtitle: 'View Your\nBookings',
                                  onTap: () => context.go('/booking'),
                                ),
                              ),
                              const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                              Expanded(
                                child: _GridItem(
                                  icon: Icons.info_outline,
                                  title: 'NTSA Info',
                                  subtitle: 'Guidelines &\nExam Process',
                                  onTap: () {},
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Green Call to Action Banner
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF065F2F),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Prepare. Practice. Pass.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Master the NTSA theory test and become a safe and confident driver.',
                              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.verified_user_outlined, color: Colors.white, size: 36),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Progress Overview Card
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Progress Overview',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _StatItem(label: 'Units Completed', value: '3/19'),
                          _StatItem(label: 'Questions Attempted', value: '180'),
                          _StatItem(label: 'Average Score', value: '72%'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: 3 / 19,
                          backgroundColor: const Color(0xFFF1F5F9),
                          color: AppColors.primary,
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Payment Unlock (Retaining original functionality)
            if (!hasPaid)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                sliver: SliverToBoxAdapter(
                  child: Card(
                    color: AppColors.primary.withOpacity(0.08),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            'Unlock Full Access',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Get unlimited access to all 19 units and booking features.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => context.push('/unlock'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              elevation: 0,
                            ),
                            child: const Text('Unlock with M-Pesa'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }
}

class _GridItem extends StatelessWidget {
  const _GridItem({
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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF059669), size: 30),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF1E293B),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B)),
        ),
      ],
    );
  }
}
