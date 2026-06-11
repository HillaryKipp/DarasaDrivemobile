import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'presentation/providers/auth_providers.dart';
import 'presentation/router/app_router.dart';
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
        if (authState.isLoading) {
          return const Scaffold(body: LoadingView(message: 'Loading…'));
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
