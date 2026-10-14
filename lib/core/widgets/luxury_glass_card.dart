import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class LuxuryGlassCard extends StatelessWidget {
  final Widget child;
  final double opacity;
  final double borderRadius;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;

  const LuxuryGlassCard({
    super.key,
    required this.child,
    this.opacity = 0.06,
    this.borderRadius = 24.0,
    this.borderColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? colors.borderDefault,
          width: 1.5,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.surfaceElevated, colors.surface],
        ),
      ),
      child: child,
    );
  }
}
