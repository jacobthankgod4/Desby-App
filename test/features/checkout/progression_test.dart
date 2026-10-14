import 'package:desby_app/features/checkout/domain/entities/checkout_draft.dart';
import 'package:desby_app/features/checkout/domain/entities/journey_state.dart';
import 'package:desby_app/features/checkout/presentation/widgets/progress_tracker.dart';
import 'package:desby_app/features/checkout/presentation/widgets/step_progression_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const tailor = CheckoutTailor(id: 't1', name: 'Chibueze Atelier');

  CheckoutDraft draftWith({
    String? garment,
    List<String> tags = const [],
    String? fabric,
    String? fitPreference,
    List<String> occasions = const [],
    Map<String, double> measurements = const {},
    Set<CheckoutStep> acknowledged = const {},
    String? summaryOverride,
  }) =>
      CheckoutDraft(
        ownerId: 'u1',
        tailor: tailor,
        entryMode: CheckoutEntryMode.fromProfile,
        request: CheckoutRequest(garmentType: garment, summary: summaryOverride),
        style: CheckoutStyle(tags: tags, fitPreference: fitPreference),
        fabric: CheckoutFabric(name: fabric),
        occasions: occasions,
        measurements: CheckoutMeasurements(
          source: measurements.isEmpty
              ? MeasurementSource.none
              : MeasurementSource.bodyScan,
          values: measurements.isEmpty ? null : measurements,
        ),
        acknowledgedSteps: acknowledged,
      );

  group('Only the current step is exposed (sections 2 and 11)', () {
    test('at the start, only step 1 is visible', () {
      const state = JourneyState();
      expect(state.currentStep, CheckoutStep.defineRequest);
      expect(state.visibleSteps, [CheckoutStep.defineRequest]);
      expect(state.isLocked(CheckoutStep.fabric), isTrue);
      expect(state.isLocked(CheckoutStep.review), isTrue);
    });

    test('only the active step is exposed until earlier ones are answered', () {
      final state = JourneyState(currentStep: CheckoutStep.fabric);
      expect(state.visibleSteps, [CheckoutStep.fabric],
          reason: 'steps 1 and 2 have not been completed yet');
      expect(state.isLocked(CheckoutStep.occasion), isTrue);
    });

    test('answered steps stay visible as summaries once completed', () {
      final state = JourneyState(
        currentStep: CheckoutStep.fabric,
        completedSteps: {CheckoutStep.defineRequest, CheckoutStep.styleDirection},
      );
      expect(state.visibleSteps, [
        CheckoutStep.defineRequest,
        CheckoutStep.styleDirection,
        CheckoutStep.fabric,
      ], reason: 'summaries are ordered by position, active step last');
    });

    test('the review is never exposed before its turn', () {
      for (final step in CheckoutStep.values) {
        if (step == CheckoutStep.review) continue;
        final state = JourneyState(currentStep: step);
        expect(state.isLocked(CheckoutStep.review), isTrue,
            reason: 'review must stay locked while ${step.name} is active');
      }
    });

    test('visible steps are the completed ones plus the current one', () {
      final state = JourneyState(
        currentStep: CheckoutStep.occasion,
        completedSteps: {
          CheckoutStep.defineRequest,
          CheckoutStep.styleDirection,
          CheckoutStep.fabric,
        },
      );
      expect(state.visibleSteps.length, 4);
      expect(state.availableSteps, state.visibleSteps);
    });
  });

  group('Three distinct tracker states (section 7)', () {
    test('locked, current and completed are mutually exclusive', () {
      final state = JourneyState(
        currentStep: CheckoutStep.styleDirection,
        completedSteps: {CheckoutStep.defineRequest},
      );
      expect(state.stateOf(CheckoutStep.defineRequest),
          JourneyStepState.completed);
      expect(state.stateOf(CheckoutStep.styleDirection),
          JourneyStepState.current);
      expect(state.stateOf(CheckoutStep.fabric), JourneyStepState.locked);
      // and the sequence the brief asks for
      expect(
        state.stateOf(CheckoutStep.defineRequest).name,
        'completed',
      );
      expect(state.stateOf(CheckoutStep.styleDirection).name, 'current');
      expect(state.stateOf(CheckoutStep.fabric).name, 'locked');
    });

    test('counter and progress track real completion', () {
      final state = JourneyState(
        currentStep: CheckoutStep.fabric,
        completedSteps: {
          CheckoutStep.defineRequest,
          CheckoutStep.styleDirection,
        },
      );
      expect(state.counterLabel, 'Step 3 of 6');
      expect(state.progress, closeTo(2 / 6, 0.001));
    });
  });

  group('Submission CTA appears only when the request is ready (section 19)', () {
    test('never ready mid-journey', () {
      for (final step in CheckoutStep.values.where((s) => s != CheckoutStep.review)) {
        expect(JourneyState(currentStep: step).isReadyToSubmit, isFalse);
      }
    });

    test('not ready merely by reaching review with steps outstanding', () {
      final state = JourneyState(currentStep: CheckoutStep.review);
      expect(state.isReadyToSubmit, isFalse,
          reason: 'review alone is not completion');
    });

    test('ready only when every step is complete', () {
      final state = JourneyState(
        currentStep: CheckoutStep.review,
        completedSteps: {
          CheckoutStep.defineRequest,
          CheckoutStep.styleDirection,
          CheckoutStep.fabric,
          CheckoutStep.occasion,
          CheckoutStep.measurements,
          CheckoutStep.review,
        },
      );
      expect(state.isReadyToSubmit, isTrue);
      expect(state.isMilestone, isTrue);
      expect(state.progress, 1.0);
    });
  });

  group('Unlocking is based on real completion, not on opening (section 12)', () {
    test('step 1 is not complete without a garment', () {
      final draft = draftWith();
      expect(draft.completedSteps.contains(CheckoutStep.defineRequest), isFalse);
    });

    test('a chosen garment completes step 1', () {
      final draft = draftWith(garment: 'Agbada');
      expect(draft.completedSteps.contains(CheckoutStep.defineRequest), isTrue);
    });

    test('blank text does not count', () {
      final draft = draftWith(garment: '   ');
      expect(draft.completedSteps.contains(CheckoutStep.defineRequest), isFalse);
    });

    test('a product entry completes step 1 with no garment chosen', () {
      const draft = CheckoutDraft(
        ownerId: 'u1',
        tailor: tailor,
        entryMode: CheckoutEntryMode.fromProduct,
        product: CheckoutProduct(designId: 'd1', title: 'Aso Ebi'),
      );
      expect(draft.completedSteps.contains(CheckoutStep.defineRequest), isTrue);
    });

    test('optional steps complete on acknowledgement, not on data', () {
      // No fabric, no notes, no scan — still allowed through.
      final draft = draftWith(
        garment: 'Agbada',
        acknowledged: {
          CheckoutStep.styleDirection,
          CheckoutStep.fabric,
          CheckoutStep.occasion,
          CheckoutStep.measurements,
        },
      );
      expect(draft.completedSteps, contains(CheckoutStep.fabric));
      expect(draft.completedSteps, contains(CheckoutStep.measurements));
      expect(draft.completedSteps, contains(CheckoutStep.review));
    });

    test('review is never complete while a required step is missing', () {
      final draft = draftWith(
        garment: 'Agbada',
        acknowledged: {
          CheckoutStep.styleDirection,
          CheckoutStep.fabric,
          CheckoutStep.occasion,
        },
      );
      expect(draft.completedSteps.contains(CheckoutStep.review), isFalse);
    });
  });

  group('Back is non-destructive (section 13)', () {
    test('completed steps stay completed and editable', () {
      // Realistic state: the client answered 1 and 2 and is now on 3.
      final before = JourneyState(
        currentStep: CheckoutStep.fabric,
        completedSteps: {
          CheckoutStep.defineRequest,
          CheckoutStep.styleDirection,
        },
      );
      final afterGoingBack = before.copyWith(currentStep: CheckoutStep.styleDirection);
      // Data is not touched by navigation.
      expect(afterGoingBack.completedSteps, before.completedSteps);
      // The step they left is still reachable, so their answers stay editable.
      expect(afterGoingBack.isLocked(CheckoutStep.styleDirection), isFalse);
      expect(afterGoingBack.isCompleted(CheckoutStep.defineRequest), isTrue);
      expect(afterGoingBack.visibleSteps, [
        CheckoutStep.defineRequest,
        CheckoutStep.styleDirection,
      ]);
    });

    test('a locked step cannot be jumped to', () {
      final state = JourneyState(currentStep: CheckoutStep.defineRequest);
      expect(state.isLocked(CheckoutStep.review), isTrue);
      expect(state.availableSteps.contains(CheckoutStep.review), isFalse);
    });
  });

  group('Editing an earlier step warns about consequences (section 14)', () {
    test('dependents are only steps already completed after it', () {
      final state = JourneyState(
        currentStep: CheckoutStep.occasion,
        completedSteps: {
          CheckoutStep.defineRequest,
          CheckoutStep.styleDirection,
          CheckoutStep.fabric,
        },
      );
      // Jumping back to step 1, steps 2 and 3 are downstream.
      expect(state.dependentsOf(CheckoutStep.defineRequest),
          [CheckoutStep.styleDirection, CheckoutStep.fabric]);
    });

    test('nothing downstream means nothing to warn about', () {
      final state = JourneyState(currentStep: CheckoutStep.defineRequest);
      expect(state.dependentsOf(CheckoutStep.defineRequest), isEmpty);
    });

    test('later completed steps are NOT wiped by editing an earlier one', () {
      final draft = draftWith(garment: 'Agbada', tags: ['Traditional']);
      final edited = draft.copyWith(
        request: const CheckoutRequest(garmentType: 'Senator'),
      );
      // Changing the garment must not silently discard the style answers.
      expect(edited.style.tags, ['Traditional']);
    });
  });

  group('Completed steps collapse to a summary (section 4)', () {
    test('summaries read as one line, not a form', () {
      final draft = draftWith(
        garment: 'Agbada',
        tags: ['Traditional', 'Regal'],
        fitPreference: 'Slim',
        fabric: 'Linen',
        occasions: ['Wedding'],
      );
      expect(
        CompletedStepSummary.summaryFor(CheckoutStep.styleDirection, draft),
        'Traditional, Regal · Slim fit',
      );
      expect(
        CompletedStepSummary.summaryFor(CheckoutStep.fabric, draft),
        'Linen',
      );
      expect(
        CompletedStepSummary.summaryFor(CheckoutStep.occasion, draft),
        'Wedding',
      );
    });

    test('a step with nothing chosen says so rather than lying', () {
      final draft = draftWith(garment: 'Agbada');
      expect(
        CompletedStepSummary.summaryFor(CheckoutStep.fabric, draft),
        isNull,
        reason: 'null means "not specified — your tailor will ask"');
      expect(
        CompletedStepSummary.summaryFor(CheckoutStep.measurements, draft),
        'To be taken at fitting',
      );
    });

    test('a long summary is truncated, not wrapped over the page', () {
      final draft = draftWith(
        garment: 'Agbada',
        summaryOverride: 'x' * 200,
      );
      final line =
          CompletedStepSummary.summaryFor(CheckoutStep.defineRequest, draft);
      expect(line, isNotNull);
      expect(line!.length, lessThanOrEqualTo(90));
      expect(line, endsWith('…'));
    });
  });

  group('Transition guard prevents double submission', () {
    test('isTransitioning is observable', () {
      const state = JourneyState(isTransitioning: true);
      expect(state.isTransitioning, isTrue);
      expect(state.copyWith(isTransitioning: false).isTransitioning, isFalse);
    });

    test('isSubmitting is separate from isTransitioning', () {
      const state = JourneyState(isSubmitting: true);
      expect(state.isSubmitting, isTrue);
      expect(state.isTransitioning, isFalse);
    });
  });

  group('Tracker renders only reachable steps as interactive', () {
    testWidgets('locked rows are not tappable', (tester) async {
      var taps = 0;
      final state = JourneyState(currentStep: CheckoutStep.defineRequest);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ProgressTracker(
            state: state,
            draft: draftWith(),
            onJump: (_) => taps++,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final rows = find.bySemanticsLabel(RegExp('not yet available'));
      expect(rows, findsWidgets);
      await tester.tap(find.text('Fabric').first);
      expect(taps, 0, reason: 'a locked step must not be jumpable');
    });

    testWidgets('the current step is announced as selected', (tester) async {
      final state = JourneyState(currentStep: CheckoutStep.styleDirection);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ProgressTracker(
            state: state,
            draft: draftWith(garment: 'Agbada'),
            onJump: (_) {},
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Style direction, current step.'),
          findsOneWidget);
      expect(find.bySemanticsLabel('Fabric, not yet available.'),
          findsOneWidget);
    });

    testWidgets('a completed step announces its summary', (tester) async {
      final state = JourneyState(
        currentStep: CheckoutStep.fabric,
        completedSteps: {CheckoutStep.defineRequest},
      );
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ProgressTracker(
            state: state,
            draft: draftWith(garment: 'Agbada'),
            onJump: (_) {},
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel(RegExp('Define the request, completed')),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.check), findsWidgets);
    });
  });
}
