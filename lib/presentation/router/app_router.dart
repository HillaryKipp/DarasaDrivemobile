import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_providers.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/booking/booking_flow_screen.dart';
import '../screens/booking/schools_screen.dart';
import '../screens/home/home_shell.dart';
import '../screens/home/home_tab.dart';
import '../screens/materials/materials_screen.dart';
import '../screens/profile/statistics_screen.dart';
import '../screens/tests/test_runner_screen.dart';
import '../screens/tests/units_screen.dart';
import '../screens/unlock/unlock_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      if (isLoading) return null;

      final user = authState.valueOrNull?.session?.user;
      final onAuth = state.matchedLocation == '/auth';
      final onUnlock = state.matchedLocation == '/unlock';

      if (user == null && _requiresAuth(state.matchedLocation)) {
        return '/auth';
      }
      if (user != null && onAuth) return '/home';
      if (onUnlock) return null;
      return null;
    },
    routes: [
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/unlock',
        builder: (context, state) => const UnlockScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tests',
                builder: (context, state) => const UnitsScreen(),
                routes: [
                  GoRoute(
                    path: ':unitId',
                    builder: (context, state) => TestRunnerScreen(
                      unitId: state.pathParameters['unitId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/materials',
                builder: (context, state) => const MaterialsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/booking',
                builder: (context, state) => const SchoolsScreen(),
                routes: [
                  GoRoute(
                    path: ':schoolId',
                    builder: (context, state) => BookingFlowScreen(
                      schoolId: state.pathParameters['schoolId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stats',
                builder: (context, state) => const StatisticsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

bool _requiresAuth(String location) {
  return location.startsWith('/stats') ||
      location.startsWith('/booking/') ||
      location.contains('/booking/');
}
