import 'package:flutter/material.dart';

/// Consistent, short, non-blocking transitions used across the app's major
/// routes (auth flow, home, feature pages).
class FadeThroughRoute<T> extends PageRouteBuilder<T> {
  FadeThroughRoute({required WidgetBuilder builder, super.settings})
      : super(
          transitionDuration: const Duration(milliseconds: 260),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          pageBuilder: (context, animation, secondaryAnimation) => builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
            final slide = Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
                .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
            return FadeTransition(
              opacity: fade,
              child: SlideTransition(position: slide, child: child),
            );
          },
        );
}

/// Pushes [page] using [FadeThroughRoute].
Future<T?> pushFade<T>(BuildContext context, Widget page) {
  return Navigator.of(context).push<T>(FadeThroughRoute<T>(builder: (_) => page));
}

/// Replaces the whole stack with [page] using a fade — used for auth
/// transitions (splash -> auth check -> login/home) where going "back"
/// should not be possible.
Future<T?> pushFadeReplacingStack<T>(BuildContext context, Widget page) {
  return Navigator.of(context).pushAndRemoveUntil<T>(
    FadeThroughRoute<T>(builder: (_) => page),
    (route) => false,
  );
}
