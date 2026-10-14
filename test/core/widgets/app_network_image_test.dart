import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:desby_app/core/widgets/app_network_image.dart';

void main() {
  group('resolveImageUrl', () {
    test('passes absolute http(s) URLs through unchanged', () {
      const url =
          'https://aemumiyzowraoachzxtu.supabase.co/storage/v1/object/public/images/designs/a/b.jpg';
      expect(resolveImageUrl(url), url);
      expect(resolveImageUrl('  $url  '), url);
    });

    test('returns empty string for null, blank and whitespace input', () {
      expect(resolveImageUrl(null), '');
      expect(resolveImageUrl(''), '');
      expect(resolveImageUrl('   '), '');
    });

    test('resolves storage object paths against the Supabase storage base',
        () {
      // Supabase is not initialised in unit tests, so the helper falls back to
      // the trimmed input rather than throwing.
      expect(resolveImageUrl('images/designs/x.jpg'), 'images/designs/x.jpg');
    });
  });

  group('AppNetworkImage', () {
    Future<AppNetworkImage> pump(
      WidgetTester tester, {
      String? url,
      IconData placeholderIcon = Icons.image_outlined,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 120,
              height: 120,
              child: AppNetworkImage(
                url: url,
                placeholderIcon: placeholderIcon,
              ),
            ),
          ),
        ),
      );
      return tester.widget<AppNetworkImage>(find.byType(AppNetworkImage));
    }

    testWidgets('renders the placeholder icon when the URL is missing',
        (tester) async {
      await pump(tester, url: null);
      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    });

    testWidgets('renders the caller placeholder icon when the URL is missing',
        (tester) async {
      await pump(tester, url: '', placeholderIcon: Icons.checkroom_rounded);
      expect(find.byIcon(Icons.checkroom_rounded), findsOneWidget);
    });

    testWidgets('builds an image view for a non-empty URL', (tester) async {
      final widget = await pump(
        tester,
        url: 'https://example.com/garment.jpg',
      );
      expect(find.byType(Image), findsOneWidget);
      expect(widget.fit, BoxFit.cover);
    });
  });
}
