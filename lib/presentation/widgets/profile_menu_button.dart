import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../providers/auth_providers.dart';
import '../providers/repository_providers.dart';

class ProfileMenuButton extends ConsumerWidget {
  const ProfileMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isLoggedIn = user != null;
    final isAdmin = ref.watch(isAdminProvider).valueOrNull ?? false;

    return PopupMenuButton<String>(
      icon: const Icon(Icons.account_circle_outlined, size: 28),
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, 48),
      onSelected: (value) => _onSelected(context, ref, value),
      itemBuilder: (context) {
        if (isLoggedIn) {
          return [
            _menuItem(
              value: 'profile',
              icon: Icons.person_outline,
              label: 'View profile',
            ),
            if (isAdmin)
              _menuItem(
                value: 'admin',
                icon: Icons.admin_panel_settings_outlined,
                label: 'Admin panel',
              ),
            const PopupMenuDivider(height: 1),
            _menuItem(
              value: 'logout',
              icon: Icons.logout,
              label: 'Log out',
              color: Colors.redAccent,
            ),
          ];
        }

        return [
          _menuItem(
            value: 'signin',
            icon: Icons.login,
            label: 'Sign in',
          ),
          _menuItem(
            value: 'signup',
            icon: Icons.person_add_outlined,
            label: 'Sign up',
          ),
        ];
      },
    );
  }

  PopupMenuItem<String> _menuItem({
    required String value,
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? AppColors.textMuted),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: color ?? const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onSelected(
    BuildContext context,
    WidgetRef ref,
    String value,
  ) async {
    switch (value) {
      case 'signin':
        context.push('/auth');
      case 'signup':
        context.push('/auth?tab=signup');
      case 'profile':
        context.push('/profile');
      case 'admin':
        context.push('/admin');
      case 'logout':
        await ref.read(authRepositoryProvider).signOut();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Signed out successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
    }
  }
}
