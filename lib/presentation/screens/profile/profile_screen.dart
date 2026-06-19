import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/auth_providers.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/loading_view.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const _green = Color(0xFF065F2F);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = ref.watch(currentUserProvider);

    if (authState.isLoading) {
      return const Scaffold(body: LoadingView());
    }

    if (user == null) {
      return Scaffold(
        appBar: _buildAppBar(context),
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
    final hasPaid = ref.watch(hasPaidProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: ListView(
        children: [
          // ── Profile Banner ───────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: profileAsync.when(
              loading: () => _ProfileBanner(
                initials: '...',
                name: 'Loading…',
                email: '',
                hasPaid: hasPaid,
              ),
              error: (_, __) => _ProfileBanner(
                initials: _initials(user.email ?? ''),
                name: user.email ?? 'Student',
                email: user.email ?? '',
                hasPaid: hasPaid,
              ),
              data: (profile) => _ProfileBanner(
                initials: _initials(profile?.fullName ?? user.email ?? ''),
                name: profile?.fullName ?? 'Student',
                email: user.email ?? '',
                hasPaid: hasPaid,
              ),
            ),
          ),

          if (!hasPaid)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _UnlockTile(onTap: () => context.push('/unlock')),
            ),

          _SectionLabel(text: 'ACCOUNT INFO'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                profileAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(20),
                    child: LoadingView(),
                  ),
                  error: (e, _) => Text(e.toString()),
                  data: (profile) => Column(
                    children: [
                      _InfoTile(
                        icon: Icons.phone_outlined,
                        title: 'PHONE',
                        subtitle: profile?.phone ?? '—',
                      ),
                      const SizedBox(height: 10),
                      _InfoTile(
                        icon: Icons.calendar_today_outlined,
                        title: 'JOINED',
                        subtitle: profile?.createdAt != null
                            ? DateFormat.yMMMd().format(profile!.createdAt!)
                            : '—',
                      ),
                      const SizedBox(height: 10),
                      _InfoTile(
                        icon: Icons.badge_outlined,
                        title: 'PLAN',
                        subtitle: hasPaid ? 'Subscription active' : 'Free tier',
                        trailing: hasPaid
                            ? _StatusBadge(
                          label: 'Full Access',
                          bg: const Color(0xFFDCFCE7),
                          fg: _green,
                        )
                            : _StatusBadge(
                          label: 'Free',
                          bg: const Color(0xFFFEF9C3),
                          fg: const Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          _SectionLabel(text: 'ACTIONS'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _ActionTile(
                  icon: Icons.logout_outlined,
                  iconBg: _green,
                  title: 'SIGN OUT',
                  subtitle: 'End your current session',
                  onTap: () async {
                    await ref.read(authRepositoryProvider).signOut();
                    if (context.mounted) context.go('/auth');
                  },
                ),
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.delete_outline,
                  iconBg: const Color(0xFFFEE2E2),
                  iconColor: Colors.redAccent,
                  title: 'DELETE ACCOUNT',
                  titleColor: Colors.redAccent,
                  subtitle: 'Permanently remove your data',
                  onTap: () => _showDeleteConfirmation(context, ref, user.id),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.chevron_left, color: Colors.black, size: 28),
        onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
      ),
      title: const Text(
        'PROFILE',
        style: TextStyle(
          color: _green,
          fontWeight: FontWeight.bold,
          fontSize: 18,
          letterSpacing: 1.1,
        ),
      ),
      centerTitle: true,
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context, WidgetRef ref, String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Account?'),
        content: const Text(
          'This will permanently delete your account, your progress, and all associated data. This action cannot be undone.',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('DELETE PERMANENTLY'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        // Show a non-dismissible loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const Center(child: CircularProgressIndicator()),
        );

        await ref.read(authRepositoryProvider).deleteAccount(userId);

        if (context.mounted) {
          // Close loading dialog
          Navigator.pop(context);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your account has been deleted.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.go('/auth');
        }
      } catch (e) {
        if (context.mounted) {
          // Close loading dialog
          Navigator.pop(context);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+|@'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

// ── Shared UI Widgets ──────────────────────────────────────────────────────

class _ProfileBanner extends StatelessWidget {
  const _ProfileBanner({
    required this.initials,
    required this.name,
    required this.email,
    required this.hasPaid,
  });

  final String initials;
  final String name;
  final String email;
  final bool hasPaid;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF065F2F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              initials,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(
            hasPaid ? Icons.verified_outlined : Icons.lock_outline,
            color: Colors.white70,
            size: 24,
          ),
        ],
      ),
    );
  }
}

class _UnlockTile extends StatelessWidget {
  const _UnlockTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.lock_open_outlined,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UNLOCK FULL ACCESS',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF92400E),
                        letterSpacing: 0.2),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Practise unlimited',
                    style: TextStyle(color: Color(0xFFB45309), fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFB45309), size: 20),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFF065F2F),
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF065F2F),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: Colors.white, size: 17),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                      color: Color(0xFF64748B), fontSize: 11),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor = Colors.white,
    this.titleColor = const Color(0xFF1E293B),
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final Color titleColor;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: iconColor, size: 17),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: titleColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        color: Color(0xFF64748B), fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: Color(0xFF94A3B8), size: 20),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(
      {required this.label, required this.bg, required this.fg});

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
      BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}
