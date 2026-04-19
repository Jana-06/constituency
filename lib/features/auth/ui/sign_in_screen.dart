import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_snackbar.dart';
import '../providers/auth_providers.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (previous, next) {
      next.whenOrNull(error: (error, _) => showErrorSnackBar(context, error.toString()));
    });

    final loading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Welcome back', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) => (value == null || value.isEmpty) ? 'Enter email' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) => (value == null || value.length < 6) ? 'Min 6 chars' : null,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: loading
                      ? null
                      : () async {
                          if (!(_formKey.currentState?.validate() ?? false)) {
                            return;
                          }
                          await ref.read(authControllerProvider.notifier).signIn(
                                _emailController.text.trim(),
                                _passwordController.text,
                              );
                        },
                  child: const Text('Sign in'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: loading
                      ? null
                      : () => ref.read(authControllerProvider.notifier).signInWithGoogle(),
                  icon: const Icon(Icons.g_mobiledata_rounded),
                  label: const Text('Continue with Google'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.push('/signup'),
            child: const Text("Don't have an account? Sign up"),
          ),
        ],
      ),
    );
  }
}

