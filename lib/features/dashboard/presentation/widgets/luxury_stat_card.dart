import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';
import '../../../../core/widgets/luxury_glass_card.dart';

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
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          return Transform.scale(
            scale: _pulseAnim.value,
            child: child,
          );
        },
        child: LuxuryGlassCard(
          padding: const EdgeInsets.all(16),
          borderColor: _isHovered
              ? widget.color.withValues(alpha: 0.3)
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isHovered
                          ? widget.color.withValues(alpha: 0.2)
                          : widget.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 18),
                  ),
                  if (widget.trend != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (widget.isPositiveTrend
                                ? const Color(0xFF00FF7F)
                                : Colors.redAccent)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.isPositiveTrend
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            color: widget.isPositiveTrend
                                ? const Color(0xFF00FF7F)
                                : Colors.redAccent,
                            size: 10,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            widget.trend!,
                            style: TextStyle(
                              color: widget.isPositiveTrend
                                  ? const Color(0xFF00FF7F)
                                  : Colors.redAccent,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                widget.value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.title.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
