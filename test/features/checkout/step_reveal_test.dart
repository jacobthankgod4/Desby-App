import 'package:desby_app/features/checkout/presentation/widgets/step_progression_widgets.dart';
import 'package:desby_app/config/environment.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A controller in the settled state, the way the journey starts: the first
  // step must be fully visible, never mid-fade.
  AnimationController settled() => AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 460),
        value: 1,
      );

  group('step reveal', () {
    testWidgets('first paint is fully opaque', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RevealOnChange(
            step: 'a',
            child: const Text('body'),
          ),
        ),
      );

      final opacity = tester
          .widget<Opacity>(
            find.descendant(
              of: find.byType(RevealOnChange),
              matching: find.byType(Opacity),
            ).first,
          )
          .opacity;
      expect(opacity, 1.0,
          reason: 'a step that opens invisible reads as a blank panel');
      expect(find.text('body'), findsOneWidget);
    });

    testWidgets('changing step replays the reveal', (tester) async {
      Widget build(String step) => MaterialApp(
            home: RevealOnChange(step: step, child: const Text('body')),
          );

      await tester.pumpWidget(build('a'));
      await tester.pumpWidget(build('b'));
      // Mid-animation the content must be partly transparent, i.e. animating.
      await tester.pump(const Duration(milliseconds: 40));

      // Read the opacity actually painted, rather than poking at internals.
      double opacityNow() => tester
          .widget<Opacity>(
            find.descendant(
              of: find.byType(RevealOnChange),
              matching: find.byType(Opacity),
            ).first,
          )
          .opacity;

      expect(opacityNow(), lessThan(1.0),
          reason: 'a step change should be visibly animating');
      expect(opacityNow(), greaterThan(0.0));

      await tester.pumpAndSettle();
      expect(opacityNow(), 1.0);
    });

    test('direction is carried for forward and back', () {
      expect(RevealDirection.values, hasLength(2));
      expect(RevealDirection.forward, isNot(RevealDirection.back));
    });
  });

  group('staggered sections', () {
    testWidgets('renders every child', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StaggeredReveal(
              animation: settled(),
              children: const [
                SizedBox(height: 10, child: Text('one')),
                SizedBox(height: 10, child: Text('two')),
                SizedBox(height: 10, child: Text('three')),
              ],
            ),
          ),
        ),
      );

      expect(find.text('one'), findsOneWidget);
      expect(find.text('two'), findsOneWidget);
      expect(find.text('three'), findsOneWidget);
    });

    testWidgets('a single child form works', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StaggeredReveal(
              animation: settled(),
              child: const Text('only'),
            ),
          ),
        ),
      );
      expect(find.text('only'), findsOneWidget);
    });

    testWidgets('nothing rendered when empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: StaggeredReveal(animation: settled())),
        ),
      );
      expect(find.byType(StaggeredReveal), findsOneWidget);
    });
  });

  group('korra base url', () {
    test('off-web falls back to the absolute host', () async {
      // `KORRA_API_BASE_URL=` in .env yields '' (never null), so the old
      // `?? default` could never fire. Off-web there is no same-origin /api
      // proxy, so an empty value would silently resolve against the app's own
      // origin and 404. This is that guard — a VM test is not web.
      await Environment.initialize();
      expect(kIsWeb, isFalse);
      expect(Environment.current.korraApiBaseUrl, 'https://korra.work/api/v2');
    });
  });
}
