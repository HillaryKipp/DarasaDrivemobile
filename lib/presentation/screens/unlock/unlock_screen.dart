import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_providers.dart';
import '../../providers/repository_providers.dart';
import '../auth/auth_screen.dart';

/// Payment screen shown after sign-in when the user has not paid yet.
/// Guests are directed to register first via the auth screen.
class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key});

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _loading = false;
  bool _waiting = false;

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

    setState(() => _loading = true);
    try {
      await ref.read(paymentRepositoryProvider).initiateStkPush(
        email: email,
        phone: phone,
        amount: AppConfig.unlockAmountKes,
        purpose: AppConfig.unlockPurpose,
        userId: user.id,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('STK push sent. Check your phone to authorize.'),
        ),
      );

      setState(() {
        _loading = false;
        _waiting = true;
      });

      final unlocked = await ref
          .read(paymentRepositoryProvider)
          .waitForUnlock(user.id);

      if (!mounted) return;

      if (unlocked) {
        ref.invalidate(userProfileProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Full access unlocked!')),
        );
        context.go('/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment not confirmed yet. Check your M-Pesa, then try again.'),
          ),
        );
      }
    } catch (e) {
      final message = e is AppException ? e.message : e.toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _waiting = false;
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
      body: SingleChildScrollView(
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
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: busy ? null : _pay,
                        icon: const Icon(Icons.phone_android),
                        label: Text(
                          _waiting
                              ? 'Waiting for payment…'
                              : _loading
                              ? 'Sending STK push…'
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
    );
  }
}
