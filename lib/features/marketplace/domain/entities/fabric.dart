import 'package:equatable/equatable.dart';

class FabricVariant extends Equatable {
  final String? id;
  final String colorName;
  final String? colorCode;
  final double stockQuantity;
  final String? imageUrl;

  const FabricVariant({
    this.id,
    required this.colorName,
    this.colorCode,
    required this.stockQuantity,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [id, colorName, colorCode, stockQuantity, imageUrl];

  FabricVariant copyWith({
    String? id,
    String? colorName,
    String? colorCode,
    double? stockQuantity,
    String? imageUrl,
  }) {
    return FabricVariant(
      id: id ?? this.id,
      colorName: colorName ?? this.colorName,
      colorCode: colorCode ?? this.colorCode,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

class WholesaleTier extends Equatable {
  final String? id;
  final double minQuantity;
  final double unitPrice;

  const WholesaleTier({
    this.id,
    required this.minQuantity,
    required this.unitPrice,
  });

  @override
  List<Object?> get props => [id, minQuantity, unitPrice];
}

class Fabric extends Equatable {
  final String id;
  final String name;
  final String category;
  final double pricePerYard;
  final double stockQuantity;
  final String sellerId;
  final List<String> imageUrls;
  
  // Professional Metadata
  final String? composition; // e.g. 100% Cotton
  final String? weight; // e.g. 200gsm
  final String? origin; // e.g. Milan, IT
  final List<String> availableColors;
  
  // Advanced Features
  final List<FabricVariant> variants;
  final List<WholesaleTier> wholesaleTiers;

  final bool isVisible;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Fabric({
    required this.id,
    required this.name,
    required this.category,
    required this.pricePerYard,
    required this.stockQuantity,
    required this.sellerId,
    required this.imageUrls,
    this.composition,
    this.weight,
    this.origin,
    required this.availableColors,
    this.variants = const [],
    this.wholesaleTiers = const [],
    this.isVisible = true,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id, name, category, pricePerYard, stockQuantity, sellerId, 
    imageUrls, composition, weight, origin, availableColors, 
    variants, wholesaleTiers, isVisible, createdAt, updatedAt
  ];

  Fabric copyWith({
    String? id,
    String? name,
    String? category,
    double? pricePerYard,
    double? stockQuantity,
    String? sellerId,
    List<String>? imageUrls,
    String? composition,
    String? weight,
    String? origin,
    List<String>? availableColors,
    List<FabricVariant>? variants,
    List<WholesaleTier>? wholesaleTiers,
    bool? isVisible,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Fabric(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      pricePerYard: pricePerYard ?? this.pricePerYard,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      sellerId: sellerId ?? this.sellerId,
      imageUrls: imageUrls ?? this.imageUrls,
      composition: composition ?? this.composition,
      weight: weight ?? this.weight,
      origin: origin ?? this.origin,
      availableColors: availableColors ?? this.availableColors,
      variants: variants ?? this.variants,
      wholesaleTiers: wholesaleTiers ?? this.wholesaleTiers,
      isVisible: isVisible ?? this.isVisible,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
