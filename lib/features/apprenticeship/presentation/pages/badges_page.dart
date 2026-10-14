import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/skill_badge.dart';
import '../providers/badge_provider.dart';
import '../widgets/badge_lottie_icon.dart';
import '../../../../theme/colors.dart';

class BadgesPage extends ConsumerWidget {
  const BadgesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final badgesAsync = ref.watch(earnedBadgesProvider);

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.workspace_premium_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'BADGES',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your achievements unlocked through learning',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          badgesAsync.when(
            data: (earned) {
              final allBadges = SkillBadge.predefined;
              final earnedIds = earned.map((b) => b.id).toSet();
              final earnedList = allBadges
                  .where((b) => earnedIds.contains(b.id))
                  .toList();
              final lockedList = allBadges
                  .where((b) => !earnedIds.contains(b.id))
                  .toList();

              return SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (earnedList.isNotEmpty) ...[
                      _SectionHeader(
                        label: 'EARNED',
                        count: earnedList.length,
                        color: colors.textMuted,
                      ),
                      const SizedBox(height: 16),
                      ...earnedList.map(
                        (b) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _BadgeCard(badge: b, earned: true),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    _SectionHeader(
                      label: 'LOCKED',
                      count: lockedList.length,
                      color: colors.textMuted,
                    ),
                    const SizedBox(height: 16),
                    ...lockedList.map(
                      (b) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _BadgeCard(badge: b, earned: false),
                      ),
                    ),
                  ]),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Could not load badges: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SectionHeader({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _BadgeCard extends StatefulWidget {
  final SkillBadge badge;
  final bool earned;
  const _BadgeCard({required this.badge, required this.earned});

  @override
  State<_BadgeCard> createState() => _BadgeCardState();
}

class _BadgeCardState extends State<_BadgeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = SkillBadge.tierGradient(widget.badge.tier);
    final glowColor = SkillBadge.tierGlow(widget.badge.tier);

    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: widget.earned
                ? colors.surface
                : (isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : colors.surfaceAlt),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.earned
                  ? glowColor.withValues(alpha: 0.25)
                  : colors.borderDefault.withValues(alpha: 0.5),
              width: widget.earned ? 1.5 : 1,
            ),
            boxShadow: widget.earned
                ? [
                    BoxShadow(
                      color: glowColor.withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: glowColor.withValues(alpha: 0.06),
                      blurRadius: 40,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Badge icon with Lottie animation
                BadgeLottieIcon(
                  badgeId: widget.badge.id,
                  tier: widget.badge.tier,
                  earned: widget.earned,
                  size: 64,
                ),
                const SizedBox(width: 16),
                // Badge info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.badge.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: widget.earned
                                    ? colors.textPrimary
                                    : colors.textHint,
                              ),
                            ),
                          ),
                          if (widget.earned)
                            _ShimmerBadge(
                              shimmerValue: _shimmerController.value,
                              glowColor: glowColor,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.badge.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textMuted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: widget.earned
                              ? LinearGradient(colors: gradient)
                              : null,
                          color: widget.earned
                              ? null
                              : colors.borderDefault.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.badge.tier.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: widget.earned
                                ? colors.textPrimary
                                : colors.textHint,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ShimmerBadge extends StatelessWidget {
  final double shimmerValue;
  final Color glowColor;

  const _ShimmerBadge({required this.shimmerValue, required this.glowColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: glowColor,
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(
              alpha: 0.4 + (sin(shimmerValue * pi * 2) * 0.3),
            ),
            blurRadius: 6 + (sin(shimmerValue * pi * 2) * 3),
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
