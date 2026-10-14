import 'package:desby_app/features/checkout/domain/entities/checkout_draft.dart';
import 'package:desby_app/features/marketplace/domain/entities/fabric.dart';

/// Vocabulary for the guided request journey.
///
/// Every list here is a *suggestion*, never a constraint: the client can always
/// type something the catalogue does not have, because a tailor who cannot get
/// the exact cloth will tell the client rather than silently substituting it.
class RequestOptions {
  RequestOptions._();

  /// Grouped by how the client is most likely to arrive. The legacy flow
  /// hardcoded `_selectedGender = 'Male'` and only ever offered male garments,
  /// so a woman could not describe a dress at all.
  static const Map<String, List<String>> garmentsByGroup = {
    'Traditional menswear': [
      'Agbada',
      'Senator',
      'Kaftan',
      'Suit',
      'Traditional shirt',
      'Wrapper',
    ],
    'Traditional womenswear': [
      'Gown',
      'Ankara',
      'Aso ebi',
      'Buba',
      'Blouse & skirt',
      'Boubou',
    ],
    'Contemporary': [
      'Shirt',
      'Trousers',
      'Dress',
      'Jacket',
      'Jumpsuit',
      'Two-piece set',
    ],
  };

  /// Flat, stable order — used by tests and by the review summary.
  static List<String> get allGarments =>
      garmentsByGroup.values.expand((g) => g).toList(growable: false);

  /// Style direction. Chosen as chips rather than a text box because the client
  /// recognises these words; "describe your style" is the wrong question.
  static const List<String> styleTags = [
    'Traditional',
    'Modern',
    'Minimalist',
    'Bold',
    'Classic',
    'Contemporary',
    'Corporate',
    'Regal',
  ];

  static const List<String> fitPreferences = [
    'Slim',
    'Regular',
    'Relaxed',
    'Tailored',
    'Oversized',
  ];

  /// Multi-select. A request really can be for a wedding AND a church service.
  static const List<String> occasions = [
    'Wedding',
    'Traditional ceremony',
    'Church',
    'Party',
    'Corporate',
    'Casual',
    'Graduation',
    'Naming ceremony',
  ];

  /// Fallback fabric list, shown only when the catalogue returns nothing. The
  /// legacy flow offered four hardcoded fabrics with invented prices and no link
  /// to the real `fabrics` table at all.
  static const List<String> fabricSuggestions = [
    'Cotton',
    'Linen',
    'Wool',
    'Silk',
    'Lace',
    'Velvet',
    'Denim',
    'Chiffon',
    'Brocade',
    'Adire',
  ];

  static const List<String> colourSuggestions = [
    'Black',
    'Navy',
    'White',
    'Ivory',
    'Wine',
    'Gold',
    'Silver',
    'Emerald',
    'Royal blue',
    'Rose',
  ];

  /// How a catalogue fabric maps onto the draft.
  static CheckoutFabric toDraftFabric(Fabric fabric) => CheckoutFabric(
        fabricId: fabric.id,
        name: fabric.name,
      );

  /// Parse a raw row from the `fabrics` table without pulling in the whole
  /// entity. The catalogue provider is stream-backed and the journey only needs
  /// three fields, so this keeps the step decoupled from marketplace internals.
  static CheckoutFabric? fromRow(Map<String, dynamic> row) {
    final id = row['id']?.toString();
    final name = row['name']?.toString();
    if (id == null || name == null || name.trim().isEmpty) return null;
    return CheckoutFabric(fabricId: id, name: name);
  }
}
