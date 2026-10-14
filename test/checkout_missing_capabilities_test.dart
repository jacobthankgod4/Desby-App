import 'package:desby_app/features/checkout/domain/entities/checkout_draft.dart';
import 'package:desby_app/features/checkout/presentation/providers/checkout_draft_provider.dart';
import 'package:desby_app/features/checkout/presentation/widgets/fabric_and_fit_steps.dart';
import 'package:desby_app/features/orders/presentation/widgets/body_scan_picker_widget.dart';
import 'package:desby_app/features/checkout/presentation/widgets/review_step.dart';
import 'package:desby_app/core/error/failures.dart';
import 'package:desby_app/features/checkout/data/repositories/checkout_draft_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Regression cover for the four capabilities that already existed in the legacy
// order flow but were missing from the guided flow: body scan, cloth reference,
// delivery, and an indicative price.
class _Repo implements CheckoutDraftRepositoryContract {
  @override
  Future<Result<CheckoutDraft?>> loadFor(CheckoutDraft probe) async =>
      const Success(null);
  @override
  Future<Result<CheckoutDraft?>> loadMostRecent(String id) async =>
      const Success(null);
  @override
  Future<Result<CheckoutDraft>> save(CheckoutDraft d) async => Success(d);
  @override
  Future<Result<void>> discard(CheckoutDraft d) async => const Success(null);
}

/// Builds the notifier OUTSIDE the tree so no provider is mutated during build,
/// matching test/features/checkout/step_render_test.dart.
Widget wrap(Widget child) {
  final controller = CheckoutDraftController(_Repo(), null)
    ..begin(ownerId: 'u1');
  return ProviderScope(
    overrides: [
      checkoutDraftRepositoryProvider.overrideWithValue(_Repo()),
      checkoutDraftControllerProvider.overrideWith((ref) => controller),
    ],
    child: MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

/// The steps lay out for desktop first; the default 800x600 test viewport makes
/// the chip rows overflow. Tests that render steps widen the surface.
void _wide(WidgetTester tester) {
  tester.view.physicalSize = const Size(1600, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  group('guided flow regressions', () {
    testWidgets('measurements step offers a body scan', (tester) async {
      _wide(tester);
      await tester.pumpWidget(wrap(const MeasurementsStep()));
      await tester.pump();

      // The scan picker must be present on the measurements step, and the host
      // must own how it is presented. (Copy assertions are unstable here: with
      // no Supabase the picker sits in its loading state.)
      expect(find.byType(BodyScanPickerWidget), findsOneWidget);
    });

    testWidgets('fabric step offers a cloth reference upload', (tester) async {
      await tester.pumpWidget(wrap(const FabricStep()));
      await tester.pump();

      expect(find.text('Show your tailor what you mean'), findsOneWidget);
      expect(find.textContaining('Add at least one photo of the cloth'), findsOneWidget);
    });

    testWidgets('review covers delivery and does not promise a price',
        (tester) async {
      await tester.pumpWidget(
        wrap(ReviewStep(onEdit: (_) {}, onSubmit: () async {})),
      );
      await tester.pump();

      expect(find.text('Where should it be delivered?'), findsOneWidget);
      expect(find.text('INDICATIVE COST'), findsOneWidget);
      // Never imply a guaranteed price.
      expect(find.textContaining('not a quote'), findsOneWidget);
      // The client never picks the courier — the tailor arranges collection.
      expect(find.textContaining('Your tailor arranges the collection'),
          findsOneWidget);
    });

    test('draft persists the reference and delivery address', () {
      final draft = const CheckoutDraft(ownerId: 'u1').copyWith(
        materialAssetUrl: 'https://cdn.example/material.jpg',
        deliveryAddress: '12 Allen Avenue, Ikeja, Lagos',
      );

      expect(draft.materialAssetUrl, 'https://cdn.example/material.jpg');
      expect(draft.deliveryAddress, contains('Ikeja'));
    });
  });
}
