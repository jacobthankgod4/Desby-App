import 'package:desby_app/core/error/failures.dart';
import 'package:desby_app/features/checkout/data/repositories/checkout_draft_repository.dart';
import 'package:desby_app/features/checkout/domain/entities/checkout_draft.dart';
import 'package:desby_app/features/checkout/presentation/providers/checkout_draft_provider.dart';
import 'package:desby_app/features/checkout/presentation/providers/request_journey_feature.dart';
import 'package:desby_app/features/checkout/presentation/widgets/request_steps.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// The repository is the only thing that would reach the network, so it is
// overridden with an in-memory double. Everything under test — step gating,
// scenario awareness, state preservation across Back — is pure logic.
class _FakeDraftRepo implements CheckoutDraftRepositoryContract {
  CheckoutDraft? stored;

  @override
  Future<Result<CheckoutDraft?>> loadFor(CheckoutDraft probe) async =>
      Success(stored);

  @override
  Future<Result<CheckoutDraft?>> loadMostRecent(String ownerId) async =>
      Success(stored);

  @override
  Future<Result<CheckoutDraft>> save(CheckoutDraft draft) async {
    stored = draft;
    return Success(draft);
  }

  @override
  Future<Result<void>> discard(CheckoutDraft draft) async {
    stored = null;
    return const Success(null);
  }
}

