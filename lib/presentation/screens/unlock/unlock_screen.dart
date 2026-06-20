import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/auth_providers.dart';
import '../../providers/iap_providers.dart';
import '../../widgets/loading_view.dart';
import '../auth/auth_screen.dart';

/// Payment screen shown after sign-in when the user has not paid yet.
/// Digital content must be unlocked via Google Play Billing to comply with Play Store policies.
class UnlockScreen extends ConsumerStatefulWidget {
  final String? from;
  const UnlockScreen({super.key, this.from});

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  static const _perks = [
    'Driving tests',
    'PDF and video materials',
    'Progress analytics and weak-area insights',
  ];

  void _goToSignUp() {
    context.go(
      '/auth',
      extra: const AuthScreenArgs(initialTab: 1),
    );
  }

  void _goToSignIn() {
    context.go(
      '/auth',
      extra: const AuthScreenArgs(initialTab: 0),
    );
  }

  void _skipUnlock() {
    ref.read(unlockSkippedProvider.notifier).state = true;
    context.go('/home');
  }

  Future<void> _onBuyIap(ProductDetails product) async {
    await ref.read(iapStateNotifierProvider.notifier).buyUnlock(product);
  }

  Future<void> _onRestore() async {
    await ref.read(iapStateNotifierProvider.notifier).restorePurchases();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isLoggedIn = user != null;

    final iapState = ref.watch(iapStateNotifierProvider);
    final iapProducts = ref.watch(iapProductsProvider);

    final busy = iapState.isLoading;

    // Listen for IAP errors
    ref.listen(iapStateNotifierProvider, (previous, next) {
      next.whenOrNull(error: (err, stack) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Store error: $err'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () => ref.read(iapStateNotifierProvider.notifier).reset(),
            ),
          ),
        );
      });
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _skipUnlock();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Unlock Full Access'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _skipUnlock,
            tooltip: 'Continue for free',
          ),
          actions: [
            if (isLoggedIn)
              TextButton(
                onPressed: busy ? null : _onRestore,
                child: const Text('RESTORE', style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            isLoggedIn ? 'Complete your payment' : 'Create account & unlock',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isLoggedIn
                                ? 'Unlock full access to all materials and tests.'
                                : 'Register first if not registered, then sign in to pay.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          iapProducts.when(
                            data: (products) => products.isNotEmpty
                                ? Text(
                                    products.first.price,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                            loading: () => const SizedBox(
                              height: 44,
                              child: Center(
                                child: CircularProgressIndicator(color: Colors.white),
                              ),
                            ),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final perk in _perks)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(perk)),
                                ],
                              ),
                            ),
                          const Divider(height: 32),
                          if (!isLoggedIn) ...[
                            const Text(
                              'Step 1: Create your account',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Register with your details. After verifying your email and signing in, you will be guided to unlock the app.',
                              style: TextStyle(color: AppColors.textMuted, height: 1.4),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: busy ? null : _goToSignUp,
                              child: const Text('Create account'),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Already have an account?',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Sign in after verifying your email.',
                                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton(
                                      onPressed: busy ? null : _goToSignIn,
                                      child: const Text('Sign in'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            const Text(
                              'Step 2: Unlock Access',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Use Google Play Billing to securely unlock all premium content.',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 16),
                            iapProducts.when(
                              data: (products) {
                                if (products.isEmpty) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 20),
                                      child: Text(
                                        'Store items not found. Please ensure you are using the official version of the app from the Play Store.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.redAccent, fontSize: 13),
                                      ),
                                    ),
                                  );
                                }
                                final product = products.first;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: busy ? null : () => _onBuyIap(product),
                                      icon: const Icon(Icons.shopping_bag_outlined),
                                      label: Text('Unlock with Google Play (${product.price})'),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Safe and secure checkout powered by Google.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                                    ),
                                    const SizedBox(height: 16),
                                    OutlinedButton(
                                      onPressed: busy ? null : _onRestore,
                                      child: const Text('Restore Purchase'),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Already paid but account not unlocked? Tap Restore.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                                    ),
                                  ],
                                );
                              },
                              loading: () => const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              error: (err, _) => Center(
                                child: Text(
                                  'Store connection error. Please try again later.',
                                  style: TextStyle(color: Colors.redAccent.withValues(alpha: 0.8)),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          TextButton(
                            onPressed: _skipUnlock,
                            child: const Text('CONTINUE FOR FREE'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (busy)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: Stack(
                    children: [
                      const LoadingView(message: 'Processing your request…'),
                      Positioned(
                        bottom: 40,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: TextButton(
                            onPressed: () => ref.read(iapStateNotifierProvider.notifier).reset(),
                            child: const Text(
                              'Cancel Waiting',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
