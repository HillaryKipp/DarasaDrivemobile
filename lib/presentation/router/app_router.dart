import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/material_item.dart';
import '../../domain/entities/question.dart';
import '../../domain/entities/school.dart';
import '../../domain/entities/unit.dart';
import '../providers/auth_providers.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_materials_screen.dart';
import '../screens/admin/admin_payments_screen.dart';
import '../screens/admin/admin_questions_screen.dart';
import '../screens/admin/admin_schools_screen.dart';
import '../screens/admin/admin_units_screen.dart';
import '../screens/admin/admin_users_screen.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/booking/booking_flow_screen.dart';
import '../screens/booking/schools_screen.dart';
import '../screens/home/home_shell.dart';
import '../screens/home/home_tab.dart';
import '../screens/materials/materials_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/statistics_screen.dart';
import '../screens/support/support.dart';
import '../screens/tests/test_runner_screen.dart';
import '../screens/tests/units_screen.dart';
import '../screens/unlock/unlock_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final isAdminAsync = ref.watch(isAdminProvider);
  final hasPaid = ref.watch(hasPaidProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      if (isLoading) return null;

      final user = authState.valueOrNull?.session?.user;
      final event = authState.valueOrNull?.event;
      final location = state.matchedLocation;

      // Handle Password Recovery Event
      if (event == AuthChangeEvent.passwordRecovery) {
        return '/reset-password';
      }

      final onAuth = location == '/auth';
      final onUnlock = location == '/unlock';
      final onResetPassword = location == '/reset-password';
      final onLoginCallback = location == '/login-callback';
      final onAdmin = location.startsWith('/admin');

      // Admin access control
      if (onAdmin) {
        if (user == null) return '/auth';
        if (isAdminAsync.isLoading) return null;
        if (isAdminAsync.valueOrNull != true) return '/home';
      }

      // Guest access control for specific sections
      if (user == null && _requiresAuth(location)) {
        return '/auth';
      }

      // If user is already logged in and paid, don't let them stay on Auth or Unlock screens
      if (user != null && (onAuth || onLoginCallback)) {
        final isAdmin = isAdminAsync.valueOrNull ?? false;
        if (isAdmin || hasPaid) return '/home';
        // Allow them to proceed to /unlock if they came from Auth
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/auth',
        builder: (context, state) {
          final args = state.extra as AuthScreenArgs?;
          final tab = state.uri.queryParameters['tab'];
          return AuthScreen(
            initialTab: args?.initialTab ?? (tab == 'signup' ? 1 : 0),
            prefillEmail: args?.prefillEmail ?? state.uri.queryParameters['email'],
            prefillPhone: args?.prefillPhone ?? state.uri.queryParameters['phone'],
          );
        },
      ),
      GoRoute(
        path: '/login-callback',
        builder: (context, state) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/unlock',
        builder: (context, state) {
          final from = state.uri.queryParameters['from'];
          return UnlockScreen(from: from);
        },
      ),
      GoRoute(
        path: '/admin',
        redirect: (context, state) =>
            state.uri.path == '/admin' ? '/admin/dashboard' : null,
        routes: [
          GoRoute(
            path: 'dashboard',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: 'units',
            builder: (context, state) => const AdminUnitsScreen(),
            routes: [
              GoRoute(
                path: 'form',
                builder: (context, state) =>
                    AdminUnitFormScreen(unit: state.extra as Unit?),
              ),
            ],
          ),
          GoRoute(
            path: 'questions',
            builder: (context, state) => const AdminQuestionsScreen(),
            routes: [
              GoRoute(
                path: 'form',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  return AdminQuestionFormScreen(
                    unitId: extra?['unitId'] as String? ?? '',
                    question: extra?['question'] as Question?,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: 'materials',
            builder: (context, state) => const AdminMaterialsScreen(),
            routes: [
              GoRoute(
                path: 'form',
                builder: (context, state) =>
                    AdminMaterialFormScreen(material: state.extra as MaterialItem?),
              ),
            ],
          ),
          GoRoute(
            path: 'schools',
            builder: (context, state) => const AdminSchoolsScreen(),
            routes: [
              GoRoute(
                path: 'form',
                builder: (context, state) =>
                    AdminSchoolFormScreen(school: state.extra as School?),
              ),
            ],
          ),
          GoRoute(
            path: 'users',
            builder: (context, state) => const AdminUsersScreen(),
          ),
          GoRoute(
            path: 'payments',
            builder: (context, state) => const AdminPaymentsScreen(),
          ),
        ],
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
                builder: (context, state) {
                  final tab = state.uri.queryParameters['tab'];
                  return MaterialsScreen(
                    initialTab: tab == 'videos' ? 1 : 0,
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/support',
                builder: (context, state) => const SupportTab(),
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
  return location.startsWith('/stats') || location.startsWith('/profile');
}
