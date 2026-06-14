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
          onRetry: () => ref.invalidate(adminUsersProvider),
        ),
        data: (users) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) => _UserTile(user: users[index]),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    profile.fullName ?? profile.email ?? profile.id,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (user.isAdmin)
                  const Chip(
                    label: Text('Admin'),
                    backgroundColor: Color(0xFFE8F5E9),
                  ),
              ],
            ),
            if (profile.email != null) Text(profile.email!, style: const TextStyle(color: Colors.grey)),
            if (profile.phone != null) Text(profile.phone!),
            if (profile.createdAt != null)
              Text('Joined ${dateFmt.format(profile.createdAt!)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              children: [
                FilterChip(
                  label: Text(profile.hasPaid ? 'Paid' : 'Free'),
                  selected: profile.hasPaid,
                  onSelected: (v) => _togglePaid(context, ref, v),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Admin role'),
                  selected: user.isAdmin,
                  onSelected: (v) => _toggleAdmin(context, ref, v),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _togglePaid(BuildContext context, WidgetRef ref, bool hasPaid) async {
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

  Future<void> _toggleAdmin(BuildContext context, WidgetRef ref, bool isAdmin) async {
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
