import 'package:flutter/material.dart';

import '../../../../theme/colors.dart';
import '../../../../theme/spacing.dart';
import '../../../../theme/typography.dart';
import '../../domain/entities/checkout_draft.dart';

/// One step in the left-hand narrative rail. Shared by the rail and the mobile
/// progress strip so the wording can never drift between them.
class JourneyStepRail extends StatelessWidget {
  const JourneyStepRail({
    super.key,
    required this.current,
    required this.furthestStep,
    required this.onJump,
    this.editingFromReview = false,
  });

  final CheckoutStep current;
  final int furthestStep;
  final ValueChanged<CheckoutStep> onJump;

  /// In review, the rail becomes a jump menu: "Edit" beside a section takes the
  /// client straight back to that step.
  final bool editingFromReview;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final step in CheckoutStep.values)
          _RailRow(
            step: step,
            state: _stateFor(step),
            isCurrent: step == current,
            onTap: onJump,
          ),
      ],
    );
  }

  _RailState _stateFor(CheckoutStep step) {
    if (step.position < furthestStep) return _RailState.done;
    if (step == current) return _RailState.current;
    if (step.position == furthestStep + 1) return _RailState.next;
    return _RailState.upcoming;
  }
}

enum _RailState { done, current, next, upcoming }

class _RailRow extends StatelessWidget {
  const _RailRow({
    required this.step,
    required this.state,
    required this.isCurrent,
    required this.onTap,
  });

  final CheckoutStep step;
  final _RailState state;
  final bool isCurrent;
  final ValueChanged<CheckoutStep> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final reachable = state != _RailState.upcoming;

    // Selection is never signalled by colour alone: the marker changes shape and
    // the label becomes bold, and screen readers get an explicit state.
    final marker = switch (state) {
      _RailState.done =>
          Icon(Icons.check_circle, size: 22, color: colors.statusSuccess),
      _RailState.current => Container(
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
              decoration: BoxDecoration(color: colors.borderFocused, shape: BoxShape.circle),
            ),
          ),
        ),
      _RailState.next => Icon(Icons.radio_button_unchecked,
          size: 22, color: colors.textSecondary),
      _RailState.upcoming => Icon(Icons.radio_button_unchecked,
          size: 22, color: colors.textHint),
    };

    return Semantics(
      button: reachable,
      enabled: reachable,
      selected: isCurrent,
      label: '${step.title}. '
          '${state == _RailState.done ? 'Answered' : ''} '
          '${state == _RailState.current ? 'Current step' : ''}',
      child: InkWell(
        onTap: reachable ? () => onTap(step) : null,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              marker,
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: AppTypography.subtitle1.copyWith(
                        color: reachable ? colors.textPrimary : colors.textHint,
                        fontWeight:
                            isCurrent ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(height: 2),
                      Text(
                        step.purpose,
                        style: AppTypography.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
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

/// Compact "2 of 6" progress for mobile, where the rail does not fit.
class JourneyProgressStrip extends StatelessWidget {
  const JourneyProgressStrip({
    super.key,
    required this.current,
    required this.furthestStep,
  });

  final CheckoutStep current;
  final int furthestStep;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              current.title,
              style: AppTypography.subtitle1
                  .copyWith(color: colors.textPrimary, fontWeight: FontWeight.w700),
            ),
            Text(
              'Step ${current.position + 1} of ${CheckoutStep.values.length}',
              style: AppTypography.caption.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // A segmented bar reads faster than a percentage and shows exactly how
        // much is left.
        Row(
          children: [
            for (final step in CheckoutStep.values)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Semantics(
                    label: '${step.title}: '
                        '${step.position <= furthestStep ? 'answered' : 'not started'}',
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: step.position <= furthestStep
                            ? colors.borderFocused
                            : colors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          current.purpose,
          style: AppTypography.caption.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}
