import 'package:animate_do/animate_do.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme.dart';
import '../../providers/auth_provider.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _isLoading = false;
  bool _obscurePassword = true;

  bool get _canSubmit =>
      _emailController.text.trim().isNotEmpty && _passwordController.text.isNotEmpty && !_isLoading;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController()..addListener(_onFieldChanged);
    _passwordController = TextEditingController()..addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _emailController.removeListener(_onFieldChanged);
    _passwordController.removeListener(_onFieldChanged);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).signInWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign in failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
    } catch (e) {
      if (!mounted) return;
      final isShaError = e.toString().contains('ApiException: 10') || e.toString().contains('SHA-1/SHA-256');
      final message = isShaError
          ? 'Google Sign-In needs Firebase SHA setup. Tap Help below.'
          : 'Google sign-in failed: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
      if (isShaError) {
        _showGoogleSetupHelp();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showGoogleSetupHelp() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fix Google Sign-In (ApiException: 10)'),
        content: const Text(
          '1) Firebase Console > Project settings > Android app\n'
          '2) Add SHA-1 and SHA-256 fingerprints\n'
          '3) Enable Google provider in Firebase Auth\n'
          '4) Download new google-services.json and replace android/app/google-services.json\n'
          '5) Run: flutter clean, flutter pub get, flutter run',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              FadeInDown(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Back!',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.darkGray,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to continue engaging with Tamil Nadu governance',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.darkGray.withOpacity(0.6),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              FadeInUp(
                child: TextField(
                  controller: _emailController,
                  enabled: !_isLoading,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'your.email@example.com',
                    prefixIcon: const Icon(Icons.email_outlined),
                    prefixIconColor: AppTheme.saffronPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FadeInUp(
                delay: const Duration(milliseconds: 100),
                child: TextField(
                  controller: _passwordController,
                  enabled: !_isLoading,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    prefixIconColor: AppTheme.saffronPrimary,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _canSubmit ? _handleSignIn : null,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Sign In'),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: Divider(color: AppTheme.borderGray)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('Or continue with', style: Theme.of(context).textTheme.bodySmall),
                  ),
                  Expanded(child: Divider(color: AppTheme.borderGray)),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  icon: const Icon(Icons.g_mobiledata_rounded),
                  label: const Text('Sign in with Google'),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _showGoogleSetupHelp,
                  child: const Text('Google Sign-In Help'),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: RichText(
                  text: TextSpan(
                    text: "Don't have an account? ",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.darkGray),
                    children: [
                      TextSpan(
                        text: 'Sign Up',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.saffronPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                        recognizer: TapGestureRecognizer()..onTap = () => context.go('/sign-up'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


