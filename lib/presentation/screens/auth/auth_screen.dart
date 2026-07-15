import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_providers.dart';
import '../../providers/repository_providers.dart';
import 'reset_password_screen.dart' show PasswordPolicy, PasswordStrengthChecklist;

const _kRememberedEmailKey = 'remembered_email';

class AuthScreenArgs {
  const AuthScreenArgs({
    this.prefillEmail,
    this.prefillPhone,
    this.initialTab = 0,
  });

  final String? prefillEmail;
  final String? prefillPhone;
  final int initialTab;
}



class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({
    super.key,
    this.initialTab = 0,
    this.prefillEmail,
    this.prefillPhone,
  });

  final int initialTab;
  final String? prefillEmail;
  final String? prefillPhone;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _signUpPasswordController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _rememberMe = true;
  String _signUpPassword = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    // Rebuild when tab changes so the form swaps
    _tabController.addListener(() => setState(() {}));

    _signUpPasswordController.addListener(() {
      setState(() => _signUpPassword = _signUpPasswordController.text);
    });

    if (widget.prefillEmail != null) {
      _emailController.text = widget.prefillEmail!;
    } else {
      _loadRememberedEmail();
    }

    // Pre-fill 254 prefix for phone
    _phoneController.text = widget.prefillPhone ?? '254';
    _phoneController.addListener(_handlePhonePrefix);
  }

  Future<void> _loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kRememberedEmailKey);
    if (saved != null && mounted) {
      setState(() => _emailController.text = saved);
    }
  }

  Future<void> _persistRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString(_kRememberedEmailKey, _emailController.text.trim());
    } else {
      await prefs.remove(_kRememberedEmailKey);
    }
  }

  void _handlePhonePrefix() {
    if (!_phoneController.text.startsWith('254')) {
      _phoneController.text = '254';
      _phoneController.selection = TextSelection.fromPosition(
        TextPosition(offset: _phoneController.text.length),
      );
    }
  }

  @override
  void dispose() {
    _phoneController.removeListener(_handlePhonePrefix);
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _signUpPasswordController.dispose();
    super.dispose();
  }

  // ── Navigation ──────────────────────────────────────────────────────────────

  Future<void> _navigateAfterSignIn() async {
    final user = ref.read(currentUserProvider);
    if (user == null || !mounted) return;
    ref.invalidate(userProfileProvider);
    if (!mounted) return;

    // Restoration: Go to home after sign-in.
    // Premium items will trigger the unlock screen on-demand.
    context.go('/home');
  }

  // ── Auth actions ────────────────────────────────────────────────────────────

  Future<void> _signIn() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      _showMsg('Please enter your email and password.', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await _persistRememberedEmail();
      // Signal the platform autofill service (Google/Play Services Password
      // Manager or iOS Keychain) that the credential entry is complete, so
      // it can prompt the user to save it.
      TextInput.finishAutofillContext();
      await _navigateAfterSignIn();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final name = _nameController.text.trim();
    final password = _signUpPasswordController.text;

    if (email.isEmpty || phone.isEmpty || name.isEmpty || password.isEmpty) {
      _showMsg('Please fill in all fields to create your account.', isError: true);
      return;
    }

    // Validate phone number format (2547XXXXXXXX or 2541XXXXXXXX)
    if (!RegExp(r'^254[17]\d{8}$').hasMatch(phone)) {
      _showMsg('Enter a valid M-Pesa number starting with 2547... or 2541...', isError: true);
      return;
    }

    if (!PasswordPolicy.isStrong(password)) {
      _showMsg('Please meet all password requirements shown below.', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      final auth = ref.read(authRepositoryProvider);
      final requiresConfirmation = await auth.signUp(
        email: email,
        password: password,
        fullName: name,
        phone: phone,
      );
      if (!mounted) return;
      if (requiresConfirmation) {
        _showEmailVerificationDialog(email);
      } else {
        await auth.signIn(email: email, password: password);
        TextInput.finishAutofillContext();
        _showMsg('Account created successfully!');
        await _navigateAfterSignIn();
      }
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showEmailVerificationDialog(String email) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.mark_email_read_outlined, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Check your email',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        content: Text(
          'We sent a confirmation link to:\n$email\n\n'
              'Tap the link to verify your account, then come back to sign in. '
              'After signing in you will be guided to pay via Google Play.',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _passwordController.clear();
              _tabController.animateTo(0);
            },
            child: const Text('Go to Sign in'),
          ),
        ],
      ),
    );
  }

  void _forgotPassword() {
    showDialog<void>(
      context: context,
      builder: (ctx) => _ForgotPasswordDialog(
        initialEmail: _emailController.text.trim(),
        onSend: (email) => ref.read(authRepositoryProvider).resetPassword(email),
      ),
    );
  }

  void _showError(Object e) {
    final message = getErrorMessage(e);
    _showMsg(message, isError: true);
  }

  void _showMsg(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: isError ? 5 : 3),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _tabController.index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _tabController.index == 1) {
          _tabController.animateTo(0);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAF9),
        appBar: context.canPop()
            ? AppBar(
          backgroundColor: const Color(0xFF065F2F),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.chevron_left,
                color: Colors.white, size: 28),
            onPressed: () {
              if (_tabController.index == 1) {
                _tabController.animateTo(0);
              } else {
                context.pop();
              }
            },
          ),
        )
            : null,
        body: Column(
          children: [
            // ── Green hero header ──────────────────────────────────────
            _AuthHero(showTopPadding: !context.canPop()),

            // ── Tab + forms ────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    _TabSelector(
                      controller: _tabController,
                      onChanged: (i) => setState(() {}),
                    ),
                    const SizedBox(height: 24),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: _tabController.index == 0
                          ? _SignInForm(
                        key: const ValueKey('signin'),
                        emailController: _emailController,
                        passwordController: _passwordController,
                        obscurePassword: _obscurePassword,
                        onToggleObscure: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                        loading: _loading,
                        rememberMe: _rememberMe,
                        onRememberMeChanged: (v) =>
                            setState(() => _rememberMe = v),
                        onSubmit: _signIn,
                        onForgotPassword: _forgotPassword,
                        onGoToSignUp: () =>
                            _tabController.animateTo(1),
                      )
                          : _SignUpForm(
                        key: const ValueKey('signup'),
                        nameController: _nameController,
                        emailController: _emailController,
                        phoneController: _phoneController,
                        passwordController: _signUpPasswordController,
                        password: _signUpPassword,
                        obscurePassword: _obscurePassword,
                        onToggleObscure: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                        loading: _loading,
                        onSubmit: _signUp,
                        onGoToSignIn: () =>
                            _tabController.animateTo(0),
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

// ── Hero Header ───────────────────────────────────────────────────────────────

class _AuthHero extends StatelessWidget {
  const _AuthHero({required this.showTopPadding});
  final bool showTopPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF065F2F),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        top: showTopPadding,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.directions_car_outlined,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'DarasaDrive',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Kenya\'s driving test prep App',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const _StepPill(icon: Icons.person_add_outlined, label: 'Sign in/Register'),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepPill extends StatelessWidget {
  const _StepPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF4ADE80), size: 13),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Tab Selector ──────────────────────────────────────────────────────────────

class _TabSelector extends StatelessWidget {
  const _TabSelector({required this.controller, required this.onChanged});
  final TabController controller;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final isSignIn = controller.index == 0;
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE9F0EC),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              _TabPill(
                label: 'Sign in',
                active: isSignIn,
                onTap: () {
                  controller.animateTo(0);
                  onChanged(0);
                },
              ),
              _TabPill(
                label: 'Create account',
                active: !isSignIn,
                onTap: () {
                  controller.animateTo(1);
                  onChanged(1);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill(
      {required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: active
                ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: active ? const Color(0xFF065F2F) : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Forgot Password Dialog ────────────────────────────────────────────────────

/// Focused, email-only dialog for the "forgot password" action.
/// Deliberately does NOT show anywhere near a password field — the sign-in
/// password field belongs to a different action and showing it here was
/// confusing users about what they were being asked to do.
class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog({required this.initialEmail, required this.onSend});
  final String initialEmail;
  final Future<void> Function(String email) onSend;

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  late final TextEditingController _emailController =
  TextEditingController(text: widget.initialEmail);
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.onSend(email);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password reset link sent — check your inbox.'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      final message = e is AppException ? e.message : 'Failed to send reset link.';
      if (mounted) setState(() => _error = message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.lock_reset_outlined, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Reset your password',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Enter your account email and we'll send you a link to set a new password.",
            style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            onSubmitted: (_) => _submit(),
            decoration: _fieldDecor(
              label: 'Email address',
              hint: 'you@email.com',
              icon: Icons.email_outlined,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
              : const Text('Send link'),
        ),
      ],
    );
  }
}

// ── Shared field decoration ───────────────────────────────────────────────────

InputDecoration _fieldDecor({
  required String label,
  required String hint,
  required IconData icon,
  Widget? suffix,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
    prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
    suffixIcon: suffix,
    filled: true,
    fillColor: Colors.white,
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
  );
}

Widget _primaryButton({
  required String label,
  required bool loading,
  required VoidCallback onPressed,
}) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(
            strokeWidth: 2, color: Colors.white),
      )
          : Text(label,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600)),
    ),
  );
}

