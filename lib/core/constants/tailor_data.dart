/// Tailor services offered by tailors
class TailorServices {
  /// Basic services list
  static const List<String> all = [
    'Dress Making',
    'Suits & Blazers',
    'Native Wear',
    'Alterations',
    'Bridal & Groom Wear',
    'Corporate Attire',
    'Shirts & Trousers',
    'Fabrics & Sales',
  ];

  /// Detailed services for detailed view (with id, name, description)
  static const List<Map<String, String>> detailed = [
    {'id': '1', 'name': 'Dress Making', 'description': 'Create custom dresses for any occasion. From casual day dresses to elegant evening gowns.'},
    {'id': '2', 'name': 'Suits & Blazers', 'description': 'Professional suits and blazers tailored to perfection for corporate and formal events.'},
    {'id': '3', 'name': 'Native Wear', 'description': 'Traditional African wear including Agbada, Dashiki, native dresses, and more.'},
    {'id': '4', 'name': 'Alterations', 'description': 'Expert alterations to fit your existing clothes perfectly.'},
    {'id': '5', 'name': 'Bridal & Groom Wear', 'description': 'Beautiful wedding attire for the big day. Bridesmaids dresses and groom suits.'},
    {'id': '6', 'name': 'Corporate Attire', 'description': 'Professional办公 attire including work shirts, trousers, and office wear.'},
    {'id': '7', 'name': 'Shirts & Trousers', 'description': 'Custom shirts and trousers made to your measurements and style preferences.'},
    {'id': '8', 'name': 'Fabrics & Sales', 'description': 'Quality fabrics available for sale. We help you find the perfect material for your project.'},
  ];
}

/// Fabric types available for selection
class FabricTypes {
  /// All fabric types
  static const List<String> all = [
    'Ankara',
    'Aso Oke',
    'Lace',
    'Damask',
    'George',
    'Velvet',
    'Silk',
    'Cotton',
    'Java Print',
    'Kampala',
    'Guinea',
    'Wax Print',
    'Chempian',
    'Satins',
    'Organza',
    'Jacquard',
    'Crepe',
    'Tafetta',
    'Linen',
    'Denim',
  ];
}
