import 'dart:math' as math;

import 'package:desby_app/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the contrast fixes on the tailor profile.
///
/// The brand amber (#FFC107) is a *background* accent. Used as text or an icon
/// on a light surface it measured 1.63:1 on white and 1.32:1 on a light border,
/// which is why the profile's Call/Route/Chat/Share icons and its expertise
/// chips were effectively invisible in light mode. These tests pin the tokens
/// that replaced it so a future "simplification" back to raw amber fails here
/// rather than in someone's eyes.
/// WCAG 2.x relative luminance.
double _relativeLuminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double contrastRatio(Color a, Color b) {
  final la = _relativeLuminance(a);
  final lb = _relativeLuminance(b);
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// Flatten a translucent colour onto an opaque backdrop, because contrast is
/// only meaningful for what the eye actually sees.
Color _over(Color fg, Color bg) {
  final a = fg.a;
  return Color.from(
    alpha: 1,
    red: fg.r * a + bg.r * (1 - a),
    green: fg.g * a + bg.g * (1 - a),
    blue: fg.b * a + bg.b * (1 - a),
  );
}

void main() {
  const aaText = 4.5;
  const aaNonText = 3.0;

  Widget wrap(Brightness brightness, Widget Function() build) => MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: Builder(
          builder: (context) => build(),
        ),
      );

  Future<DesbyThemeColors> colorsFor(
    WidgetTester tester,
    Brightness brightness,
  ) async {
    DesbyThemeColors? captured;
    await tester.pumpWidget(wrap(brightness, () {
      return Builder(
        builder: (context) {
          captured = context.colors;
          return const SizedBox.shrink();
        },
      );
    }));
    final result = captured;
    expect(result, isNotNull, reason: 'no BuildContext was pumped');
    return result!;
  }

  group('accentOnSurface', () {
    testWidgets('is readable on a light card', (tester) async {
      final colors = await colorsFor(tester, Brightness.light);
      expect(contrastRatio(colors.accentOnSurface, colors.surface),
          greaterThanOrEqualTo(aaText));
    });

    testWidgets('is readable on a light button fill', (tester) async {
      final colors = await colorsFor(tester, Brightness.light);
      // Icons are non-text, but these are small glyphs next to a label, so the
      // stricter text threshold is the honest bar.
      expect(contrastRatio(colors.accentOnSurface, colors.interactiveFill),
          greaterThanOrEqualTo(aaText));
    });

    testWidgets('is readable on the tinted chip fill in light mode',
        (tester) async {
      final colors = await colorsFor(tester, Brightness.light);
      final chipBg = _over(colors.accentSubtleFill, colors.surface);
      expect(contrastRatio(colors.accentOnSubtleFill, chipBg),
          greaterThanOrEqualTo(aaText));
    });

    testWidgets('is readable against the page beside it in light mode',
        (tester) async {
      // Not the 1px border: a border is a hairline and is never a text or icon
      // backdrop. The realistic adjacent surface is the page the tile sits on.
      final colors = await colorsFor(tester, Brightness.light);
      expect(contrastRatio(colors.accentOnSurface, colors.scaffoldBg),
          greaterThanOrEqualTo(aaNonText));
    });

    testWidgets('stays readable in dark mode', (tester) async {
      final colors = await colorsFor(tester, Brightness.dark);
      expect(contrastRatio(colors.accentOnSurface, colors.scaffoldBg),
          greaterThanOrEqualTo(aaText));
    });
  });

  group('interactive rows', () {
    testWidgets('fill is distinguishable from the border in dark mode',
        (tester) async {
      // Previously fill and border were both white@5%, a 1.02:1 difference:
      // the row existed but you could not see its edges.
      final colors = await colorsFor(tester, Brightness.dark);
      final fill = _over(colors.interactiveFill, colors.scaffoldBg);
      final border = _over(colors.interactiveBorder, colors.scaffoldBg);
      expect(contrastRatio(fill, border), greaterThan(1.4));
    });

    testWidgets('light mode clears 3:1 between the border and the fill',
        (tester) async {
      // Light mode has the dynamic range to meet 1.4.11 for the tile edge, so
      // it does. Dark mode cannot against a near-black background — see the
      // note on interactiveBorder.
      final colors = await colorsFor(tester, Brightness.light);
      final fill = _over(colors.interactiveFill, colors.scaffoldBg);
      final border = _over(colors.interactiveBorder, colors.scaffoldBg);
      expect(contrastRatio(border, fill), greaterThanOrEqualTo(aaNonText));
    });

    testWidgets('the tile fill differs from the page behind it',
        (tester) async {
      final colors = await colorsFor(tester, Brightness.light);
      final fill = _over(colors.interactiveFill, colors.scaffoldBg);
      expect(fill, isNot(equals(colors.scaffoldBg)));
    });
  });

  group('raw brand amber is not used as a light-mode foreground', () {
    testWidgets('would fail, which is why the token exists', (tester) async {
      final colors = await colorsFor(tester, Brightness.light);
      final rawAmber = contrastRatio(AppColors.amber, colors.surface);
      final token = contrastRatio(colors.accentOnSurface, colors.surface);

      // Documents the regression we are protecting against.
      expect(rawAmber, lessThan(aaNonText));
      expect(token, greaterThan(rawAmber));
    });
  });
}
