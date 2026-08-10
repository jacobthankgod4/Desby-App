/// Product entity for tailor shop items
class ShopProduct {
  final String id;
  final String tailorId;
  final String name;
  final String description;
  final double price;
  final String currency;
  final List<String> imageUrls;
  final String category;
  final List<String> availableFabrics;
  final List<String> availableSizes;
  final bool isVisible;
  final bool isAvailable;
  final int orderCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ShopProduct({
    required this.id,
    required this.tailorId,
    required this.name,
    this.description = '',
    required this.price,
    this.currency = 'NGN',
    this.imageUrls = const [],
    this.category = 'Custom',
    this.availableFabrics = const [],
    this.availableSizes = const [],
    this.isVisible = true,
    this.isAvailable = true,
    this.orderCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  ShopProduct copyWith({
    String? id,
    String? tailorId,
    String? name,
    String? description,
    double? price,
    String? currency,
    List<String>? imageUrls,
    String? category,
    List<String>? availableFabrics,
    List<String>? availableSizes,
    bool? isVisible,
    bool? isAvailable,
    int? orderCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShopProduct(
      id: id ?? this.id,
      tailorId: tailorId ?? this.tailorId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      imageUrls: imageUrls ?? this.imageUrls,
      category: category ?? this.category,
      availableFabrics: availableFabrics ?? this.availableFabrics,
      availableSizes: availableSizes ?? this.availableSizes,
      isVisible: isVisible ?? this.isVisible,
      isAvailable: isAvailable ?? this.isAvailable,
      orderCount: orderCount ?? this.orderCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tailor_id': tailorId,
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'image_urls': imageUrls,
      'category': category,
      'available_fabrics': availableFabrics,
      'available_sizes': availableSizes,
      'is_visible': isVisible,
      'is_available': isAvailable,
      'order_count': orderCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory ShopProduct.fromMap(Map<String, dynamic> map) {
    return ShopProduct(
      id: map['id'] as String? ?? '',
      tailorId: map['tailor_id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'NGN',
      imageUrls: (map['image_urls'] as List?)?.cast<String>() ?? [],
      category: map['category'] as String? ?? 'Custom',
      availableFabrics: (map['available_fabrics'] as List?)?.cast<String>() ?? [],
      availableSizes: (map['available_sizes'] as List?)?.cast<String>() ?? [],
      isVisible: map['is_visible'] as bool? ?? true,
      isAvailable: map['is_available'] as bool? ?? true,
      orderCount: map['order_count'] as int? ?? 0,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
    );
  }
}

/// Shop categories
class ShopCategory {
  static const String custom = 'Custom';
  static const String bridal = 'Bridal';
  static const String menswear = 'Menswear';
  static const String womenswear = 'Womenswear';
  static const String childrenswear = 'Childrenswear';
  static const String alteration = 'Alteration';
  static const String accessories = 'Accessories';

  static List<String> get all => [
    custom,
    bridal,
    menswear,
    womenswear,
    childrenswear,
    alteration,
    accessories,
  ];
}
