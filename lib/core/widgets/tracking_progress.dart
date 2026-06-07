import 'package:flutter/material.dart';
import '../../theme/colors.dart';

/// TrackingProgressBar - Shows order progress with animated fill
/// Uses Desby brand theme (Dark Navy + Amber)
class TrackingProgressBar extends StatelessWidget {
  final int currentStep;
  final List<TrackingStep> steps;
  final double height;

  const TrackingProgressBar({
    super.key,
    required this.currentStep,
    required this.steps,
    this.height = 32,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final stepWidth = totalWidth / (steps.length - 1);
          
          return Stack(
            children: [
              // Background track
              Container(
                height: 4,
                margin: EdgeInsets.only(top: height / 2 - 2),
                decoration: BoxDecoration(
                  color: AppColors.borderDark.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Progress fill
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                height: 4,
                margin: EdgeInsets.only(top: height / 2 - 2),
                width: stepWidth * currentStep + (stepWidth / 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.amber.withValues(alpha: 0.8),
                      AppColors.amber,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.amber.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              
              // Step indicators
              ...List.generate(steps.length, (index) {
                final isCompleted = index <= currentStep;
                final isCurrent = index == currentStep;
                
                return Positioned(
                  left: stepWidth * index - 12,
                  top: height / 2 - 12,
                  child: _StepIndicator(
                    step: steps[index],
                    isCompleted: isCompleted,
                    isCurrent: isCurrent,
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _StepIndicator extends StatefulWidget {
  final TrackingStep step;
  final bool isCompleted;
  final bool isCurrent;

  const _StepIndicator({
    required this.step,
    required this.isCompleted,
    required this.isCurrent,
  });

  @override
  State<_StepIndicator> createState() => _StepIndicatorState();
}

class _StepIndicatorState extends State<_StepIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 0, end: -4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.bounceOut),
    );
    if (widget.isCurrent) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _color {
    if (widget.isCompleted) {
      return widget.step.color ?? AppColors.amber;
    }
    return AppColors.borderDark.withValues(alpha: 0.3);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, widget.isCurrent ? _bounceAnimation.value : 0),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: widget.isCompleted ? _color : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: _color,
                width: 2,
              ),
              boxShadow: widget.isCurrent
                  ? [
                      BoxShadow(
                        color: _color.withValues(alpha: 0.5),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: widget.isCompleted
                  ? Icon(
                      widget.isCurrent
                          ? Icons.circle
                          : Icons.check,
                      size: 12,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }
}

/// TrackingStep - Single step in tracking progress
class TrackingStep {
  final String label;
  final String? icon;
  final Color? color;

  const TrackingStep({
    required this.label,
    this.icon,
    this.color,
  });

  // Using Desby brand colors
  static const List<TrackingStep> defaultSteps = [
    TrackingStep(label: 'Pending', color: AppColors.warning),
    TrackingStep(label: 'Accepted', color: AppColors.info),
    TrackingStep(label: 'Processing', color: AppColors.amber),
    TrackingStep(label: 'Ready', color: AppColors.success),
    TrackingStep(label: 'Delivered', color: AppColors.mediumGray),
  ];
}

/// CompactProgressBar - For use in cards
class CompactProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final Color? color;
  final double height;

  const CompactProgressBar({
    super.key,
    required this.progress,
    this.color,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.borderDark.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: Stack(
        children: [
          AnimatedFractionallySizedBox(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (color ?? AppColors.amber).withValues(alpha: 0.7),
                    color ?? AppColors.amber,
                  ],
                ),
                borderRadius: BorderRadius.circular(height / 2),
                boxShadow: [
                  BoxShadow(
                    color: (color ?? AppColors.amber).withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
