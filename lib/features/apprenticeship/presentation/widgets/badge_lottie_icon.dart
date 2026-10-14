import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../domain/entities/skill_badge.dart';

class BadgeLottieIcon extends StatelessWidget {
  final String badgeId;
  final String tier;
  final bool earned;
  final double size;

  const BadgeLottieIcon({
    super.key,
    required this.badgeId,
    required this.tier,
    this.earned = true,
    this.size = 64,
  });

  String get _assetPath {
    switch (tier) {
      case 'gold':
        return 'assets/lottie/badge_gold_glow.json';
      case 'silver':
        return 'assets/lottie/badge_silver_shine.json';
      case 'bronze':
      default:
        return 'assets/lottie/badge_bronze_pulse.json';
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = SkillBadge.tierGradient(tier);
    final glowColor = SkillBadge.tierGlow(tier);

    if (!earned) {
      return _buildLocked(glowColor);
    }

    return _buildEarned(glowColor, gradient);
  }

  Widget _buildLocked(Color glowColor) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: glowColor.withValues(alpha: 0.08),
      ),
      child: Opacity(
        opacity: 0.3,
        child: Lottie.asset(
          _assetPath,
          width: size,
          height: size,
          repeat: false,
          errorBuilder: (_, _, _) => Icon(
            SkillBadge.getIcon(badgeId),
            color: glowColor.withValues(alpha: 0.4),
            size: size * 0.44,
          ),
        ),
      ),
    );
  }

  Widget _buildEarned(Color glowColor, List<Color> gradient) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: gradient.map((c) => c.withValues(alpha: 0.15)).toList(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.25),
            blurRadius: 16,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: glowColor.withValues(alpha: 0.10),
            blurRadius: 32,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: Lottie.asset(
          _assetPath,
          width: size,
          height: size,
          repeat: true,
          errorBuilder: (_, _, _) => Icon(
            SkillBadge.getIcon(badgeId),
            color: glowColor,
            size: size * 0.44,
          ),
        ),
      ),
    );
  }
}
