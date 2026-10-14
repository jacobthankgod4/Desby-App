import 'package:desby_app/features/checkout/data/repositories/checkout_draft_repository.dart';
import 'package:desby_app/features/checkout/domain/entities/checkout_draft.dart';
import 'package:desby_app/features/checkout/presentation/providers/checkout_draft_provider.dart';
import 'package:desby_app/features/checkout/presentation/widgets/progress_tracker.dart';
import 'package:desby_app/features/checkout/presentation/widgets/request_steps.dart';
import 'package:desby_app/features/checkout/presentation/widgets/step_progression_widgets.dart';
import 'package:desby_app/features/checkout/domain/entities/journey_state.dart';
import 'package:desby_app/core/error/failures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

/// Builds the notifier OUTSIDE the widget tree so no provider is mutated
/// during build.
Widget wrap(Widget child, {CheckoutTailor? tailor, CheckoutProduct? product}) {
  final controller = CheckoutDraftController(_Repo(), null)
    ..begin(ownerId: 'u1', tailor: tailor, product: product);
  return ProviderScope(
    overrides: [
      checkoutDraftRepositoryProvider.overrideWithValue(_Repo()),
      checkoutDraftControllerProvider.overrideWith((ref) => controller),
    ],
    // Mirrors production: the journey hosts each step inside its scroll view,
    // and the step bodies are plain columns.
    child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    ),
  );
}

