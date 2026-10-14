import 'package:desby_app/features/checkout/domain/entities/checkout_draft.dart';
import 'package:desby_app/features/checkout/presentation/providers/checkout_draft_provider.dart';
import 'package:desby_app/features/checkout/domain/entities/journey_state.dart';
import 'package:desby_app/core/error/failures.dart';
import 'package:desby_app/features/checkout/data/repositories/checkout_draft_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// The tracker showed 17% with only step 1 ticked after a client had filled
/// steps 1-4.
///
/// Cause: completion was derived from `acknowledgedSteps`, which is in-memory
/// only — `markStepAnswered` never wrote to it, and the repository never
/// persisted it. Completion now derives from `furthestStep`, which IS a column
/// on order_drafts.
class _Repo implements CheckoutDraftRepositoryContract {
  CheckoutDraft? stored;
  @override
  Future<Result<CheckoutDraft?>> loadFor(CheckoutDraft p) async =>
      Success(stored);
  @override
  Future<Result<CheckoutDraft?>> loadMostRecent(String id) async =>
      Success(stored);
  @override
  Future<Result<CheckoutDraft>> save(CheckoutDraft d) async {
    stored = d;
    return Success(d);
  }

  @override
  Future<Result<void>> discard(CheckoutDraft d) async {
    stored = null;
    return const Success(null);
  }
}

