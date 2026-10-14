import 'package:equatable/equatable.dart';

import '../entities/checkout_draft.dart';

/// Whether a step is locked, in progress, or done.
///
/// This is a *workflow state*, not a styling hint. Locked steps are not built
/// at all — see [JourneyState.visibleSteps] — because a hidden form is still in
/// the tree, still focusable by a screen reader, and still tab-reachable on a
/// keyboard. Progressive disclosure has to be structural to be honest.
enum JourneyStepState { locked, current, completed }

/// The explicit workflow model the brief asks for:
///
/// ```
/// checkout state:
///   currentStep
///   completedSteps
///   availableSteps
///   isTransitioning
///   isSubmitting
/// ```
///
/// One place that answers "where is the client and what may they see", so the
/// UI never has to infer it. Built on the project's existing Riverpod
/// conventions rather than a new state library.
class JourneyState extends Equatable {
  /// The single active step. Exactly one is ever `current`.
  final CheckoutStep currentStep;

  /// Steps the client has finished, in completion order.
  final Set<CheckoutStep> completedSteps;

  /// Set while a step-completion animation runs, so the CTA cannot be
  /// double-pressed and the next step is not revealed early.
  final bool isTransitioning;

  final bool isSubmitting;

  const JourneyState({
    this.currentStep = CheckoutStep.defineRequest,
    this.completedSteps = const {},
    this.isTransitioning = false,
    this.isSubmitting = false,
  });

  /// Steps the client is allowed to see: every completed step (rendered as a
  /// compact summary and editable) plus the one active step.
  ///
  /// Completed steps stay visible after going Back — section 13 requires them
  /// to remain editable, and section 4 wants them visible as summaries. Only
  /// never-visited steps are locked, and they return no widget at all.
  ///
  /// Exactly one of these is *active* ([currentStep]); the rest are read-only
  /// summaries, so this is not an accordion.
  List<CheckoutStep> get visibleSteps {
    final visible = {...completedSteps, currentStep}.toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    return visible;
  }

  /// Steps whose data may be edited — completed ones and the current one.
  /// Locked steps are not reachable.
  List<CheckoutStep> get availableSteps => visibleSteps;

  bool isLocked(CheckoutStep step) => !availableSteps.contains(step);

  bool isCompleted(CheckoutStep step) => completedSteps.contains(step);

  bool isCurrent(CheckoutStep step) => step == currentStep;

  JourneyStepState stateOf(CheckoutStep step) {
    if (isCompleted(step)) return JourneyStepState.completed;
    if (isCurrent(step)) return JourneyStepState.current;
    return JourneyStepState.locked;
  }

  /// True once the journey is ready to submit — the only time the primary
  /// submission CTA may appear. Showing "Place Order" while required steps are
  /// unfinished is exactly the confusion the brief calls out.
  /// True once on review AND the blocking answers are present.
  ///
  /// Scoped rather than every-step: optional steps are answered by omission, so
  /// demanding all of them left a client reading their finished request with no
  /// send button. Reaching review on its own is still not enough.
  ///
  /// This can only see *completion*, which is derived from how far the client
  /// travelled. Whether the answers themselves are present — notably a cloth
  /// reference — is the draft's call, and the page ANDs in
  /// `draft.isBlockingComplete` before showing the CTA.
  bool get isReadyToSubmit =>
      currentStep == CheckoutStep.review &&
      completedSteps.contains(CheckoutStep.defineRequest);

  /// Fraction complete, for reassurance only. Never the dominant element.
  double get progress =>
      completedSteps.length / CheckoutStep.values.length;

  String get counterLabel =>
      'Step ${currentStep.position + 1} of ${CheckoutStep.values.length}';

  /// The review milestone: every step done, request ready to send.
  bool get isMilestone => isReadyToSubmit;

  /// Which steps would be affected if the client changes [step].
  ///
  /// The brief is explicit: do not silently destroy input, and explain the
  /// consequence. This powers that message instead of guessing.
  List<CheckoutStep> dependentsOf(CheckoutStep step) {
    final index = step.position;
    return CheckoutStep.values
        .where((s) => s.position > index && isCompleted(s))
        .toList(growable: false);
  }

  JourneyState copyWith({
    CheckoutStep? currentStep,
    Set<CheckoutStep>? completedSteps,
    bool? isTransitioning,
    bool? isSubmitting,
  }) =>
      JourneyState(
        currentStep: currentStep ?? this.currentStep,
        completedSteps: completedSteps ?? this.completedSteps,
        isTransitioning: isTransitioning ?? this.isTransitioning,
        isSubmitting: isSubmitting ?? this.isSubmitting,
      );

  @override
  List<Object?> get props =>
      [currentStep, completedSteps, isTransitioning, isSubmitting];
}
