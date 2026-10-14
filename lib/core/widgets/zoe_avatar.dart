import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated Zoe AI avatar — orange-to-pink gradient chat bubble with three dots.
class ZoeAvatar extends StatefulWidget {
  final double size;
  final bool isThinking;
  final bool showGlow;

  const ZoeAvatar({
    super.key,
    this.size = 88,
    this.isThinking = false,
    this.showGlow = true,
  });

  @override
  State<ZoeAvatar> createState() => _ZoeAvatarState();
}

class _ZoeAvatarState extends State<ZoeAvatar> with TickerProviderStateMixin {
  late AnimationController _breatheController;
  late AnimationController _thinkController;
  late Animation<double> _breatheAnim;
  late Animation<double> _thinkAnim;

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _breatheAnim = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );

    _thinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _thinkAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _thinkController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(ZoeAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isThinking && !oldWidget.isThinking) {
      _thinkController.repeat(reverse: true);
    } else if (!widget.isThinking && oldWidget.isThinking) {
      _thinkController.reverse();
    }
  }

  @override
  void dispose() {
    _breatheController.dispose();
    _thinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_breatheAnim, _thinkAnim]),
      builder: (context, child) {
        final glowIntensity = widget.isThinking
            ? 0.3 + (0.3 * _thinkAnim.value)
            : 0.15 + (0.1 * _breatheAnim.value);

        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.size * 0.3),
            boxShadow: [
              if (widget.showGlow) ...[
                BoxShadow(
                  color: const Color(
                    0xFFFF6B35,
                  ).withValues(alpha: glowIntensity),
                  blurRadius: widget.size * 0.4,
                  spreadRadius: widget.size * 0.05,
                ),
                BoxShadow(
                  color: const Color(
                    0xFFD63384,
                  ).withValues(alpha: glowIntensity * 0.5),
                  blurRadius: widget.size * 0.8,
                  spreadRadius: widget.size * 0.1,
                ),
              ],
            ],
          ),
          child: Transform.scale(
            scale: widget.isThinking
                ? 1.0 + (0.03 * _thinkAnim.value)
                : _breatheAnim.value,
            child: _ChatBubbleIcon(
              size: widget.size,
              isThinking: widget.isThinking,
            ),
          ),
        );
      },
    );
  }
}

/// Small inline Zoe avatar for chat bubbles.
class ZoeAvatarSmall extends StatefulWidget {
  final double size;

  const ZoeAvatarSmall({super.key, this.size = 32});

  @override
  State<ZoeAvatarSmall> createState() => _ZoeAvatarSmallState();
}

class _ZoeAvatarSmallState extends State<ZoeAvatarSmall>
    with SingleTickerProviderStateMixin {
  late AnimationController _dotController;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dotController,
      builder: (context, child) {
        return _ChatBubbleIcon(
          size: widget.size,
          dotAnimValue: _dotController.value,
        );
      },
    );
  }
}

/// The actual chat bubble icon — orange-to-pink gradient with three dots.
class _ChatBubbleIcon extends StatelessWidget {
  final double size;
  final bool isThinking;
  final double dotAnimValue;

  const _ChatBubbleIcon({
    required this.size,
    this.isThinking = false,
    this.dotAnimValue = 0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ChatBubblePainter(
        isThinking: isThinking,
        dotAnimValue: dotAnimValue,
      ),
    );
  }
}

/// Custom painter — rounded speech bubble with tail and three animated dots.
class _ChatBubblePainter extends CustomPainter {
  final bool isThinking;
  final double dotAnimValue;

  _ChatBubblePainter({required this.isThinking, required this.dotAnimValue});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = w * 0.22; // corner radius

    // --- Bubble body ---
    final bubbleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h * 0.82),
      Radius.circular(r),
    );

    final bubblePath = Path()
      ..addRRect(bubbleRect)
      // tail at bottom-left
      ..moveTo(w * 0.18, h * 0.82)
      ..lineTo(w * 0.08, h * 0.98)
      ..lineTo(w * 0.32, h * 0.82)
      ..close();

    // Gradient: orange (bottom-left) → pink/magenta (top-right)
    final gradientPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFF6B35), // orange
          Color(0xFFFF8C42), // warm orange
          Color(0xFFE8477F), // pink
          Color(0xFFD63384), // magenta
        ],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(bubblePath, gradientPaint);

    // --- Three dots ---
    final dotY = h * 0.41;
    final dotSpacing = w * 0.22;
    final dotCenterX = w * 0.5;
    final dotRadius = w * 0.06;

    final dotBasePaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 3; i++) {
      final dx = dotCenterX + (i - 1) * dotSpacing;

      // Animate: dots bounce slightly when thinking
      double dy = dotY;
      double scale = 1.0;
      if (isThinking) {
        final phase = (dotAnimValue * 2 * math.pi) + (i * 0.8);
        dy = dotY + math.sin(phase) * (h * 0.025);
        scale = 1.0 + math.sin(phase) * 0.15;
      }

      // Dot gradient color (orange → pink from left to right)
      final t = i / 2.0;
      final dotColor = Color.lerp(
        const Color(0xFFFF6B35),
        const Color(0xFFD63384),
        t,
      )!;

      dotBasePaint.color = dotColor;
      canvas.drawCircle(Offset(dx, dy), dotRadius * scale, dotBasePaint);
    }
  }

  @override
  bool shouldRepaint(_ChatBubblePainter oldDelegate) =>
      oldDelegate.isThinking != isThinking ||
      oldDelegate.dotAnimValue != dotAnimValue;
}
