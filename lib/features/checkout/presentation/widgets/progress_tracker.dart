import 'package:desby_app/features/checkout/domain/entities/checkout_draft.dart';
import 'package:desby_app/features/checkout/domain/entities/journey_state.dart';
import 'package:desby_app/features/checkout/presentation/widgets/step_progression_widgets.dart';
import 'package:desby_app/theme/colors.dart';
import 'package:desby_app/theme/spacing.dart';
import 'package:desby_app/theme/typography.dart';
import 'package:flutter/material.dart';

/// The progress tracker.
///
/// Three visually distinct states — locked, current, completed — and it animates
/// between them. The brief asks for reassurance rather than a dashboard, so the
/// percentage is deliberately small and the checkmarks do the talking.
class ProgressTracker extends StatelessWidget {
  const ProgressTracker({
    super.key,
    required this.state,
    required this.draft,
    required this.onJump,
    this.compact = false,
  });

  final JourneyState state;
  final CheckoutDraft draft;
  final ValueChanged<CheckoutStep> onJump;

  /// Mobile variant: horizontal, shorter, less chrome.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final steps = CheckoutStep.values;

    return Semantics(
      container: true,
      // Without explicitChildNodes the rows merge into this node and a screen
      // reader announces one long blob instead of a navigable list of steps.
      explicitChildNodes: true,
      label:
          '${state.counterLabel}. ${state.completedSteps.length} of '
          '${steps.length} steps complete.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!compact) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  state.counterLabel.toUpperCase(),
                  style: AppTypography.overline.copyWith(
                    fontSize: 12,
                    color: colors.borderFocused,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: state.progress),
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => Text(
                    '${(value * 100).round()}%',
                    style: AppTypography.captionSmall.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // The connector line animates as steps complete.
          if (!compact) _progressLine(context),

          for (var i = 0; i < steps.length; i++)
            _TrackerRow(
              step: steps[i],
              stepState: state.stateOf(steps[i]),
              summary: CompletedStepSummary.summaryFor(steps[i], draft),
              isLast: i == steps.length - 1,
              reachable: !state.isLocked(steps[i]),
              compact: compact,
              onTap: () => onJump(steps[i]),
            ),

          if (!compact) const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _progressLine(BuildContext context) {
    final colors = context.colors;
    final total = CheckoutStep.values.length;
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: AppSpacing.md),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return SizedBox(
            height: 2,
            child: Stack(
              children: [
                Container(color: colors.divider),
                TweenAnimationBuilder<double>(
                  tween: Tween(
                    begin: 0,
                    end: state.completedSteps.length / total,
                  ),
                  duration: const Duration(milliseconds: 360),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => Container(
                    width: width * value,
                    color: colors.borderFocused,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TrackerRow extends StatelessWidget {
  const _TrackerRow({
    required this.step,
    required this.stepState,
    required this.summary,
    required this.isLast,
    required this.reachable,
    required this.compact,
    required this.onTap,
  });

  final CheckoutStep step;
  final JourneyStepState stepState;
  final String? summary;
  final bool isLast;
  final bool reachable;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final current = stepState == JourneyStepState.current;
    final completed = stepState == JourneyStepState.completed;
    final locked = stepState == JourneyStepState.locked;

    // Step names must be readable at a glance. They rendered at caption size
    // and in textHint grey, which users reported as unreadable.
    final labelStyle = AppTypography.subtitle2.copyWith(
      fontSize: 15,
      color: locked
          ? colors.textMuted
          : current
          ? colors.textPrimary
          : colors.textSecondary,
      fontWeight: current
          ? FontWeight.w800
          : completed
          ? FontWeight.w700
          : FontWeight.w500,
      letterSpacing: 0.1,
    );

    return Semantics(
      button: reachable,
      enabled: reachable,
      selected: current,
      label: switch (stepState) {
        JourneyStepState.completed =>
          '${step.title}, completed. ${summary ?? 'Nothing specified'}. Activate to edit.',
        JourneyStepState.current => '${step.title}, current step.',
        JourneyStepState.locked => '${step.title}, not yet available.',
      },
      // The tap action is declared here rather than inherited from the InkWell,
      // so each step is one clean node carrying our label, instead of an
      // unlabelled cluster of icon and text nodes a screen reader walks.
      onTap: reachable ? onTap : null,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: reachable ? onTap : null,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          child: Opacity(
            // Locked steps are visibly subordinate, not merely dimmed text.
            opacity: locked ? 0.55 : 1,
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: compact ? AppSpacing.xs : AppSpacing.sm,
                horizontal: AppSpacing.xs,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _marker(context, colors, completed, current, locked),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(step.title, style: labelStyle),
                        if (!compact && completed && summary != null)
                          Text(
                            summary!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.captionSmall.copyWith(
                              color: colors.textMuted,
                            ),
                          ),
                        if (!compact && current)
                          Text(
                            step.purpose,
                            style: AppTypography.captionSmall.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _marker(
    BuildContext context,
    dynamic colors,
    bool completed,
    bool current,
    bool locked,
  ) {
    // The checkmark draws itself in on completion. Subtle, under ~300ms, and it
    // never blocks the client from continuing.
    return SizedBox(
      width: 22,
      height: 22,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: completed
            ? Container(
                key: const ValueKey('done'),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.statusSuccess.withValues(alpha: 0.16),
                ),
                child: Icon(Icons.check, size: 14, color: colors.statusSuccess),
              )
            : current
            ? Container(
                key: const ValueKey('current'),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.borderFocused, width: 2),
                ),
                child: Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors.borderFocused,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              )
            : Container(
                key: const ValueKey('idle'),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.divider),
                ),
              ),
      ),
    );
  }
}
