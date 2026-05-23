import 'package:cloud_firestore/cloud_firestore.dart';

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
      'tailorId': tailorId,
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'imageUrls': imageUrls,
      'category': category,
      'availableFabrics': availableFabrics,
      'availableSizes': availableSizes,
      'isVisible': isVisible,
      'isAvailable': isAvailable,
      'orderCount': orderCount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory ShopProduct.fromMap(Map<String, dynamic> map) {
    return ShopProduct(
      id: map['id'] as String? ?? '',
      tailorId: map['tailorId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'NGN',
      imageUrls: (map['imageUrls'] as List?)?.cast<String>() ?? [],
      category: map['category'] as String? ?? 'Custom',
      availableFabrics: (map['availableFabrics'] as List?)?.cast<String>() ?? [],
      availableSizes: (map['availableSizes'] as List?)?.cast<String>() ?? [],
      isVisible: map['isVisible'] as bool? ?? true,
      isAvailable: map['isAvailable'] as bool? ?? true,
      orderCount: map['orderCount'] as int? ?? 0,
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : (map['createdAt'] is String)
              ? DateTime.parse(map['createdAt'] as String)
              : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] is Timestamp)
              ? (map['updatedAt'] as Timestamp).toDate()
              : DateTime.tryParse(map['updatedAt'] as String)
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
