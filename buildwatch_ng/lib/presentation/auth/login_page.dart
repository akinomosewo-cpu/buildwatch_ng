import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import '../../core/auth/auth_service.dart';
import '../../core/navigation/page_transitions.dart';
import '../../core/theme/app_theme.dart';
import '../pages/home_page.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await AuthService.instance.login(email: _emailCtrl.text, password: _passwordCtrl.text);
      if (!mounted) return;
      pushFadeReplacingStack(context, const HomePage());
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(18)),
                  child: const Icon(Icons.construction_rounded, color: Colors.white, size: 28),
                ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
                const Gap(24),
                Text('Welcome back', style: AppTextStyles.displaySmall.copyWith(color: AppColors.textPrimary))
                    .animate(delay: 50.ms)
                    .fadeIn()
                    .slideY(begin: 0.1),
                const Gap(6),
                Text(
                  'Log in to keep watching your build.',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ).animate(delay: 100.ms).fadeIn(),
                const Gap(32),
                if (_error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(_error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.danger)),
                  ).animate().fadeIn().shake(hz: 4, offset: const Offset(4, 0)),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                  decoration: const InputDecoration(hintText: 'Email', prefixIcon: Icon(Icons.mail_outline_rounded)),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your email' : null,
                ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.15),
                const Gap(14),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
                  onFieldSubmitted: (_) => _submit(),
                ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.15),
                const Gap(28),
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                        )
                      : const Text('Log In'),
                ).animate(delay: 250.ms).fadeIn(),
                const Gap(16),
                Center(
                  child: TextButton(
                    onPressed: () => pushFade(context, const SignUpPage()),
                    child: Text.rich(
                      TextSpan(
                        text: "Don't have an account? ",
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                        children: [
                          TextSpan(
                            text: 'Sign up',
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate(delay: 300.ms).fadeIn(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
