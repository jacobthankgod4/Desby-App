import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class LuxuryGlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;

  const LuxuryGlassCard({
    super.key,
    required this.child,
    this.blur = 20.0,
    this.opacity = 0.05,
    this.borderRadius = 24.0,
    this.borderColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? Colors.white.withValues(alpha: 0.1),
              width: 1.5,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: opacity + 0.05),
                Colors.white.withValues(alpha: opacity),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
