import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../providers/auth_providers.dart';
import '../../providers/repository_providers.dart';

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

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );

    if (widget.prefillEmail != null) {
      _emailController.text = widget.prefillEmail!;
    }
    if (widget.prefillPhone != null) {
      _phoneController.text = widget.prefillPhone!;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _navigateAfterSignIn() async {
    final user = ref.read(currentUserProvider);
    if (user == null || !mounted) return;

    final profile = await ref.read(authRepositoryProvider).getProfile(user.id);
    ref.invalidate(userProfileProvider);

    if (!mounted) return;
    if (profile.hasPaid) {
      context.go('/home');
    } else {
      context.go('/unlock');
    }
  }

  Future<void> _signIn() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      _showMsg('Enter your email and password.', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
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
    final password = _passwordController.text;

    if (email.isEmpty || phone.isEmpty || name.isEmpty || password.isEmpty) {
      _showMsg('Fill in all fields to create your account.', isError: true);
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
        // Email confirmation disabled on project — sign in and continue.
        await auth.signIn(email: email, password: password);
        _showMsg('Account created successfully.');
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
        title: const Text('Check your email'),
        content: Text(
          'We sent a confirmation link to $email.\n\n'
          'Verify your email, then sign in. After signing in you will be prompted to pay '
          'via M-Pesa before accessing the full app.',
        ),
        actions: [
          TextButton(
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

  Future<void> _forgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      _showMsg('Enter your email first to reset password.', isError: true);
      return;
    }
    try {
      await ref.read(authRepositoryProvider).resetPassword(_emailController.text.trim());
      _showMsg('Password reset link sent to your email.');
    } catch (e) {
      _showError(e);
    }
  }

  void _showError(Object e) {
    final message = e is AppException ? e.message : e.toString();
    _showMsg(message, isError: true);
  }

  void _showMsg(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 5 : 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.drive_eta, size: 64, color: Colors.green),
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Welcome to DarasaDrive',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Register, verify your email, sign in, then pay to unlock.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        TabBar(
                          controller: _tabController,
                          labelColor: Colors.green,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: Colors.green,
                          tabs: const [
                            Tab(text: 'Sign in'),
                            Tab(text: 'Sign up'),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 520),
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _SignInForm(
                                emailController: _emailController,
                                passwordController: _passwordController,
                                loading: _loading,
                                onSubmit: _signIn,
                                onForgotPassword: _forgotPassword,
                                onGoToSignUp: () => _tabController.animateTo(1),
                              ),
                              _SignUpForm(
                                nameController: _nameController,
                                emailController: _emailController,
                                phoneController: _phoneController,
                                passwordController: _passwordController,
                                loading: _loading,
                                onSubmit: _signUp,
                                onGoToSignIn: () => _tabController.animateTo(0),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignInForm extends StatelessWidget {
  const _SignInForm({
    required this.emailController,
    required this.passwordController,
    required this.loading,
    required this.onSubmit,
    required this.onForgotPassword,
    required this.onGoToSignUp,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool loading;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;
  final VoidCallback onGoToSignUp;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Sign in after verifying your email. Payment is required if you have not unlocked yet.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: loading ? null : onForgotPassword,
            child: const Text('Forgot password?'),
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: loading ? null : onSubmit,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(loading ? 'Signing in…' : 'Sign in'),
            ),
          ),
        ),
        TextButton(
          onPressed: loading ? null : onGoToSignUp,
          child: const Text("Don't have an account? Create one"),
        ),
      ],
    );
  }
}

class _SignUpForm extends StatelessWidget {
  const _SignUpForm({
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.loading,
    required this.onSubmit,
    required this.onGoToSignIn,
  });

  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final bool loading;
  final VoidCallback onSubmit;
  final VoidCallback onGoToSignIn;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const Text(
            'Create your account first. We will email you a verification link before you can sign in and pay.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Full name',
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'M-Pesa phone',
              hintText: '2547XXXXXXXX',
              prefixIcon: Icon(Icons.phone),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: loading ? null : onSubmit,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(loading ? 'Creating account…' : 'Create account'),
              ),
            ),
          ),
          TextButton(
            onPressed: loading ? null : onGoToSignIn,
            child: const Text('Already have an account? Sign in'),
          ),
        ],
      ),
    );
  }
}