// ── Sign-In Form ──────────────────────────────────────────────────────────────

class _SignInForm extends StatelessWidget {
  const _SignInForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.loading,
    required this.rememberMe,
    required this.onRememberMeChanged,
    required this.onSubmit,
    required this.onForgotPassword,
    required this.onGoToSignUp,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final bool loading;
  final bool rememberMe;
  final ValueChanged<bool> onRememberMeChanged;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;
  final VoidCallback onGoToSignUp;

  @override
  Widget build(BuildContext context) {
    // AutofillGroup lets the OS (Google Password Manager / iOS Keychain)
    // recognize this as a login form and offer to save the credentials
    // after a successful sign-in, and to suggest saved ones on future visits.
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _InfoChip(
            icon: Icons.info_outline,
            text: 'Sign in after verifying your email.',
          ),
          const SizedBox(height: 20),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            decoration: _fieldDecor(
                label: 'Email address', hint: 'you@email.com', icon: Icons.email_outlined),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: passwordController,
            obscureText: obscurePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => onSubmit(),
            decoration: _fieldDecor(
              label: 'Password',
              hint: '••••••••',
              icon: Icons.lock_outline,
              suffix: IconButton(
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                onPressed: onToggleObscure,
              ),
            ),
          ),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: rememberMe,
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                      onChanged: (v) => onRememberMeChanged(v ?? true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => onRememberMeChanged(!rememberMe),
                    child: const Text(
                      '',
                      style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: loading ? null : onForgotPassword,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('                 Forgot password?',
                    style:
                    TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _primaryButton(
              label: 'Sign in', loading: loading, onPressed: onSubmit),
          const SizedBox(height: 16),
          const _OrDivider(),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: loading ? null : onGoToSignUp,
              child: RichText(
                text: const TextSpan(
                  text: "Don't have an account? ",
                  style:
                  TextStyle(color: AppColors.textMuted, fontSize: 13),
                  children: [
                    TextSpan(
                      text: 'Create one',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sign-Up Form ──────────────────────────────────────────────────────────────

class _SignUpForm extends StatelessWidget {
  const _SignUpForm({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.password,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.loading,
    required this.onSubmit,
    required this.onGoToSignIn,
  });

  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final String password;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final bool loading;
  final VoidCallback onSubmit;
  final VoidCallback onGoToSignIn;

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _InfoChip(
            icon: Icons.verified_user_outlined,
            text: 'Register.',
          ),
          const SizedBox(height: 20),
          TextField(
            controller: nameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            decoration: _fieldDecor(
                label: 'Full name',
                hint: 'Jane Mwangi',
                icon: Icons.person_outline),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            decoration: _fieldDecor(
                label: 'Email address',
                hint: 'you@email.com',
                icon: Icons.email_outlined),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.telephoneNumber],
            decoration: _fieldDecor(
                label: 'Your phone number',
                hint: '2547XXXXXXXX',
                icon: Icons.phone_outlined),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 4, top: 4),
            child: Text(
              'Format: 2547XXXXXXXX',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: passwordController,
            obscureText: obscurePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            onSubmitted: (_) => onSubmit(),
            decoration: _fieldDecor(
              label: 'Password',
              hint: 'At least 8 characters',
              icon: Icons.lock_outline,
              suffix: IconButton(
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                onPressed: onToggleObscure,
              ),
            ),
          ),
          const SizedBox(height: 12),
          PasswordStrengthChecklist(password: password),
          const SizedBox(height: 20),
          _primaryButton(
              label: 'Create account',
              loading: loading,
              onPressed: onSubmit),
          const SizedBox(height: 16),
          const _OrDivider(),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: loading ? null : onGoToSignIn,
              child: RichText(
                text: const TextSpan(
                  text: 'Already have an account? ',
                  style:
                  TextStyle(color: AppColors.textMuted, fontSize: 13),
                  children: [
                    TextSpan(
                      text: 'Sign in',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAFFF3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  color: Color(0xFF065F2F), fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('or',
              style: TextStyle(
                  color: AppColors.textMuted, fontSize: 12)),
        ),
        const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
      ],
    );
  }
}