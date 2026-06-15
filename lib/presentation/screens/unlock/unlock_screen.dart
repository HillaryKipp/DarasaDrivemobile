import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/repositories/payment_repository.dart';
import '../../providers/auth_providers.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/loading_view.dart';
import '../auth/auth_screen.dart';

/// Payment screen shown after sign-in when the user has not paid yet.
/// Guests are directed to register first via the auth screen.
class UnlockScreen extends ConsumerStatefulWidget {
  final String? from;
  const UnlockScreen({super.key, this.from});

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _loading = false;
  bool _waiting = false;
  String? _overlayMessage;
  String? _errorMessage;
  String? _lastCheckoutRequestId;

  static const _perks = [
    'All 16 NTSA units + 950+ questions',
    'Every PDF and video material',
    'Progress analytics and weak-area insights',
    'Book practical lessons with partner schools',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefillFromUser());
  }

  void _prefillFromUser() {
    final user = ref.read(currentUserProvider);
    if (user?.email != null) {
      _emailController.text = user!.email!;
    }
    ref.read(userProfileProvider.future).then((profile) {
      if (!mounted) return;
      if (profile?.phone != null && profile!.phone!.isNotEmpty) {
        _phoneController.text = profile.phone!;
      }
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _goToSignUp() {
    context.go(
      '/auth',
      extra: AuthScreenArgs(initialTab: 1),
    );
  }

  void _goToSignIn() {
    context.go(
      '/auth',
      extra: AuthScreenArgs(
        prefillEmail: _emailController.text.trim(),
        initialTab: 0,
      ),
    );
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
  }

  Future<void> _refreshProfileUntilPaid({int maxAttempts = 10}) async {
    for (var i = 0; i < maxAttempts; i++) {
      ref.invalidate(userProfileProvider);
      final profile = await ref.refresh(userProfileProvider.future);
      if (profile?.hasPaid == true) return;
      if (i < maxAttempts - 1) {
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    }
  }

  Future<void> _handleUnlockResult(UnlockWaitResult result) async {
    if (!mounted) return;

    if (result.confirmed) {
      setState(() {
        _overlayMessage = 'Unlocking your account…';
      });
      await _refreshProfileUntilPaid();
      if (!mounted) return;

      final hasPaid = ref.read(hasPaidProvider);
      if (hasPaid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Full access unlocked!')),
        );
        // Navigate back to the intended destination or home
        if (widget.from != null && widget.from!.isNotEmpty) {
          context.go(widget.from!);
        } else {
          context.go('/home');
        }
        return;
      }

      setState(() {
        _errorMessage =
        'Payment confirmed but your account is still updating. '
            'Tap "Check payment status" to try again.';
      });
      return;
    }

    if (result.paymentCompleted) {
      setState(() {
        _errorMessage =
        'Payment received! We are activating your account. '
            'Tap "Check payment status" in a moment.';
      });
      return;
    }

    setState(() {
      _errorMessage =
      'Payment not confirmed yet. Authorize the M-Pesa prompt on your phone, '
          'then tap "Check payment status" or "Pay again" to retry.';
    });
  }

  Future<void> _waitForPayment({
    required String userId,
    required String email,
    required String phone,
    String? checkoutRequestId,
  }) async {
    setState(() {
      _loading = false;
      _waiting = true;
      _overlayMessage =
      'Waiting for payment confirmation…\n'
          'Authorize the M-Pesa prompt on your phone.';
    });

    final result = await ref.read(paymentRepositoryProvider).waitForUnlock(
      userId,
      email: email,
      phone: phone,
      checkoutRequestId: checkoutRequestId,
    );

    if (!mounted) return;
    await _handleUnlockResult(result);
  }

  Future<void> _checkPaymentStatus() async {
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final user = ref.read(currentUserProvider);

    if (user == null) {
      _goToSignIn();
      return;
    }

    if (email.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email and M-Pesa phone number.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    _clearError();
    setState(() {
      _waiting = true;
      _overlayMessage = 'Checking payment status…';
    });

    try {
      final result = await ref.read(paymentRepositoryProvider).checkUnlockStatus(
        userId: user.id,
        email: email,
        phone: phone,
        checkoutRequestId: _lastCheckoutRequestId,
      );
      if (!mounted) return;
      await _handleUnlockResult(result);
    } catch (e) {
      final message = e is AppException ? e.message : e.toString();
      if (mounted) {
        setState(() {
          _errorMessage = message;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _waiting = false;
          _overlayMessage = null;
        });
      }
    }
  }

  Future<void> _pay() async {
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final user = ref.read(currentUserProvider);

    if (user == null) {
      _goToSignUp();
      return;
    }

    if (email.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email and M-Pesa phone number.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    _clearError();
    setState(() {
      _loading = true;
      _overlayMessage = 'Sending M-Pesa prompt to your phone…';
    });

    try {
      final checkoutRequestId = await ref.read(paymentRepositoryProvider).initiateStkPush(
        email: email,
        phone: phone,
        amount: AppConfig.unlockAmountKes,
        purpose: AppConfig.unlockPurpose,
        userId: user.id,
      );

      _lastCheckoutRequestId = checkoutRequestId;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('STK push sent. Check your phone to authorize.'),
        ),
      );

      await _waitForPayment(
        userId: user.id,
        email: email,
        phone: phone,
        checkoutRequestId: checkoutRequestId,
      );
    } catch (e) {
      final message = e is AppException ? e.message : e.toString();
      if (mounted) {
        setState(() {
          _errorMessage = message;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _waiting = false;
          _overlayMessage = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isLoggedIn = user != null;
    final busy = _loading || _waiting;

    return Scaffold(
      appBar: AppBar(title: const Text('Unlock Full Access')),
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
                              ? 'Pay via M-Pesa to unlock full access (test pricing).'
                              : 'Register first, verify your email, then sign in to pay.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'KSh ${AppConfig.unlockAmountKes}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
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
                            'Register with your details. We will send a confirmation link to your email. '
                                'After verifying, sign in and complete M-Pesa payment to unlock the app.',
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
                                  'Sign in after verifying your email. You will be prompted to pay if you have not unlocked yet.',
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
                            'Step 2: Pay with M-Pesa',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Authorize the payment on your phone to unlock all content.',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            enabled: !busy,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            enabled: !busy,
                            decoration: const InputDecoration(
                              labelText: 'M-Pesa phone',
                              hintText: '2547XXXXXXXX',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(height: 1.4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: busy ? null : _checkPaymentStatus,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Check payment status'),
                            ),
                          ],
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: busy ? null : _pay,
                            icon: const Icon(Icons.phone_android),
                            label: Text(
                              _errorMessage != null
                                  ? 'Pay again'
                                  : 'Pay KSh ${AppConfig.unlockAmountKes}',
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "You'll receive an M-Pesa prompt on your phone to authorize the payment.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (busy)
            ColoredBox(
              color: Colors.black54,
              child: LoadingView(message: _overlayMessage),
            ),
        ],
      ),
    );
  }
}
