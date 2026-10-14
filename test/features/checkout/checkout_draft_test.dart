import 'package:desby_app/features/checkout/domain/entities/checkout_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const owner = 'owner-1';
  const tailor = CheckoutTailor(id: 'tailor-1', name: 'Chibueze Atelier');
  const product = CheckoutProduct(
    designId: 'design-1',
    title: 'Aso Ebi Party Set',
    category: 'ASO EBI',
    price: 75000,
    selectedSize: 'L',
    selectedColour: 'Gold',
  );

  CheckoutDraft fromProfile() => CheckoutDraft(
        ownerId: owner,
        tailor: tailor,
        entryMode: CheckoutEntryMode.fromProfile,
      );

  CheckoutDraft fromProduct() => CheckoutDraft(
        ownerId: owner,
        tailor: tailor,
        product: product,
        entryMode: CheckoutEntryMode.fromProduct,
      );

  group('Entry mode decides what we are allowed to ask', () {
    test('from a profile there is no product, so we must ask what to sew', () {
      final draft = fromProfile();
      expect(draft.product, isNull);
      expect(draft.entryMode.needsGarmentDefinition, isTrue);
      expect(draft.isStepComplete(CheckoutStep.defineRequest), isFalse,
          reason: 'nothing chosen yet, so the step is not answerable');
    });

    test('from a profile, naming a garment completes step 1', () {
      final draft = fromProfile().copyWith(
        request: const CheckoutRequest(garmentType: 'Agbada'),
      );
      expect(draft.isStepComplete(CheckoutStep.defineRequest), isTrue);
    });

    test('from a product the design is the answer — never re-ask', () {
      final draft = fromProduct();
      expect(draft.entryMode.needsGarmentDefinition, isFalse);
      expect(draft.isStepComplete(CheckoutStep.defineRequest), isTrue);
      expect(draft.product!.designId, 'design-1');
    });

    test('a product choice can still become a different request', () {
      final draft = fromProduct().copyWith(
        entryMode: CheckoutEntryMode.customDesign,
        request: const CheckoutRequest(
          garmentType: 'Senator',
          wantsSomethingDifferent: true,
        ),
      );
      expect(draft.entryMode.hasProduct, isTrue);
      expect(draft.request.wantsSomethingDifferent, isTrue);
      expect(draft.isStepComplete(CheckoutStep.defineRequest), isTrue);
    });

    test('entry mode round-trips through its db name', () {
      for (final mode in CheckoutEntryMode.values) {
        expect(CheckoutEntryMode.fromName(mode.storageValue), mode);
      }
      expect(CheckoutEntryMode.fromName('nonsense'), isNull);
      expect(CheckoutEntryMode.fromName(null), isNull);
    });

    test('the db only accepts the three modes it has a CHECK for', () {
      // order_drafts_entry_mode_check
      const allowed = {'from_profile', 'from_product', 'custom_design'};
      for (final mode in CheckoutEntryMode.values) {
        expect(allowed, contains(mode.storageValue),
            reason: '${mode.name} must serialise to a value the CHECK accepts');
        // Dart's default name would be camelCase and fail every insert (23514).
        expect(mode.storageValue, isNot(mode.name));
      }
    });
  });

  group('Product selection is carried, not dropped', () {
    test('size and colour survive into the submission map', () {
      final map = fromProduct().toSubmissionMap();
      expect(map['design_id'], 'design-1');
      expect(map['selected_size'], 'L');
      expect(map['selected_colour'], 'Gold');
      expect(map['quantity'], 1);
      // The legacy flow dropped designId, size and colorIndex on the floor.
      expect(map['entry_mode'], 'from_product');
    });

    test('a product entry reports no garment question in the submission', () {
      expect(fromProduct().toSubmissionMap()['garment_type'], isNull);
    });
  });

  group('Progress never moves backwards', () {
    test('a fresh draft has answered nothing', () {
      final draft = fromProfile();
      expect(draft.furthestStep, -1,
          reason: 'must be distinguishable from "step 1 answered"');
      expect(draft.nextStep, CheckoutStep.defineRequest);
    });

    test('marking a later step advances furthestStep', () {
      final draft = fromProfile().copyWith(furthestStep: 3);
      expect(draft.furthestStep, 3);
      // furthestStep is the furthest ANSWERED step, so the next one to
      // answer is the following index.
      expect(draft.nextStep, CheckoutStep.measurements);
    });

    test('answering every step reaches the end', () {
      var draft = fromProfile();
      for (final step in CheckoutStep.values) {
        draft = draft.copyWith(furthestStep: step.position);
      }
      expect(draft.furthestStep, 5);
      expect(draft.nextStep, isNull);
    });

    test('re-entering an earlier step keeps later progress', () {
      // The client tapped Edit on step 0 after reaching step 4. That must not
      // discard steps 1-4.
      final draft = fromProfile().copyWith(furthestStep: 4);
      expect(draft.furthestStep, 4);
      expect(draft.copyWith(request: const CheckoutRequest(garmentType: 'Kaftan'))
          .furthestStep, 4);
    });

    test('steps are addressable by index without drift', () {
      expect(CheckoutStep.fromIndex(0), CheckoutStep.defineRequest);
      expect(CheckoutStep.fromIndex(5), CheckoutStep.review);
      expect(CheckoutStep.fromIndex(6), isNull);
      expect(CheckoutStep.fromIndex(-1), isNull);
      expect(CheckoutStep.review.position, 5);
    });

    test('every step has a title and a stated purpose', () {
      for (final step in CheckoutStep.values) {
        expect(step.title, isNotEmpty, reason: '$step needs a title');
        expect(step.purpose, isNotEmpty, reason: '$step needs to justify itself');
      }
    });
  });

  group('Optional is optional', () {
    test('steps 2-5 never block progress', () {
      final draft = fromProfile()
          .copyWith(request: const CheckoutRequest(garmentType: 'Agbada'));
      for (final step in [
        CheckoutStep.styleDirection,
        CheckoutStep.fabric,
        CheckoutStep.occasion,
        CheckoutStep.measurements,
      ]) {
        expect(draft.isStepComplete(step), isTrue,
            reason: '${step.title} must not hard-block the journey');
      }
    });

    test('a client with no fabric, no image and no notes can still submit', () {
      final draft = fromProfile()
          .copyWith(request: const CheckoutRequest(garmentType: 'Agbada'));
      expect(draft.style.isEmpty, isTrue);
      expect(draft.fabric.isEmpty, isTrue);
      expect(draft.isSubmittable, isTrue);
    });

    test('garment and cloth reference are the only blocking steps', () {
      // Fabric became blocking deliberately: a request with no picture of the
      // cloth is the biggest source of "this is not what I asked for".
      expect(fromProfile().blockingSteps,
          [CheckoutStep.defineRequest, CheckoutStep.fabric]);
      // Everything else is answered by moving on.
      expect(fromProfile().blockingSteps, isNot(contains(CheckoutStep.occasion)));
      expect(fromProfile().blockingSteps, isNot(contains(CheckoutStep.review)));
    });
  });

  group('Submitting', () {
    test('requires a tailor', () {
      final draft = CheckoutDraft(
        ownerId: owner,
        request: const CheckoutRequest(garmentType: 'Agbada'),
      );
      expect(draft.isSubmittable, isFalse);
    });

    test('requires a garment only when entering from a profile', () {
      expect(fromProfile().isSubmittable, isFalse);
      expect(fromProduct().isSubmittable, isTrue);
    });

    test('blank garment text does not count as an answer', () {
      expect(
        fromProfile()
            .copyWith(request: const CheckoutRequest(garmentType: '   '))
            .isSubmittable,
        isFalse,
      );
    });
  });

  group('Order-level preferences stay out of global preferences', () {
    test('style tags live on the draft only', () {
      final draft = fromProduct().copyWith(
        style: const CheckoutStyle(
          tags: ['wedding', 'traditional'],
          fitPreference: 'Slim',
        ),
      );
      // The draft is the only thing changed. Nothing here writes to
      // users.preferences, which is what the brief demands.
      expect(draft.style.tags, ['wedding', 'traditional']);
      expect(draft.toSubmissionMap()['style_tags'], ['wedding', 'traditional']);
    });

    test('a draft copy never mutates the original', () {
      final original = fromProfile().copyWith(
        request: const CheckoutRequest(garmentType: 'Agbada'),
      );
      final edited = original.copyWith(
        request: const CheckoutRequest(garmentType: 'Kaftan'),
      );
      expect(original.request.garmentType, 'Agbada');
      expect(edited.request.garmentType, 'Kaftan');
    });
  });

  group('Occasions are multi-select', () {
    test('a request can be for more than one occasion', () {
      final draft = fromProduct().copyWith(occasions: ['wedding', 'church']);
      expect(draft.occasions, hasLength(2));
      expect(draft.toSubmissionMap()['occasions'], ['wedding', 'church']);
    });
  });

  group('Measurements are traceable', () {
    test('source is recorded so an order ties back to a scan', () {
      final draft = fromProduct().copyWith(
        measurements: const CheckoutMeasurements(
          source: MeasurementSource.bodyScan,
          scanId: 'scan-7',
          values: {'chest': 40.5, 'waist': 34},
        ),
      );
      expect(draft.measurements.hasData, isTrue);
      expect(draft.measurements.fieldCount, 2);
      expect(draft.toSubmissionMap()['measurement_source'], 'body_scan');
      expect(draft.toSubmissionMap()['measurement_scan_id'], 'scan-7');
    });

    test('no measurements is a legitimate state, not an error', () {
      const draft = CheckoutMeasurements();
      expect(draft.hasData, isFalse);
      expect(draft.source, MeasurementSource.none);
    });

    test('measurement source round-trips through its db value', () {
      for (final s in MeasurementSource.values) {
        expect(MeasurementSource.fromName(s.storageValue), s);
      }
      expect(MeasurementSource.fromName('nope'), isNull);
    });

    test('the one multi-word source does not rely on Dart camelCase', () {
      // body_scan != bodyScan. The CHECK accepts only the snake_case form.
      expect(MeasurementSource.bodyScan.storageValue, 'body_scan');
      expect(MeasurementSource.bodyScan.storageValue,
          isNot(MeasurementSource.bodyScan.name));
    });
  });

  group('Submission payload', () {
    test('carries both entities and the request distinctly', () {
      final draft = fromProduct().copyWith(
        request: const CheckoutRequest(
          summary: 'Six of these for my brothers wedding',
        ),
        fabric: const CheckoutFabric(name: 'Linen', colour: 'Gold'),
        occasions: const ['wedding'],
        additionalNotes: 'Slim fit, no padding',
      );
      final map = draft.toSubmissionMap();
      // product-level
      expect(map['design_id'], 'design-1');
      // order/request-level
      expect(map['request_summary'], 'Six of these for my brothers wedding');
      expect(map['fabric_name'], 'Linen');
      expect(map['additional_notes'], 'Slim fit, no padding');
      expect(map['occasions'], ['wedding']);
    });
  });

  group('Equatable', () {
    test('drafts with different content are not equal', () {
      expect(fromProfile(), isNot(equals(fromProduct())));
      expect(
        fromProfile().copyWith(request: const CheckoutRequest(garmentType: 'A')),
        isNot(equals(
          fromProfile().copyWith(request: const CheckoutRequest(garmentType: 'B')),
        )),
      );
    });

    test('identical drafts are equal', () {
      expect(fromProfile(), fromProfile());
    });
  });
}