// lib/shared/reusable/ui/micro_animations.dart
import 'package:flutter/material.dart';

/// Tiny fade-only switcher for subtle UI changes.
class MiniFadeSwitcher extends StatelessWidget {
  const MiniFadeSwitcher({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 140),
    this.curve = Curves.easeInOut,
  });

  final Widget child;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: curve,
      switchOutCurve: curve,
      transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
      child: child,
    );
  }
}
