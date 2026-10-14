import 'dart:convert';

import 'package:desby_app/core/providers/navigation_provider.dart';
import 'package:desby_app/features/designs/domain/entities/design.dart';
import 'package:desby_app/features/tailor/domain/entities/shop_product.dart';
import 'package:flutter_test/flutter_test.dart';

Design _design(String id) {
  final now = DateTime.utc(2026, 1, 1);
  return Design(
    id: id,
    title: 'Test design',
    category: 'shirt',
    price: 42,
    tailorId: 't1',
    tailorName: 'Tailor',
    tailorAvatarUrl: null,
    tailorLocation: null,
    imageUrls: const [],
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('navigation argument persistence', () {
    test('stores a domain object as <key>Id and primitives verbatim', () {
      final encoded = encodeNavigationArgs({
        'design': _design('design-9'),
        'quantity': 2,
        'size': 'M',
        'colorValue': 0xFF1A1A2E,
      });

      final decoded =
          jsonDecode(encoded!) as Map<String, dynamic>;

      // The entity itself is NOT persisted — only its id.
      expect(decoded.containsKey('design'), isFalse);
      expect(decoded['designId'], 'design-9');

      // Primitives survive untouched.
      expect(decoded['quantity'], 2);
      expect(decoded['size'], 'M');
      expect(decoded['colorValue'], 0xFF1A1A2E);
    });

    test('stores an id-bearing entity the same way', () {
      final product = ShopProduct(
        id: 'p-1',
        tailorId: 't1',
        name: 'Shirt',
        price: 10,
        createdAt: DateTime.utc(2026, 1, 1),
      );
      final decoded =
          jsonDecode(encodeNavigationArgs({'product': product})!)
              as Map<String, dynamic>;
      expect(decoded['productId'], 'p-1');
      expect(decoded.containsKey('product'), isFalse);
    });

    test('persists nested argument bundles (the tailor map)', () {
      final decoded = jsonDecode(encodeNavigationArgs({
        'tailor': {
          'id': 't1',
          'name': 'Amaka',
          'rating': 4.8,
          'tags': ['tailor', 'menswear'],
        },
      })!) as Map<String, dynamic>;

      final tailor = decoded['tailor'] as Map<String, dynamic>;
      expect(tailor['id'], 't1');
      expect(tailor['name'], 'Amaka');
      expect(tailor['rating'], 4.8);
      expect(tailor['tags'], ['tailor', 'menswear']);
    });

    test('returns null for empty/null arguments so stale args get cleared', () {
      expect(encodeNavigationArgs(null), isNull);
      expect(encodeNavigationArgs(const {}), isNull);
    });

    test('drops unserialisable values instead of throwing', () {
      final decoded = jsonDecode(encodeNavigationArgs({
        'orderId': 'o-1',
        'handler': Object(),
      })!) as Map<String, dynamic>;
      expect(decoded['orderId'], 'o-1');
      expect(decoded.containsKey('handler'), isFalse);
    });

    test('decode tolerates corrupt/absent stored payloads', () {
      expect(decodeNavigationArgs(null), isNull);
      expect(decodeNavigationArgs(''), isNull);
      expect(decodeNavigationArgs('{not json'), isNull);
      final ok = decodeNavigationArgs('{"orderId":"o-9"}');
      expect(ok?['orderId'], 'o-9');
    });
  });
}