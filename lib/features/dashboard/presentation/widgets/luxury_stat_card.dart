import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';

class LuxuryStatCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;
  final bool isPositiveTrend;

  const LuxuryStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color = AppColors.amber,
    this.trend,
    this.isPositiveTrend = true,
  });

  @override
  State<LuxuryStatCard> createState() => _LuxuryStatCardState();
}

class _LuxuryStatCardState extends State<LuxuryStatCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _pulseAnim = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _pulseController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _pulseController.reverse();
      },
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (context, child) {
          return Transform.scale(scale: _pulseAnim.value, child: child);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered
                  ? widget.color.withValues(alpha: 0.3)
                  : colors.borderSubtle,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isHovered
                      ? widget.color.withValues(alpha: 0.2)
                      : widget.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(widget.icon, color: widget.color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.value,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.title.toUpperCase(),
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (widget.isPositiveTrend
                                ? AppColors.successGreen
                                : colors.statusError)
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.isPositiveTrend
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: widget.isPositiveTrend
                            ? AppColors.successGreen
                            : colors.statusError,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.trend!,
                        style: TextStyle(
                          color: widget.isPositiveTrend
                              ? AppColors.successGreen
                              : colors.statusError,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
