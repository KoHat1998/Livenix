import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../../widgets/gradient_button.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    // TODO: call your real auth API here
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    context.go('/home'); // go to main app (Start Live / View Lives)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
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
                    'Welcome back',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 18),
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
                      hintText: 'Password',
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
                    label: _loading ? 'Signing in...' : 'Sign In',
                    icon: Icons.login,
                    onPressed: _loading ? () {} : _submit,
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => context.push('/auth/signup'),
                    child: const Text('Create an account'),
                  ),
                  TextButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Continue as Guest'),
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
