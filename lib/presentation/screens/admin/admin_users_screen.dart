import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/admin_user.dart';
import '../../providers/admin_providers.dart';
import '../../providers/auth_providers.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import 'admin_helpers.dart';

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);

    return AdminScaffold(
      title: 'Users',
      body: usersAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(adminUsersProvider)),
        data: (users) => ListView(
          children: [
            AdminBanner(
              icon: Icons.people_outline,
              title: 'Users',
              subtitle: '${users.length} registered user${users.length == 1 ? '' : 's'}',
              trailingIcon: Icons.manage_accounts_outlined,
            ),
            if (users.isEmpty)
              const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: Text('No users found')))
            else ...[
              const AdminSectionLabel(text: 'All Users'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    for (int i = 0; i < users.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      _UserTile(user: users[i]),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _UserTile extends ConsumerWidget {
  const _UserTile({required this.user});
  final AdminUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = user.profile;
    final dateFmt = DateFormat.yMMMd();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kAdminBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: kAdminGreen,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    _initials(profile.fullName ?? profile.email ?? '?'),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (profile.fullName ?? profile.email ?? profile.id)
                          .toUpperCase(),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: kAdminDark,
                          letterSpacing: 0.2),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (profile.email != null)
                      Text(profile.email!,
                          style: const TextStyle(
                              color: kAdminMuted, fontSize: 11)),
                  ],
                ),
              ),
              if (user.isAdmin)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Admin',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF5B21B6))),
                ),
            ],
          ),

          // Meta row
          if (profile.phone != null || profile.createdAt != null) ...[
            const SizedBox(height: 8),
            const Divider(height: 1, color: kAdminBorder),
            const SizedBox(height: 8),
            Row(
              children: [
                if (profile.phone != null) ...[
                  const Icon(Icons.phone_outlined,
                      size: 13, color: kAdminMuted),
                  const SizedBox(width: 4),
                  Text(profile.phone!,
                      style: const TextStyle(
                          fontSize: 11, color: kAdminMuted)),
                  const SizedBox(width: 12),
                ],
                if (profile.createdAt != null) ...[
                  const Icon(Icons.calendar_today_outlined,
                      size: 13, color: kAdminMuted),
                  const SizedBox(width: 4),
                  Text(dateFmt.format(profile.createdAt!),
                      style: const TextStyle(
                          fontSize: 11, color: kAdminMuted)),
                ],
              ],
            ),
          ],

          // Chips row
          const SizedBox(height: 10),
          Row(
            children: [
              _ToggleChip(
                label: profile.hasPaid ? 'Paid' : 'Free',
                active: profile.hasPaid,
                activeColor: kAdminGreen,
                onToggle: (v) => _togglePaid(context, ref, v),
              ),
              const SizedBox(width: 8),
              _ToggleChip(
                label: 'Admin role',
                active: user.isAdmin,
                activeColor: const Color(0xFF5B21B6),
                onToggle: (v) => _toggleAdmin(context, ref, v),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+|@'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Future<void> _togglePaid(
      BuildContext context, WidgetRef ref, bool hasPaid) async {
    try {
      await ref.read(adminRepositoryProvider).updateUserProfile(
        id: user.profile.id,
        hasPaid: hasPaid,
      );
      ref.invalidate(adminUsersProvider);
      ref.invalidate(userProfileProvider);
      if (context.mounted) showAdminSuccess(context, 'Payment status updated');
    } catch (e) {
      if (context.mounted) showAdminError(context, e);
    }
  }

  Future<void> _toggleAdmin(
      BuildContext context, WidgetRef ref, bool isAdmin) async {
    try {
      await ref.read(adminRepositoryProvider).setAdminRole(
        userId: user.profile.id,
        isAdmin: isAdmin,
      );
      ref.invalidate(adminUsersProvider);
      ref.invalidate(isAdminProvider);
      if (context.mounted) showAdminSuccess(context, 'Admin role updated');
    } catch (e) {
      if (context.mounted) showAdminError(context, e);
    }
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onToggle,
  });

  final String label;
  final bool active;
  final Color activeColor;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onToggle(!active),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active
              ? activeColor.withValues(alpha: 0.12)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? activeColor.withValues(alpha: 0.4) : kAdminBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: active ? activeColor : kAdminMuted,
          ),
        ),
      ),
    );
  }
}