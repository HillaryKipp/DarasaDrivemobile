import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/errors/error_handler.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/auth_providers.dart';
import 'presentation/router/app_router.dart';
import 'presentation/widgets/error_view.dart';
import 'presentation/widgets/loading_view.dart';

class DarasaDriveApp extends ConsumerWidget {
  const DarasaDriveApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final authState = ref.watch(authStateProvider);

    return MaterialApp.router(
      title: 'DarasaDrive',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
      builder: (context, child) {
        return authState.when(
          data: (data) {
            // Success: Remove splash and show the app
            FlutterNativeSplash.remove();
            return child ?? const SizedBox.shrink();
          },
          loading: () {
            // Still loading auth state: Do nothing (Splash remains visible)
            return const Scaffold(body: LoadingView(message: 'Initializing…'));
          },
          error: (err, stack) {
            // Error (usually connection): Remove splash so we can show the error UI
            FlutterNativeSplash.remove();
            return Scaffold(
              body: ErrorView(
                error: err,
                onRetry: () => ref.invalidate(authStateProvider),
              ),
            );
          },
        );
      },
    );
  }
}
