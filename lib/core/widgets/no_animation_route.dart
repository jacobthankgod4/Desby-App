import 'package:flutter/material.dart';

/// A customPageRoute that disables all transitions/animations.
/// Use this for routes that should appear instantly without slide/fade effects.
class NoAnimationRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  NoAnimationRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
        );
}
