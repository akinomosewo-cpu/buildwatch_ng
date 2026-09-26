import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import '../../core/auth/auth_service.dart';
import '../../core/navigation/page_transitions.dart';
import '../../core/theme/app_theme.dart';
import '../pages/home_page.dart';
import 'login_page.dart';

/// Animated brand splash, shown for ~1.2s before routing to either the
/// logged-in home screen or the login screen.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _proceed();
  }

  Future<void> _proceed() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    final loggedIn = AuthService.instance.isLoggedIn;
    pushFadeReplacingStack(
      context,
      loggedIn ? const HomePage() : const LoginPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 32, offset: const Offset(0, 12)),
                ],
              ),
              child: const Icon(Icons.construction_rounded, color: Colors.white, size: 48),
            )
                .animate()
                .scale(
                  duration: 500.ms,
                  curve: Curves.elasticOut,
                  begin: const Offset(0.4, 0.4),
                  end: const Offset(1, 1),
                )
                .fadeIn(duration: 300.ms),
            const Gap(20),
            Text(
              'BuildWatch NG',
              style: AppTextStyles.displaySmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w800),
            ).animate(delay: 250.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
            const Gap(8),
            Text(
              'Watch your build, from anywhere.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ).animate(delay: 450.ms).fadeIn(duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
