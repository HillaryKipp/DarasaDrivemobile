import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/auth_providers.dart';
import '../../providers/data_providers.dart';
import '../../widgets/profile_menu_button.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPaid = ref.watch(hasPaidProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final currentUser = ref.watch(currentUserProvider);
    final isSignedIn = currentUser != null;

    final unitsAsync = ref.watch(unitsProvider);
    final attemptsAsync = ref.watch(testAttemptsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SafeArea(
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
                          'assets/images/darasadrive_logo.png',
                          height: 44,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.directions_car,
                                  color: AppColors.primary),
                        ),
                        const ProfileMenuButton(),
                      ],
                    ),
                  ),
                ),

                // Welcome Text Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile?.fullName != null
                                    ? 'Hello, ${profile!.fullName?.split(' ').first} 👋'
                                    : 'Hello, Driver 👋',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Welcome to\nDarasaDrive',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Learn, Practice and Pass.',
                                style:
                                    TextStyle(color: AppColors.textMuted, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Hero(
                          tag: 'welcome_image',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'assets/images/Automobile traffic design.jpg',
                              height: 90,
                              width: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
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
                                      icon: Icons.assignment,
                                      title: 'Tests',
                                      subtitle: 'Questions\nPractice & Pass',
                                      onTap: () => context.go('/tests'),
                                    ),
                                  ),
                                  const VerticalDivider(
                                      width: 1,
                                      thickness: 1,
                                      color: Color(0xFFF1F5F9)),
                                  Expanded(
                                    child: _GridItem(
                                      icon: Icons.menu_book_outlined,
                                      title: 'Learning Materials',
                                      subtitle: 'Study Notes,\nVideos & More',
                                      onTap: () => context.go('/materials'),
                                    ),
                                  ),
                                  const VerticalDivider(
                                      width: 1,
                                      thickness: 1,
                                      color: Color(0xFFF1F5F9)),
                                  Expanded(
                                    child: _GridItem(
                                      icon: Icons.bar_chart_outlined,
                                      title: 'Statistics',
                                      subtitle: 'Track Your\nProgress',
                                      onTap: () {
                                        if (isSignedIn) {
                                          context.go('/stats');
                                        } else {
                                          context.push('/auth');
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(
                                height: 1,
                                thickness: 1,
                                color: Color(0xFFF1F5F9)),
                            IntrinsicHeight(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _GridItem(
                                      icon: isSignedIn
                                          ? Icons.account_circle_outlined
                                          : Icons.login_outlined,
                                      title:
                                          isSignedIn ? 'My Profile' : 'Sign In',
                                      subtitle: isSignedIn
                                          ? 'View & \nManage Account'
                                          : 'Sign In to\nYour Account',
                                      onTap: () {
                                        if (isSignedIn) {
                                          context.push('/profile');
                                        } else {
                                          context.push('/auth');
                                        }
                                      },
                                    ),
                                  ),
                                  const VerticalDivider(
                                      width: 1,
                                      thickness: 1,
                                      color: Color(0xFFF1F5F9)),
                                  Expanded(
                                    child: _GridItem(
                                      icon: Icons.support_agent,
                                      title: 'Support',
                                      subtitle: 'Help &\nContact Us',
                                      onTap: () => context.go('/support'),
                                    ),
                                  ),
                                  const VerticalDivider(
                                      width: 1,
                                      thickness: 1,
                                      color: Color(0xFFF1F5F9)),
                                  Expanded(
                                    child: _GridItem(
                                      icon: Icons.video_library,
                                      title: 'Vlog',
                                      subtitle: 'Guidelines \nfrom our videos',
                                      onTap: () => context.go('/materials?tab=videos'),
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
                                  'Master the theory test and become a safe and confident driver.',
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      height: 1.4),
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
                            child: const Icon(Icons.verified_user_outlined,
                                color: Colors.white, size: 36),
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
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: isSignedIn ? null : () => context.push('/auth'),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Your Progress Overview',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFF1E293B)),
                                    ),
                                  ),
                                  if (!isSignedIn)
                                    const Row(
                                      children: [
                                        Text(
                                          'Sign in',
                                          style: TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(Icons.login_outlined,
                                            size: 14, color: AppColors.primary),
                                      ],
                                    ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Builder(
                                builder: (context) {
                                  if (!isSignedIn) {
                                    return _buildStatsRow('0/19', '0', '0%');
                                  }
                                  return attemptsAsync.when(
                                    data: (attempts) {
                                      final units = unitsAsync.valueOrNull ?? [];
                                      final totalUnits = units.length > 0 ? units.length : 19;
                                      
                                      // Calculate best scores per unit for progress calculation
                                      final bestScores = <String, double>{};
                                      int totalQuestions = 0;
                                      for (final a in attempts) {
                                        totalQuestions += a.total;
                                        final p = a.total == 0 ? 0.0 : a.score / a.total;
                                        if (p > (bestScores[a.unitId] ?? 0.0)) {
                                          bestScores[a.unitId] = p;
                                        }
                                      }
                                      
                                      final unitsCompleted = bestScores.length;
                                      final avgPct = attempts.isEmpty
                                          ? 0
                                          : (attempts.map((a) => a.percentage).reduce((a, b) => a + b) / attempts.length).round();

                                      final overallProgress = units.isEmpty 
                                          ? 0.0 
                                          : bestScores.values.fold(0.0, (a, b) => a + b) / units.length;

                                      return _buildStatsRow(
                                        '$unitsCompleted/$totalUnits',
                                        '$totalQuestions',
                                        '$avgPct%',
                                        progress: overallProgress,
                                      );
                                    },
                                    loading: () => const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(20),
                                        child: SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      ),
                                    ),
                                    error: (_, __) => _buildStatsRow('?', '?', '?'),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Payment Unlock
                if (!hasPaid)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    sliver: SliverToBoxAdapter(
                      child: Card(
                        color: AppColors.primary.withOpacity(0.08),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                              color: AppColors.primary.withOpacity(0.2)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const Text(
                                'Unlock Full Access',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryDark),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Get unlimited access to all units.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textMuted),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  final user = ref.read(currentUserProvider);
                                  if (user == null) {
                                    context.push('/auth?tab=signup');
                                  } else {
                                    context.push('/unlock');
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  elevation: 0,
                                ),
                                child: const Text('Unlock Full Access'),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () => context.push('/auth'),
                                child: const Text(
                                    'Already have an account? Sign in'),
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
        ),
      ),
    );
  }

  Widget _buildStatsRow(String units, String questions, String score, {double progress = 0}) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _StatItem(label: 'Units Done', value: units)),
            const SizedBox(width: 8),
            Expanded(child: _StatItem(label: 'Questions', value: questions)),
            const SizedBox(width: 8),
            Expanded(child: _StatItem(label: 'Avg Score', value: score)),
          ],
        ),
        const SizedBox(height: 20),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFFF1F5F9),
            color: AppColors.primary,
            minHeight: 8,
          ),
        ),
      ],
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
          ),
        ),
      ],
    );
  }
}
