import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'admin_helpers.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Admin Panel',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            AdminModuleCard(
              icon: Icons.library_books_outlined,
              title: 'Units',
              subtitle: 'Manage test units',
              onTap: () => context.push('/admin/units'),
            ),
            AdminModuleCard(
              icon: Icons.quiz_outlined,
              title: 'Questions',
              subtitle: 'Manage quiz questions',
              onTap: () => context.push('/admin/questions'),
            ),
            AdminModuleCard(
              icon: Icons.menu_book_outlined,
              title: 'Materials',
              subtitle: 'Notes, videos & more',
              onTap: () => context.push('/admin/materials'),
            ),
            AdminModuleCard(
              icon: Icons.directions_car_outlined,
              title: 'Schools',
              subtitle: 'Driving schools',
              onTap: () => context.push('/admin/schools'),
            ),
            AdminModuleCard(
              icon: Icons.people_outline,
              title: 'Users',
              subtitle: 'View & manage users',
              onTap: () => context.push('/admin/users'),
            ),
            AdminModuleCard(
              icon: Icons.payments_outlined,
              title: 'Payments',
              subtitle: 'M-Pesa transactions',
              onTap: () => context.push('/admin/payments'),
            ),
          ],
        ),
      ),
    );
  }
}
