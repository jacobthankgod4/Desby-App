import 'package:flutter/material.dart';
import '../../theme/colors.dart';

/// DesbyCard - Glassmorphic card with brand glow effect
/// Uses Desby brand theme (Dark Navy + Amber)
class DesbyCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool isActive;
  final Color? glowColor;

  const DesbyCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
    this.isActive = false,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: padding,
        decoration: BoxDecoration(
          color: AppColors.surfaceDark.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? (glowColor ?? AppColors.amber).withValues(alpha: 0.5)
                : AppColors.borderDark.withValues(alpha: 0.3),
            width: isActive ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
            if (isActive)
              BoxShadow(
                color: (glowColor ?? AppColors.amber).withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 0,
              ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// DesbyCardSmall - Compact version for lists
class DesbyCardSmall extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isActive;

  const DesbyCardSmall({
    super.key,
    required this.child,
    this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? AppColors.amber.withValues(alpha: 0.5)
                : AppColors.borderDark.withValues(alpha: 0.1),
          ),
        ),
        child: child,
      ),
    );
  }
}
