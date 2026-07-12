import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';

/// Defines the strong-password policy used across the app (sign-up and
/// reset-password). Centralized here so both screens enforce the same rule.
class PasswordPolicy {
  PasswordPolicy._();

  static const int minLength = 8;

  static final RegExp _upper = RegExp(r'[A-Z]');
  static final RegExp _lower = RegExp(r'[a-z]');
  static final RegExp _digit = RegExp(r'\d');
  static final RegExp _special = RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=~`\[\];/\\]');

  static List<PasswordRule> rulesFor(String password) => [
    PasswordRule(
      label: 'At least $minLength characters',
      isMet: password.length >= minLength,
    ),
    PasswordRule(
      label: 'One uppercase letter (A-Z)',
      isMet: _upper.hasMatch(password),
    ),
    PasswordRule(
      label: 'One lowercase letter (a-z)',
      isMet: _lower.hasMatch(password),
    ),
    PasswordRule(
      label: 'One number (0-9)',
      isMet: _digit.hasMatch(password),
    ),
    PasswordRule(
      label: 'One special character (!@#\$%...)',
      isMet: _special.hasMatch(password),
    ),
  ];

  static bool isStrong(String password) =>
      rulesFor(password).every((r) => r.isMet);
}

class PasswordRule {
  const PasswordRule({required this.label, required this.isMet});
  final String label;
  final bool isMet;
}

/// Live checklist widget — shows each policy rule with a check/cross icon
/// that updates as the user types.
class PasswordStrengthChecklist extends StatelessWidget {
  const PasswordStrengthChecklist({super.key, required this.password});
  final String password;

  @override
  Widget build(BuildContext context) {
    final rules = PasswordPolicy.rulesFor(password);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rules.map((rule) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Icon(
                  rule.isMet ? Icons.check_circle : Icons.circle_outlined,
                  size: 16,
                  color: rule.isMet ? const Color(0xFF065F2F) : const Color(0xFFCBD5E1),
                ),
                const SizedBox(width: 8),
                Text(
                  rule.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: rule.isMet ? const Color(0xFF065F2F) : AppColors.textMuted,
                    fontWeight: rule.isMet ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String _password = '';

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      setState(() => _password = _passwordController.text);
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (!PasswordPolicy.isStrong(password)) {
      _showMsg('Please meet all password requirements below.', isError: true);
      return;
    }

    if (password != confirm) {
      _showMsg('Passwords do not match.', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );
      if (!mounted) return;
      _showMsg('Password updated successfully!');
      context.go('/auth');
    } on AuthException catch (e) {
      _showMsg(e.message, isError: true);
    } catch (e) {
      _showMsg('Failed to update password. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMsg(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isStrong = PasswordPolicy.isStrong(_password);
    final passwordsMatch = _confirmPasswordController.text.isEmpty ||
        _confirmPasswordController.text == _password;

    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Create a new password',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter a strong password to secure your account.',
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 12),
            PasswordStrengthChecklist(password: _password),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscurePassword,
              autofillHints: const [AutofillHints.newPassword],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_outline),
                errorText: passwordsMatch ? null : 'Passwords do not match',
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: (_loading || !isStrong || !passwordsMatch) ? null : _updatePassword,
              child: _loading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Text('Update Password'),
            ),
          ],
        ),
      ),
    );
  }
}