import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../../widgets/gradient_button.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    // TODO: call your real sign-up API here
    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;
    context.go('/home'); // after signup, go to main app
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text(
                    'Join Livenix',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'Your name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) {
                      final s = (v ?? '').trim();
                      if (s.isEmpty) return 'Enter your email';
                      if (!s.contains('@') || !s.contains('.')) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      hintText: 'Password (min 6 chars)',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(_obscure
                            ? Icons.visibility_off
                            : Icons.visibility),
                      ),
                    ),
                    validator: (v) =>
                    (v == null || v.length < 6) ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: 20),
                  GradientButton(
                    label: _loading ? 'Creating...' : 'Create Account',
                    icon: Icons.person_add_alt_1,
                    onPressed: _loading ? () {} : _submit,
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => context.pop(), // back to Sign In
                    child: const Text('Already have an account? Sign In'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
