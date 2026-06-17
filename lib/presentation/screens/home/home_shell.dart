import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_providers.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSignedIn = ref.watch(currentUserProvider) != null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // 1. Try to pop the nested navigator for the current branch
        final NavigatorState? branchNavigator =
            navigationShell.shellRouteContext.navigatorKey.currentState;
        if (branchNavigator != null && branchNavigator.canPop()) {
          branchNavigator.pop();
          return;
        }

        // 2. If we're on a tab other than Home, switch back to Home
        if (navigationShell.currentIndex != 0) {
          navigationShell.goBranch(0);
          return;
        }

        // 3. Otherwise, if we are on the Home tab root, exit the app
        SystemNavigator.pop();
      },
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) {
            // If user is not signed in and tries to access the Stats tab (index 4),
            // we push the auth screen instead of switching branches. This keeps
            // the current branch in the history so they can navigate back.
            if (index == 4 && !isSignedIn) {
              context.push('/auth');
              return;
            }

            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment),
              selectedIcon: Icon(Icons.assignment),
              label: 'Tests',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: 'Materials',
            ),
            NavigationDestination(
              icon: Icon(Icons.support_agent),
              selectedIcon: Icon(Icons.help),
              label: 'Support',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Stats',
            ),
          ],
        ),
      ),
    );
  }
}

class GradientHeader extends StatelessWidget {
  const GradientHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.badge,
  });

  final String title;
  final String? subtitle;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A8F3D), Color(0xFF067A33)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(badge!,
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
