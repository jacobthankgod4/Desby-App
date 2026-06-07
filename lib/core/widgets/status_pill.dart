import 'package:flutter/material.dart';
import '../../theme/colors.dart';

/// StatusPill - Animated status badge with Desby glow
/// Uses Desby theme (Dark Navy + Amber + Brand colors)
class StatusPill extends StatefulWidget {
  final String status;
  final bool isLive;
  final bool showIcon;

  const StatusPill({
    super.key,
    required this.status,
    this.isLive = false,
    this.showIcon = true,
  });

  @override
  State<StatusPill> createState() => _StatusPillState();
}

class _StatusPillState extends State<StatusPill>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isLive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(StatusPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLive && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isLive && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Using Desby brand colors
  Color get _statusColor {
    switch (widget.status.toLowerCase()) {
      case 'pending':
      case 'awaiting':
        return AppColors.warning;
      case 'accepted':
      case 'confirmed':
      case 'materials in transit':
        return AppColors.info;
      case 'in progress':
      case 'processing':
        return AppColors.amber;
      case 'ready':
      case 'picked up':
        return AppColors.success;
      case 'delivered':
      case 'completed':
        return AppColors.mediumGray;
      case 'cancelled':
      case 'failed':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }

  IconData get _statusIcon {
    switch (widget.status.toLowerCase()) {
      case 'pending':
        return Icons.schedule_rounded;
      case 'accepted':
        return Icons.check_circle_outline_rounded;
      case 'in progress':
        return Icons.autorenew_rounded;
      case 'materials in transit':
        return Icons.local_shipping_rounded;
      case 'ready':
        return Icons.inventory_2_rounded;
      case 'picked up':
        return Icons.verified_rounded;
      case 'delivered':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _statusColor.withValues(alpha: widget.isLive ? 0.6 : 0.3),
            ),
            boxShadow: widget.isLive
                ? [
                    BoxShadow(
                      color: _statusColor.withValues(alpha: 0.3 * _pulseAnimation.value),
                      blurRadius: 12 * _pulseAnimation.value,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.showIcon) ...[
                Icon(
                  _statusIcon,
                  size: 14,
                  color: _statusColor,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                widget.status.toUpperCase(),
                style: TextStyle(
                  color: _statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              if (widget.isLive) ...[
                const SizedBox(width: 8),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _statusColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _statusColor,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// StatusDot - Simple colored dot with optional pulse
class StatusDot extends StatefulWidget {
  final Color color;
  final bool isPulsing;
  final double size;

  const StatusDot({
    super.key,
    required this.color,
    this.isPulsing = false,
    this.size = 8,
  });

  @override
  State<StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<StatusDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    if (widget.isPulsing) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: widget.isPulsing
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.5 * _controller.value),
                      blurRadius: widget.size * (1 + _controller.value),
                    ),
                  ]
                : null,
          ),
        );
      },
    );
  }
}
