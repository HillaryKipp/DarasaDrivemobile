import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_providers.dart';
import '../../providers/repository_providers.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user?.email != null) {
        _emailController.text = user!.email!;
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    setState(() => _loading = true);
    try {
      final user = ref.read(currentUserProvider);
      await ref.read(paymentRepositoryProvider).initiateStkPush(
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            amount: AppConfig.unlockAmountKes,
            purpose: AppConfig.unlockPurpose,
            userId: user?.id,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('STK push sent. Check your phone to authorize.'),
        ),
      );

      if (user != null) {
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
              content: Text('Payment not confirmed yet. Check your M-Pesa.'),
            ),
          );
        }
      } else {
        context.go('/auth');
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
                child: const Column(
                  children: [
                    Text(
                      'Unlock Full Access',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'One-time payment via M-Pesa',
                      style: TextStyle(color: Colors.white70),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'KSh ${AppConfig.unlockAmountKes}',
                      style: TextStyle(
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
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'M-Pesa phone',
                        hintText: '2547XXXXXXXX',
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: (_loading || _waiting) ? null : _pay,
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
                      "You'll receive an M-Pesa prompt on your phone.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
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