void main() {
  const tailor = CheckoutTailor(id: 't1', name: 'Mulberry Studio');

  CheckoutDraft at(int furthest, {String? garment, Set<CheckoutStep> ack = const {}}) =>
      CheckoutDraft(
        ownerId: 'u1',
        tailor: tailor,
        entryMode: CheckoutEntryMode.fromProfile,
        request: CheckoutRequest(garmentType: garment),
        furthestStep: furthest,
        acknowledgedSteps: ack,
      );

  group('completion survives a save round trip', () {
    test('steps passed are complete even with nothing acknowledged in memory', () {
      final draft = at(3, garment: 'Agbada');
      expect(draft.completedSteps, containsAll(<CheckoutStep>[
        CheckoutStep.defineRequest,
        CheckoutStep.styleDirection,
        CheckoutStep.fabric,
        CheckoutStep.occasion,
      ]));
      expect(draft.completedSteps, isNot(contains(CheckoutStep.measurements)));
    });

    test('reproduces the reported 17% before the fix, fixed after', () {
      // furthestStep 3 == client is working on step 4 (Fit), as in the screenshot.
      final draft = at(3, garment: 'Agbada');
      expect(draft.completedSteps.length, 4);
      // 4 of 6 is 66%; the bug showed 1 of 6 == 17%.
      expect(draft.completedSteps.length, isNot(1));
    });

    test('progress percentage tracks answered steps, not data presence', () {
      // furthestStep 3 -> four answered, review not yet (still one step of work
      // left), so 4/6.
      final draft = at(3, garment: 'Agbada');
      expect(draft.completedSteps.length, 4);
    });

    test('review is the milestone: it completes when every other step is', () {
      // On the last non-review step, review is genuinely complete — that is the
      // milestone state where the submission CTA becomes available.
      final onReview = at(4, garment: 'Agbada');
      expect(onReview.completedSteps, contains(CheckoutStep.review));
      expect(onReview.completedSteps.length, CheckoutStep.values.length);

      // One step short, review must NOT be complete.
      final oneShort = at(3, garment: 'Agbada');
      expect(oneShort.completedSteps, isNot(contains(CheckoutStep.review)));
      expect(oneShort.completedSteps.length, 4);
    });

    test('readiness to submit requires every step complete', () {
      final onReview = at(4, garment: 'Agbada');
      expect(onReview.completedSteps.length,
          CheckoutStep.values.length,
          reason: 'the submit CTA appears only here');
    });

    test('going back to edit an earlier step does not un-complete later ones', () {
      final draft = at(3, garment: 'Agbada')
          .copyWith(request: const CheckoutRequest(garmentType: 'Senator'));
      expect(draft.completedSteps.length, 4,
          reason: 'section 13: Back must never discard later progress');
    });

    test('acknowledgement alone still completes a step', () {
      final draft = at(-1,
          ack: {CheckoutStep.styleDirection, CheckoutStep.fabric});
      expect(draft.completedSteps,
          contains(CheckoutStep.styleDirection));
    });
  });

  group('the controller actually records acknowledgement', () {
    test('markStepAnswered sets both signals', () {
      final repo = _Repo();
      final controller = CheckoutDraftController(repo, null)
        ..begin(ownerId: 'u1', tailor: tailor);

      controller.markStepAnswered(CheckoutStep.styleDirection);
      final s = controller.state!;
      expect(s.furthestStep, CheckoutStep.styleDirection.position);
      expect(s.acknowledgedSteps, contains(CheckoutStep.styleDirection),
          reason: 'this was silently never being written');
    });

    test('acknowledgement never moves furthestStep backwards', () {
      final controller = CheckoutDraftController(_Repo(), null)
        ..begin(ownerId: 'u1', tailor: tailor)
        ..markStepAnswered(CheckoutStep.fabric)
        ..markStepAnswered(CheckoutStep.defineRequest);

      expect(controller.state!.furthestStep, CheckoutStep.fabric.position);
      expect(
        controller.state!.acknowledgedSteps,
        containsAll([CheckoutStep.fabric, CheckoutStep.defineRequest]),
      );
    });
  });

  // ── The reported screenshot ──────────────────────────────────────────────
  // Style and Fabric were filled in and rendered in Review, while the tracker
  // showed 17%, no checkmarks, and no send button.
  group('answers in the draft are honoured wherever they came from', () {
    CheckoutDraft filled({int furthest = 0}) => CheckoutDraft(
          ownerId: 'u1',
          tailor: tailor,
          entryMode: CheckoutEntryMode.fromProfile,
          request: const CheckoutRequest(
            garmentType: 'Agbada',
            summary: 'Six agbada for my brothers wedding',
          ),
          style: const CheckoutStyle(
            tags: ['traditional'],
            fitPreference: 'Regular',
          ),
          fabric: const CheckoutFabric(name: 'Wool', colour: 'White'),
          furthestStep: furthest,
        );

    test('style and fabric count as answered even at furthestStep 0', () {
      final done = filled().completedSteps;
      expect(done, contains(CheckoutStep.styleDirection));
      expect(done, contains(CheckoutStep.fabric));
    });

    test('progress is no longer 17% once those answers exist', () {
      final state = JourneyState(
        currentStep: CheckoutStep.review,
        completedSteps: filled().completedSteps,
      );
      expect(state.progress, greaterThan(0.17));
    });

    test('the request can be sent — the dead end is gone', () {
      final draft = filled();
      final state = JourneyState(
        currentStep: CheckoutStep.review,
        completedSteps: draft.completedSteps,
      );
      expect(state.isReadyToSubmit, isTrue);
      expect(draft.isBlockingComplete, isTrue);
      expect(draft.isSubmittable, isTrue);
    });

    test('progress is not inflated before review is reached', () {
      // furthestStep 3 == working on Fit (step 5). Review must not count yet.
      expect(filled(furthest: 3).completedSteps,
          isNot(contains(CheckoutStep.review)));
    });

    test('a cloth reference alone answers the fabric step', () {
      final draft = const CheckoutDraft(
        ownerId: 'u1',
        tailor: tailor,
        request: CheckoutRequest(garmentType: 'Agbada'),
      ).copyWith(materialAssetUrl: 'https://cdn.example/cloth.jpg');
      expect(draft.completedSteps, contains(CheckoutStep.fabric));
    });

    test('omitting every optional step still allows submission', () {
      // Fabric is blocking, so a reference is part of the minimum now; the rest
      // (style, occasion, fit) are still answerable by omission.
      final bare = CheckoutDraft(
        ownerId: 'u1',
        tailor: tailor,
        entryMode: CheckoutEntryMode.fromProfile,
        request: const CheckoutRequest(garmentType: 'Agbada'),
        furthestStep: CheckoutStep.review.position,
      ).copyWith(materialAssetUrls: const ['https://cdn.example/cloth.jpg']);
      final state = JourneyState(
        currentStep: CheckoutStep.review,
        completedSteps: bare.completedSteps,
      );
      expect(bare.isBlockingComplete, isTrue);
      expect(state.isReadyToSubmit, isTrue);
    });
  });
}
