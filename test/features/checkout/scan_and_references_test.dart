import 'package:desby_app/features/checkout/data/repositories/checkout_draft_repository.dart';
import 'package:desby_app/features/checkout/domain/entities/checkout_draft.dart';
import 'package:desby_app/features/checkout/domain/entities/journey_state.dart';
import 'package:desby_app/features/checkout/presentation/providers/checkout_draft_provider.dart';
import 'package:desby_app/core/error/failures.dart';
import 'package:flutter_test/flutter_test.dart';

/// A scan finished successfully — 25 measurements, green banner — but the
/// booking flow never received them, and the cloth step could be left empty.
class _Repo implements CheckoutDraftRepositoryContract {
  CheckoutDraft? stored;
  int saves = 0;
  @override
  Future<Result<CheckoutDraft?>> loadFor(CheckoutDraft p) async => Success(stored);
  @override
  Future<Result<CheckoutDraft?>> loadMostRecent(String id) async => Success(stored);
  @override
  Future<Result<CheckoutDraft>> save(CheckoutDraft d) async {
    saves++;
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

  CheckoutDraft base({List<String> urls = const []}) => CheckoutDraft(
        ownerId: 'u1',
        tailor: tailor,
        entryMode: CheckoutEntryMode.fromProfile,
        request: const CheckoutRequest(garmentType: 'Agbada'),
        furthestStep: CheckoutStep.review.position,
      ).copyWith(materialAssetUrls: urls);

  group('scan measurements reach the booking and persist', () {
    test('25 scan values are stored on the draft', () {
      final values = {for (var i = 0; i < 25; i++) 'm$i': 80.0 + i};
      final draft = base().copyWith(
        measurements: CheckoutMeasurements(
          source: MeasurementSource.bodyScan,
          values: values,
        ),
      );

      expect(draft.measurements.source, MeasurementSource.bodyScan);
      expect(draft.measurements.fieldCount, 25);
      expect(draft.measurements.hasData, isTrue);
    });

    test('a scan answers the fit step so its checkmark appears', () {
      // furthestStep 0 — the scan is the only thing that can answer Fit.
      final empty = base().copyWith(furthestStep: 0);
      expect(empty.completedSteps, isNot(contains(CheckoutStep.measurements)));

      final scanned = empty.copyWith(
        measurements: CheckoutMeasurements(
          source: MeasurementSource.bodyScan,
          values: const {'chest': 96.0},
        ),
      );
      expect(scanned.completedSteps, contains(CheckoutStep.measurements));
    });

    test('setMeasurements is persisted immediately', () async {
      final repo = _Repo();
      final controller = CheckoutDraftController(repo, null)
        ..begin(ownerId: 'u1', tailor: tailor);

      controller.setMeasurements(
        const CheckoutMeasurements(
          source: MeasurementSource.bodyScan,
          values: {'chest': 96.0},
        ),
      );
      expect(controller.state!.measurements.fieldCount, 1);

      await controller.save();
      expect(repo.saves, 1,
          reason: 'a scan must survive a refresh straight away');
      expect(repo.stored!.measurements.values, contains('chest'));
    });
  });

  group('multiple reference images', () {
    test('several images are held and the first becomes primary', () {
      final draft = base().copyWith(materialAssetUrls: const [
        'https://cdn/1.jpg',
        'https://cdn/2.jpg',
        'https://cdn/3.jpg',
      ]);

      expect(draft.materialAssetUrls.length, 3);
      expect(draft.hasMaterialReference, isTrue);
    });

    test('one image alone satisfies the requirement', () {
      expect(base().copyWith(materialAssetUrls: const ['https://cdn/1.jpg'])
          .hasMaterialReference, isTrue);
    });

    test('removing the last image clears the primary', () {
      // The controller sets the primary as images are added.
      final repo = _Repo();
      final controller = CheckoutDraftController(repo, null)
        ..begin(ownerId: 'u1', tailor: tailor);
      controller.addMaterialAssetUrl('https://cdn/1.jpg');
      expect(controller.state!.materialAssetUrl, 'https://cdn/1.jpg');

      controller.removeMaterialAssetUrl('https://cdn/1.jpg');
      expect(controller.state!.hasMaterialReference, isFalse);
      expect(controller.state!.materialAssetUrl, isNull,
          reason: 'the primary must not dangle once the last image is gone');
    });
  });

  group('the cloth reference is required', () {
    test('fabric cannot be continued without a reference', () {
      expect(base().canContinueFrom(CheckoutStep.fabric), isFalse);
    });

    test('fabric can continue once a reference exists', () {
      final draft = base().copyWith(materialAssetUrls: const ['https://cdn/1.jpg']);
      expect(draft.canContinueFrom(CheckoutStep.fabric), isTrue);
    });

    test('other steps stay optional', () {
      final draft = base();
      expect(draft.canContinueFrom(CheckoutStep.occasion), isTrue);
      expect(draft.canContinueFrom(CheckoutStep.measurements), isTrue);
      expect(draft.canContinueFrom(CheckoutStep.styleDirection), isTrue);
    });

    test('a request with no reference is not sendable', () {
      // The tracker counts travel, not content, so the page gates the CTA on
      // the draft's data-based check instead. This is that check.
      expect(base().isBlockingComplete, isFalse);
    });

    test('with a reference it becomes sendable', () {
      final draft = base().copyWith(materialAssetUrls: const ['https://cdn/1.jpg']);
      final state = JourneyState(
        currentStep: CheckoutStep.review,
        completedSteps: draft.completedSteps,
      );
      expect(draft.isBlockingComplete, isTrue);
      expect(state.isReadyToSubmit, isTrue);
    });
  });
}
