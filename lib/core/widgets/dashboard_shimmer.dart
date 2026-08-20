import 'package:flutter/material.dart';

class DashboardShimmer extends StatefulWidget {
  final int statCount;
  final int listCount;

  const DashboardShimmer({
    super.key,
    this.statCount = 4,
    this.listCount = 3,
  });

  @override
  State<DashboardShimmer> createState() => _DashboardShimmerState();
}

class _DashboardShimmerState extends State<DashboardShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
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
        return CustomPaint(
          painter: _ShimmerPainter(progress: _controller.value),
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header shimmer
            _shimmerBlock(10, 140, 6),
            const SizedBox(height: 8),
            _shimmerBlock(10, 220, 24),
            const SizedBox(height: 24),

            // Stats grid shimmer
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: List.generate(
                widget.statCount,
                (_) => _shimmerStatCard(),
              ),
            ),
            const SizedBox(height: 32),

            // Section header shimmer
            _shimmerBlock(10, 120, 10),
            const SizedBox(height: 16),

            // List items shimmer
            ...List.generate(
              widget.listCount,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _shimmerListTile(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBlock(double height, double width, double radius) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _shimmerStatCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        color: Colors.white.withValues(alpha: 0.02),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Container(
                width: 32,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 60,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 80,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerListTile() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        color: Colors.white.withValues(alpha: 0.02),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 80,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  final double progress;
  _ShimmerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(-1.0 + 2.0 * progress, 0),
        end: Alignment(-0.5 + 2.0 * progress, 0),
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.03),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
