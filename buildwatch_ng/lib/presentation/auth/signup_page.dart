import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import '../../core/auth/auth_service.dart';
import '../../core/auth/user_role.dart';
import '../../core/navigation/page_transitions.dart';
import '../../core/theme/app_theme.dart';
import '../pages/home_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  UserRole _role = UserRole.diasporaOwner;
  bool _obscure = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
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
      await AuthService.instance.signUp(
        name: _nameCtrl.text,
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
        role: _role,
      );
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
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('I am a...', style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary))
                    .animate()
                    .fadeIn(),
                const Gap(12),
                Row(
                  children: [
                    Expanded(
                      child: _RoleCard(
                        icon: Icons.flight_takeoff_rounded,
                        title: 'Diaspora Owner',
                        subtitle: 'I fund & monitor a build remotely',
                        selected: _role == UserRole.diasporaOwner,
                        onTap: () => setState(() => _role = UserRole.diasporaOwner),
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: _RoleCard(
                        icon: Icons.engineering_rounded,
                        title: 'Site Supervisor',
                        subtitle: 'I submit proof of work on-site',
                        selected: _role == UserRole.siteSupervisor,
                        onTap: () => setState(() => _role = UserRole.siteSupervisor),
                      ),
                    ),
                  ],
                ).animate(delay: 50.ms).fadeIn().slideY(begin: 0.1),
                const Gap(28),
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
                  controller: _nameCtrl,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                  decoration: const InputDecoration(hintText: 'Full name', prefixIcon: Icon(Icons.person_outline_rounded)),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.15),
                const Gap(14),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                  decoration: const InputDecoration(hintText: 'Email', prefixIcon: Icon(Icons.mail_outline_rounded)),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.15),
                const Gap(14),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Password (min 6 characters)',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
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
                      : const Text('Create account'),
                ).animate(delay: 250.ms).fadeIn(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 2 : 1.5),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: selected ? AppColors.primary : AppColors.textSecondary, size: 24),
              const Gap(10),
              Text(title, style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary)),
              const Gap(4),
              Text(subtitle, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary)),
            ],
          ),
        ),
      ),
    );
  }
}