void main() {
  const tailor = CheckoutTailor(id: 't1', name: 'Mulberry Studio');

  testWidgets('step 1 asks what to sew — the panel must not be blank',
      (tester) async {
    await tester.pumpWidget(wrap(const DefineRequestStep(), tailor: tailor));
    await tester.pump();
    expect(find.textContaining('make for you'), findsOneWidget);
    expect(find.text('Agbada'), findsWidgets,
        reason: 'garment choices must be visible');
  });

  testWidgets('a product entry shows the design instead of asking which one',
      (tester) async {
    await tester.pumpWidget(wrap(
      const DefineRequestStep(),
      tailor: tailor,
      product: const CheckoutProduct(
        designId: 'd1',
        title: 'Premium Kaftan',
        category: 'KAFTAN',
        selectedSize: '54',
      ),
    ));
    await tester.pump();
    expect(find.text('Premium Kaftan'), findsOneWidget);
    expect(find.text('Make this design as shown'), findsOneWidget);
  });

  testWidgets('style step renders its question', (tester) async {
    await tester.pumpWidget(wrap(const StyleDirectionStep(), tailor: tailor));
    await tester.pump();
    expect(find.textContaining('What should it look like'), findsOneWidget);
  });

  testWidgets('occasion step renders', (tester) async {
    await tester.pumpWidget(wrap(const OccasionStep(), tailor: tailor));
    await tester.pump();
    expect(find.textContaining('Where will it be worn'), findsOneWidget);
  });

  testWidgets('active header shows the counter and the title', (tester) async {
    await tester.pumpWidget(wrap(
      const ActiveStepHeader(
        state: JourneyState(),
        title: 'Define the request',
        purpose: 'Tell the tailor what to make.',
      ),
      tailor: tailor,
    ));
    await tester.pump();
    expect(find.text('STEP 1 OF 6'), findsOneWidget);
    expect(find.text('Define the request'), findsOneWidget);
  });

  testWidgets('completed summary renders one line plus an edit affordance',
      (tester) async {
    final controller = CheckoutDraftController(_Repo(), null)
      ..begin(ownerId: 'u1', tailor: tailor)
      ..setRequest(const CheckoutRequest(garmentType: 'Agbada'));
    await tester.pumpWidget(ProviderScope(
      overrides: [
        checkoutDraftRepositoryProvider.overrideWithValue(_Repo()),
        checkoutDraftControllerProvider.overrideWith((ref) => controller),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: CompletedStepSummary(
            step: CheckoutStep.defineRequest,
            draft: controller.state!,
            onEdit: () {},
          ),
        ),
      ),
    ));
    await tester.pump();
    expect(find.text('DEFINE THE REQUEST'), findsOneWidget);
    expect(find.text('Agbada'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
  });

  testWidgets('the first step is painted at full opacity, never mid-fade',
      (tester) async {
    // Regression: the body sat inside an AnimatedSwitcher, which renders its
    // first child at opacity 0. When that fade did not run (it did not after
    // the tour closed) the header showed and the whole step body was invisible.
    await tester.pumpWidget(wrap(
      const RevealOnChange(
        step: CheckoutStep.defineRequest,
        child: DefineRequestStep(),
      ),
      tailor: tailor,
    ));
    await tester.pump();

    final body = tester.widgetList<FadeTransition>(find.byType(FadeTransition));
    for (final t in body) {
      expect(t.opacity.value, 1.0,
          reason: 'the active step must be fully opaque on first build');
    }
    // And the content must actually be on screen and hittable.
    expect(find.text('Agbada'), findsWidgets);
    expect(find.byType(SelectionChip), findsWidgets);
  });

  testWidgets('a step body renders inside the journey scroll view',
      (tester) async {
    // The real regression: every step body returned its own ListView and the
    // page wraps them in a ListView. A vertical scrollable nested in an unbounded
    // vertical scrollable collapses to zero height — the header rendered and the
    // whole input area was invisible, so Continue complained about fields the
    // client could not see.
    final controller = CheckoutDraftController(_Repo(), null)
      ..begin(ownerId: 'u1', tailor: tailor);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        checkoutDraftRepositoryProvider.overrideWithValue(_Repo()),
        checkoutDraftControllerProvider.overrideWith((ref) => controller),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ListView(
            children: const [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text('STEP 1 OF 6'),
              ),
              DefineRequestStep(),
            ],
          ),
        ),
      ),
    ));
    await tester.pump();

    expect(find.text('Agbada'), findsWidgets,
        reason: 'garment choices must be visible inside the page scroll view');
    expect(find.text('Tell them in your own words'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget,
        reason: 'the free-text input must exist, not just be declared');

    // And it must actually have a real size on screen, not zero height.
    final size = tester.getSize(find.byType(SelectionChip).first);
    expect(size.height, greaterThan(20), reason: 'chips must have real height');
  });

  testWidgets('step bodies contain no nested scroll view of their own',
      (tester) async {
    // Guard: a ListView here would silently collapse again inside the journey.
    for (final widget in <Widget>[
      const DefineRequestStep(),
      const StyleDirectionStep(),
      const OccasionStep(),
    ]) {
      await tester.pumpWidget(wrap(widget, tailor: tailor));
      await tester.pump();
      expect(find.byType(ListView), findsNothing,
          reason: '${widget.runtimeType} must not create its own scroll view');
    }
  });

  testWidgets('step labels are legible, not 10px whispers', (tester) async {
    // Regression: the rail rendered step names at caption size and grey, which
    // users reported as unreadable. Lock in a real floor.
    final controller = CheckoutDraftController(_Repo(), null)
      ..begin(ownerId: 'u1', tailor: tailor);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        checkoutDraftRepositoryProvider.overrideWithValue(_Repo()),
        checkoutDraftControllerProvider.overrideWith((ref) => controller),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ProgressTracker(
            state: JourneyState(),
            draft: controller.state!,
            onJump: (_) {},
          ),
        ),
      ),
    ));
    await tester.pump();

    final stepNames = ['Define the request', 'Style direction', 'Fabric'];
    for (final name in stepNames) {
      final finder = find.text(name);
      expect(finder, findsOneWidget, reason: '$name must be visible');
      final style = tester.widget<Text>(finder).style!;
      expect(style.fontSize, greaterThanOrEqualTo(14),
          reason: '$name is ${style.fontSize}px — too small');
      expect(style.fontWeight, anyOf(FontWeight.w500, FontWeight.w700, FontWeight.w800),
          reason: '$name must not be light weight');
    }
  });

  testWidgets('no step text is rendered below a legibility floor',
      (tester) async {
    await tester.pumpWidget(wrap(const StyleDirectionStep(), tailor: tailor));
    await tester.pump();
    final sizes = <double>[];
    for (final el in find.byType(Text).evaluate()) {
      final t = el.widget as Text;
      if (t.style?.fontSize != null) sizes.add(t.style!.fontSize!);
    }
    expect(sizes, isNotEmpty);
    // Headings and labels must be readable, not 10px whispers.
    expect(sizes.where((s) => s >= 13).length, greaterThanOrEqualTo(3),
        reason: 'found sizes: $sizes');
  });
}