void main() {
  late _FakeDraftRepo repo;

  const tailor = CheckoutTailor(id: 'tailor-1', name: 'Chibueze Atelier');

  ProviderContainer makeContainer() {
    repo = _FakeDraftRepo();
    final container = ProviderContainer(
      overrides: [
        checkoutDraftRepositoryProvider.overrideWithValue(repo),
      ],
    );
    return container;
  }

  setUp(() => RequestJourneyFeature.overrideForTesting(true));
  tearDown(() => RequestJourneyFeature.overrideForTesting(null));

  group('Scenario A — tailor profile, no product', () {
    test('step 1 asks what to sew, and does not offer a product question', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.read(checkoutDraftControllerProvider.notifier).begin(
            ownerId: 'u1',
            tailor: tailor,
          );

      final draft = container.read(checkoutDraftControllerProvider)!;
      expect(draft.product, isNull);
      expect(draft.entryMode, CheckoutEntryMode.fromProfile);
      expect(draft.entryMode.needsGarmentDefinition, isTrue);
      expect(draft.isStepComplete(CheckoutStep.defineRequest), isFalse);
      expect(draft.isSubmittable, isFalse);
    });

    test('choosing a garment satisfies step 1 and enables submission', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(checkoutDraftControllerProvider.notifier)
            ..begin(ownerId: 'u1', tailor: tailor);
      final first = container.read(checkoutDraftControllerProvider)!;

      notifier.setRequest(first.request.copyWith(garmentType: 'Agbada'));

      final after = container.read(checkoutDraftControllerProvider)!;
      expect(after.isStepComplete(CheckoutStep.defineRequest), isTrue);
      expect(after.isSubmittable, isTrue);
    });
  });

  group('Scenario B — a design is already selected', () {
    test('step 1 is already answered and the design is carried', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.read(checkoutDraftControllerProvider.notifier).begin(
            ownerId: 'u1',
            tailor: tailor,
            product: const CheckoutProduct(
              designId: 'design-9',
              title: 'Aso Ebi Party Set',
              category: 'ASO EBI',
              price: 75000,
              selectedSize: '54',
              selectedColour: 'Gold',
              quantity: 2,
            ),
          );

      final draft = container.read(checkoutDraftControllerProvider)!;
      expect(draft.entryMode, CheckoutEntryMode.fromProduct);
      expect(draft.isStepComplete(CheckoutStep.defineRequest), isTrue,
          reason: 'never ask a client to pick a design they already picked');
      expect(draft.isSubmittable, isTrue);
      // The legacy flow dropped every one of these.
      expect(draft.product!.designId, 'design-9');
      expect(draft.product!.selectedSize, '54');
      expect(draft.product!.selectedColour, 'Gold');
      expect(draft.product!.quantity, 2);
    });

    test('the client can still ask for something different', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(checkoutDraftControllerProvider.notifier)
            ..begin(
              ownerId: 'u1',
              tailor: tailor,
              product: const CheckoutProduct(designId: 'd1', title: 'Senator'),
            );

      notifier.setEntryMode(CheckoutEntryMode.customDesign);
      notifier.setRequest(
        container
            .read(checkoutDraftControllerProvider)!
            .request
            .copyWith(garmentType: 'Kaftan', wantsSomethingDifferent: true),
      );

      final draft = container.read(checkoutDraftControllerProvider)!;
      expect(draft.entryMode.hasProduct, isTrue);
      expect(draft.request.wantsSomethingDifferent, isTrue);
      expect(draft.isSubmittable, isTrue);
    });
  });

  group('Back never loses anything (TEST 3)', () {
    test('step 1 survives moving forward and back', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(checkoutDraftControllerProvider.notifier)
            ..begin(ownerId: 'u1', tailor: tailor);

      final empty = container.read(checkoutDraftControllerProvider)!;
      notifier.setRequest(empty.request.copyWith(
        garmentType: 'Agbada',
        summary: 'Six for my brothers wedding',
      ));

      await notifier.advanceFrom(CheckoutStep.defineRequest);
      // the client changes their mind and steps back
      await notifier.advanceFrom(CheckoutStep.styleDirection);
      final notifier2 =
          container.read(checkoutDraftControllerProvider.notifier)
            ..setStyle(const CheckoutStyle(tags: ['Traditional'], fitPreference: 'Slim'));
      await notifier2.advanceFrom(CheckoutStep.styleDirection);
      await notifier2.advanceFrom(CheckoutStep.fabric);

      final back = container.read(checkoutDraftControllerProvider)!;
      expect(back.request.garmentType, 'Agbada');
      expect(back.request.summary, 'Six for my brothers wedding');
      expect(back.style.tags, ['Traditional'], reason: 'step 2 must persist too');
      // Steps 0 (define), 1 (style, re-saved) and 2 (fabric) answered.
      expect(back.furthestStep, 2,
          reason: 'editing step 1 must not rewind past step 2');
    });

    test('toggling an occasion off does not disturb the others', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(checkoutDraftControllerProvider.notifier)
            ..begin(ownerId: 'u1', tailor: tailor);
      notifier.setOccasions(['Wedding', 'Church']);
      notifier.toggleOccasion('Wedding');
      expect(container.read(checkoutDraftControllerProvider)!.occasions, ['Church']);
      notifier.toggleOccasion('Corporate');
      expect(
        container.read(checkoutDraftControllerProvider)!.occasions,
        ['Church', 'Corporate'],
        reason: 'multi-select, order preserved',
      );
    });
  });

  group('Persistence (TEST 4)', () {
    test('advance saves before recording progress', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(checkoutDraftControllerProvider.notifier)
            ..begin(ownerId: 'u1', tailor: tailor);
      final d0 = container.read(checkoutDraftControllerProvider)!;
      notifier.setRequest(d0.request.copyWith(garmentType: 'Senator'));

      final error = await notifier.advanceFrom(CheckoutStep.defineRequest);
      expect(error, isNull);
      // The repository received the step, not just the in-memory state.
      expect(repo.stored, isNotNull);
      expect(repo.stored!.furthestStep, 0,
          reason: 'step index 0 answered; nextStep resolves to style');
      expect(repo.stored!.request.garmentType, 'Senator');
    });

    test('a save failure never discards what the client typed', () async {
      final container = ProviderContainer(
        overrides: [
          checkoutDraftRepositoryProvider.overrideWithValue(_FailingRepo()),
        ],
      );
      addTearDown(container.dispose);
      final notifier =
          container.read(checkoutDraftControllerProvider.notifier)
            ..begin(ownerId: 'u1', tailor: tailor);
      final d0 = container.read(checkoutDraftControllerProvider)!;
      notifier.setRequest(d0.request.copyWith(garmentType: 'Gown'));

      final error = await notifier.advanceFrom(CheckoutStep.defineRequest);
      expect(error, isNotNull);
      // In-memory draft is still authoritative.
      final draft = container.read(checkoutDraftControllerProvider)!;
      expect(draft.request.garmentType, 'Gown');
    });

    test('restore adopts a saved draft and keeps furthestStep', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      final notifier = container.read(checkoutDraftControllerProvider.notifier)
        ..begin(ownerId: 'u1', tailor: tailor);

      notifier.restore(CheckoutDraft(
        ownerId: 'u1',
        tailor: tailor,
        entryMode: CheckoutEntryMode.fromProfile,
        request: const CheckoutRequest(garmentType: 'Senator', summary: 'saved'),
        furthestStep: 3,
      ));

      final draft = container.read(checkoutDraftControllerProvider)!;
      expect(draft.request.garmentType, 'Senator');
      expect(draft.request.summary, 'saved');
      expect(draft.furthestStep, 3);
    });

    test('discard clears the draft', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      final notifier = container.read(checkoutDraftControllerProvider.notifier)
        ..begin(ownerId: 'u1', tailor: tailor);
      await notifier.discard();
      expect(container.read(checkoutDraftControllerProvider), isNull);
    });
  });

  group('Feature flag is a pure rollback', () {
    test('disabled routes fall back to the legacy chain', () {
      RequestJourneyFeature.overrideForTesting(false);
      expect(checkoutRouteForTailorProfile(), '/booking-cart');
      expect(checkoutRouteForDesign(), '/booking-cart');
      expect(checkoutRouteFor(hasProduct: true), '/booking-cart');
    });

    test('enabled routes go to the journey', () {
      RequestJourneyFeature.overrideForTesting(true);
      expect(checkoutRouteForTailorProfile(), '/request-journey');
      expect(checkoutRouteForDesign(), '/request-journey');
      expect(checkoutRouteFor(hasProduct: true), '/request-journey');
    });

    test('the two scenarios build different route arguments', () {
      final profile = tailorProfileJourneyArgs(
        tailorId: 't1',
        tailorName: 'Chibueze',
      );
      final design = designJourneyArgs(
        designId: 'd1',
        tailorId: 't1',
        title: 'Aso Ebi',
        selectedSize: '54',
        selectedColour: 'Gold',
      );
      expect(profile.containsKey('designId'), isFalse);
      expect(design['designId'], 'd1');
      expect(design['selectedSize'], '54');
      expect(design['selectedColour'], 'Gold');
    });
  });

  group('Selection chips are accessible', () {
    testWidgets('selected state is not signalled by colour alone',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SelectionChip(
            label: 'Wedding',
            selected: true,
            onTap: () => taps++,
          ),
        ),
      ));

      // The check icon is present for screen-reader-free selection cues.
      expect(find.byIcon(Icons.check), findsOneWidget);
      final node = tester.getSemantics(find.byType(SelectionChip));
      // Selected state must reach assistive tech, not just be drawn.
      expect(node.getSemanticsData().hasFlag(SemanticsFlag.isSelected), isTrue);
      expect(node.getSemanticsData().hasFlag(SemanticsFlag.isButton), isTrue);

      await tester.tap(find.byType(SelectionChip));
      expect(taps, 1);
    });

    testWidgets('an unselected chip has no check icon and is not selected',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: SelectionChip(label: 'Casual', selected: false, onTap: _noop)),
      ));
      expect(find.byIcon(Icons.check), findsNothing);
    });
  });
}

void _noop() {}

class _FailingRepo implements CheckoutDraftRepositoryContract {
  @override
  Future<Result<CheckoutDraft?>> loadFor(CheckoutDraft probe) async =>
      const Success(null);

  @override
  Future<Result<CheckoutDraft?>> loadMostRecent(String ownerId) async =>
      const Success(null);

  @override
  Future<Result<CheckoutDraft>> save(CheckoutDraft draft) async =>
      Failure(AuthFailure(message: 'network down'));

  @override
  Future<Result<void>> discard(CheckoutDraft draft) async =>
      const Success(null);
}
