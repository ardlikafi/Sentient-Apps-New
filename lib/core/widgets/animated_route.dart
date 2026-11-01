import 'package:flutter/material.dart';

class FadeRoute extends PageRouteBuilder {
  final Widget page;
  FadeRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      );
}

class SlideRightRoute extends PageRouteBuilder {
  final Widget page;
  SlideRightRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          final tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: Curves.ease));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      );
}

class FadeScaleRoute extends PageRouteBuilder {
  final Widget page;
  FadeScaleRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      );
}
