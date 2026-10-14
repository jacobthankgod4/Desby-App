import 'package:flutter_test/flutter_test.dart';

import 'package:desby_app/features/designs/data/models/design_model.dart';

void main() {
  /// Row shape mirrors a live record from the `designs` table
  /// (project aemumiyzowraoachzxtu, fetched 2026-10-03).
  Map<String, dynamic> liveRow() => {
        'id': '4619f3c1-6669-4328-b4ab-22d5f4fae273',
        'title': 'Executive Suit Collection',
        'category': 'SUITS',
        'price': 120000,
        'tailor_id': 'de22b802-4e72-4ac3-a9cd-c4c4a8b0fdb4',
        'tailor_name': 'Mulberry Studio',
        'tailor_avatar_url': null,
        'image_urls': [
          'https://aemumiyzowraoachzxtu.supabase.co/storage/v1/object/public/images/designs/a/suit.jpg',
        ],
        'description': null,
        'gender': 'male',
        'likes_count': 98,
        'is_featured': true,
        'is_visible': true,
        'created_at': '2026-08-21T16:08:03.230734+00:00',
        'updated_at': '2026-08-21T16:08:03.230734+00:00',
        'tailor_location': 'Enugu',
        'tailor_state': 'Enugu',
        'tailor_lga': 'Enugu North',
        'tailor_order_count': 14,
        'tailor_rating': 4.7,
        'tailor_review_count': 9,
      };

  group('DesignModel', () {
    test('parses a live designs row', () {
      final model = DesignModel.fromJson(liveRow());

      expect(model.id, '4619f3c1-6669-4328-b4ab-22d5f4fae273');
      expect(model.price, 120000);
      expect(model.imageUrls, hasLength(1));
      expect(model.updatedAt.toIso8601String(), startsWith('2026-08-21'));
    });

    test('tolerates a row that is missing optional fields', () {
      final row = liveRow()
        ..remove('description')
        ..remove('tailor_avatar_url')
        ..remove('tailor_rating');
      final model = DesignModel.fromJson(row);

      expect(model.description, isNull);
      expect(model.tailorRating, 0.0);
    });
  });

  group('parseDesignRows', () {
    test('keeps valid rows when one row is malformed', () {
      final rows = <dynamic>[
        liveRow(),
        {'id': 'broken', 'title': 'no required fields'},
        liveRow()..['id'] = 'second-valid',
      ];

      final designs = parseDesignRows(rows);

      expect(designs, hasLength(2));
      expect(designs.map((d) => d.id), containsAll(['4619f3c1-6669-4328-b4ab-22d5f4fae273', 'second-valid']));
    });

    test('returns an empty list for empty input', () {
      expect(parseDesignRows(const []), isEmpty);
    });
  });
}
