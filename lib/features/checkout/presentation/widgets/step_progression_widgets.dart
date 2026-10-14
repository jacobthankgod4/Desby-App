import 'package:desby_app/features/checkout/domain/entities/checkout_draft.dart';
import 'package:desby_app/features/checkout/domain/entities/journey_state.dart';
import 'package:desby_app/theme/colors.dart';
import 'package:desby_app/theme/spacing.dart';
import 'package:desby_app/theme/typography.dart';
import 'package:flutter/material.dart';

/// A completed step, collapsed to a single line.
///
/// The point is contrast with the active step: this occupies a fraction of the
/// vertical space, so the client can read their own progress at a glance
/// without the page becoming a stack of equal-weight cards.
class CompletedStepSummary extends StatelessWidget {
  const CompletedStepSummary({
    super.key,
    required this.step,
    required this.draft,
    required this.onEdit,
  });

  final CheckoutStep step;
  final CheckoutDraft draft;
  final VoidCallback onEdit;

  /// A one-line answer for this step, or null when nothing was chosen.
  static String? summaryFor(CheckoutStep step, CheckoutDraft draft) {
    switch (step) {
      case CheckoutStep.defineRequest:
        final parts = <String>[];
        final garment = draft.request.garmentType;
        if (garment != null && garment.isNotEmpty) parts.add(garment);
        else if (draft.product?.title != null) parts.add(draft.product!.title!);
        if (draft.occasions.isNotEmpty) parts.add(draft.occasions.join(' · '));
        final text = draft.request.summary?.trim() ?? '';
        if (text.isNotEmpty) {
          parts.add(text.length > 64 ? '${text.substring(0, 62)}…' : text);
        }
        return parts.isEmpty ? null : parts.join(' · ');
      case CheckoutStep.styleDirection:
        final parts = <String>[];
        if (draft.style.tags.isNotEmpty) parts.add(draft.style.tags.join(', '));
        if (draft.style.fitPreference != null) {
          parts.add('${draft.style.fitPreference} fit');
        }
        return parts.isEmpty ? null : parts.join(' · ');
      case CheckoutStep.fabric:
        final parts = <String>[];
        if (draft.fabric.name != null) parts.add(draft.fabric.name!);
        if (draft.fabric.colour != null) parts.add(draft.fabric.colour!);
        return parts.isEmpty ? null : parts.join(' · ');
      case CheckoutStep.occasion:
        return draft.occasions.isEmpty ? null : draft.occasions.join(', ');
      case CheckoutStep.measurements:
        if (!draft.measurements.hasData) return 'To be taken at fitting';
        return '${draft.measurements.fieldCount} measurements';
      case CheckoutStep.review:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final summary = summaryFor(step, draft);

    return Semantics(
      container: true,
      label: '${step.title}, completed. '
          '${summary ?? 'Nothing specified — your tailor will ask.'}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(AppSpacing.md),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: colors.cardBg,
              borderRadius: BorderRadius.circular(AppSpacing.md),
              border: Border.all(color: colors.cardBorder),
            ),
            child: Row(
              children: [
                // Checkmark, not just a colour change.
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.statusSuccess.withValues(alpha: 0.15),
                  ),
                  child: Icon(Icons.check, size: 14, color: colors.statusSuccess),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title.toUpperCase(),
                        style: AppTypography.overline.copyWith(
                          fontSize: 12,
                          color: colors.borderFocused,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        summary ?? 'Nothing specified — your tailor will ask.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body3.copyWith(
                          fontSize: 14,
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Edit',
                  style: AppTypography.caption.copyWith(
                    color: colors.borderFocused,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: colors.iconMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The active step, in a treatment strong enough to dominate the page.
class ActiveStepHeader extends StatelessWidget {
  /// The left rail already states the step and the percentage on wide layouts.
  /// Repeating it made the same two numbers appear twice on one screen.
  final bool showCounter;

  const ActiveStepHeader({
    this.showCounter = true,
    super.key,
    required this.state,
    required this.title,
    required this.purpose,
    this.warning,
  });

  final JourneyState state;
  final String title;
  final String purpose;

  /// Shown when editing this step would affect later answers.
  final String? warning;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showCounter)
          Row(
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
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                '${state.completedSteps.length} of '
                '${CheckoutStep.values.length} complete',
                style: AppTypography.overline.copyWith(
                  fontSize: 12,
                  color: colors.textMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          title,
          style: AppTypography.headline2.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          purpose,
          style: AppTypography.body2.copyWith(color: colors.textSecondary),
        ),
        if (warning != null) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.statusWarning.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppSpacing.md),
              border: Border.all(
                  color: colors.statusWarning.withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: colors.statusWarning),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    warning!,
                    style: AppTypography.caption.copyWith(color: colors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}


/// The motion of a step change.
///
/// Direction matters more than it looks: content that always slides in from the
/// same side gives the eye no cue about whether the client moved forward or
/// pressed Back, so a six-step flow starts to feel like the same panel
/// reloading. Forward enters from the right (the direction of travel), Back
/// enters from the left, matching the rail.
enum RevealDirection { forward, back }

/// Reveals a step when the active step *changes* — and shows it immediately on
/// first build.
///
/// An `AnimatedSwitcher` renders its very first child at opacity 0 and fades it
/// in. If that fade never runs — which is what happened after the tour closed —
/// the whole step body is invisible while its header renders fine, which reads
/// as a blank panel. Driving the animation ourselves means the first step is
/// painted at full opacity and only *subsequent* steps animate.
class RevealOnChange extends StatefulWidget {
  const RevealOnChange({
    super.key,
    required this.step,
    required this.child,
    this.direction = RevealDirection.forward,
    this.duration = const Duration(milliseconds: 460),
    this.stagger = const Duration(milliseconds: 70),
    this.controller,
    this.onControllerReady,
  });

  final Object step;
  final Widget child;
  final RevealDirection direction;

  /// Supply this to drive [StaggeredReveal] from the same curve. The caller then
  /// owns the lifecycle and must reset + forward it on each step change.
  final AnimationController? controller;

  final ValueChanged<AnimationController>? onControllerReady;

  /// Long enough to read as intentional motion rather than a flicker.
  final Duration duration;

  /// Delay before the second and later sections begin, so the step assembles
  /// instead of arriving as one flat block.
  final Duration stagger;

  @override
  State<RevealOnChange> createState() => _RevealOnChangeState();
}

class _RevealOnChangeState extends State<RevealOnChange>
    with SingleTickerProviderStateMixin {
  late final AnimationController _owned = AnimationController(
    vsync: this,
    duration: widget.duration,
    // Start settled: the first step must never be mid-fade.
    value: 1,
  );

  AnimationController get _c => widget.controller ?? _owned;

  @override
  void initState() {
    super.initState();
    widget.onControllerReady?.call(_c);
  }

  @override
  void didUpdateWidget(RevealOnChange oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The caller owns `_c` when one is supplied, so it also owns the restart.
    if (oldWidget.step != widget.step && widget.controller == null) {
      _c
        ..value = 0
        ..forward();
    }
  }

  @override
  void dispose() {
    _owned.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final forward = widget.direction == RevealDirection.forward;
    // Travels ~4% of the viewport: enough to read as direction, little enough
    // that it never feels like the panel is being thrown across the screen.
    final slide = Tween<Offset>(
      begin: Offset(forward ? 0.045 : -0.045, 0.018),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _c,
        // Decelerating ease-out: leaves the content at rest rather than easing
        // back, which is what makes cheap transitions feel mechanical.
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: _c,
      // Nothing to do while settled — skip the rebuild entirely.
      child: widget.child,
      builder: (context, child) {
        final t = _c.value;
        // Opacity leads the motion slightly so text is legible early.
        final fade = (t / 0.55).clamp(0.0, 1.0);
        return Opacity(
          opacity: fade,
          child: Transform.translate(
            offset: slide.value,
            child: Transform.scale(
              // A whisper of scale sells depth without being noticeable as scale.
              scale: 0.992 + 0.008 * t,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Assembles a step's sections in sequence.
///
/// A step arriving as one block reads as a page load; arriving in a short
/// cascade reads as the interface responding. Each child fades and lifts on its
/// own curve, offset by [RevealOnChange.stagger], and the last child still
/// finishes inside the parent's duration budget.
class StaggeredReveal extends StatelessWidget {
  const StaggeredReveal({
    super.key,
    required this.animation,
    this.children = const [],
    this.child,
    this.stagger = const Duration(milliseconds: 70),
    this.maxStaggered = 5,
  });

  final Animation<double> animation;
  final List<Widget> children;

  /// Single-child form, used when the caller owns the section structure.
  final Widget? child;
  final Duration stagger;

  /// Beyond this the cascade stops feeling deliberate and starts feeling slow.
  final int maxStaggered;

  @override
  Widget build(BuildContext context) {
    final items = child != null ? [child!] : children;
    if (items.isEmpty) return const SizedBox.shrink();
    final stepMs = stagger.inMilliseconds;
    final total = stepMs * (items.length.clamp(1, maxStaggered) - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++)
          AnimatedBuilder(
            animation: animation,
            child: items[i],
            builder: (context, child) {
              // Each section owns a slice of the parent's curve, so the whole
              // step is guaranteed to have settled when the parent completes.
              final begin = total == 0 ? 0.0 : i * stepMs / total * 0.45;
              final t = ((animation.value - begin) / (1 - begin)).clamp(0.0, 1.0);
              final eased = Curves.easeOutCubic.transform(t);
              return Opacity(
                opacity: eased,
                child: Transform.translate(
                  offset: Offset(0, 14 * (1 - eased)),
                  child: child,
                ),
              );
            },
          ),
      ],
    );
  }
}
