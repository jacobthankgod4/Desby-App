import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/fabric.dart';

part 'fabric_model.freezed.dart';
part 'fabric_model.g.dart';

@freezed
class FabricVariantModel with _$FabricVariantModel {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory FabricVariantModel({
    String? id,
    required String colorName,
    String? colorCode,
    required double stockQuantity,
    String? imageUrl,
  }) = _FabricVariantModel;

  factory FabricVariantModel.fromJson(Map<String, dynamic> json) =>
      _$FabricVariantModelFromJson(json);

  factory FabricVariantModel.fromEntity(FabricVariant entity) => FabricVariantModel(
    id: entity.id,
    colorName: entity.colorName,
    colorCode: entity.colorCode,
    stockQuantity: entity.stockQuantity,
    imageUrl: entity.imageUrl,
  );
}

extension FabricVariantModelX on FabricVariantModel {
  FabricVariant toEntity() => FabricVariant(
    id: id,
    colorName: colorName,
    colorCode: colorCode,
    stockQuantity: stockQuantity,
    imageUrl: imageUrl,
  );
}

@freezed
class WholesaleTierModel with _$WholesaleTierModel {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory WholesaleTierModel({
    String? id,
    required double minQuantity,
    required double unitPrice,
  }) = _WholesaleTierModel;

  factory WholesaleTierModel.fromJson(Map<String, dynamic> json) =>
      _$WholesaleTierModelFromJson(json);

  factory WholesaleTierModel.fromEntity(WholesaleTier entity) => WholesaleTierModel(
    id: entity.id,
    minQuantity: entity.minQuantity,
    unitPrice: entity.unitPrice,
  );
}

extension WholesaleTierModelX on WholesaleTierModel {
  WholesaleTier toEntity() => WholesaleTier(
    id: id,
    minQuantity: minQuantity,
    unitPrice: unitPrice,
  );
}

@freezed
class FabricModel with _$FabricModel {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory FabricModel({
    required String id,
    required String name,
    required String category,
    required double pricePerYard,
    required double stockQuantity,
    required String sellerId,
    required List<String> imageUrls,
    String? composition,
    String? weight,
    String? origin,
    required List<String> availableColors,
    @Default([]) List<FabricVariantModel> variants,
    @Default([]) List<WholesaleTierModel> wholesaleTiers,
    @Default(true) bool isVisible,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _FabricModel;

  factory FabricModel.fromJson(Map<String, dynamic> json) =>
      _$FabricModelFromJson(json);

  factory FabricModel.fromEntity(Fabric fabric) => FabricModel(
    id: fabric.id,
    name: fabric.name,
    category: fabric.category,
    pricePerYard: fabric.pricePerYard,
    stockQuantity: fabric.stockQuantity,
    sellerId: fabric.sellerId,
    imageUrls: fabric.imageUrls,
    composition: fabric.composition,
    weight: fabric.weight,
    origin: fabric.origin,
    availableColors: fabric.availableColors,
    variants: fabric.variants.map((v) => FabricVariantModel.fromEntity(v)).toList(),
    wholesaleTiers: fabric.wholesaleTiers.map((t) => WholesaleTierModel.fromEntity(t)).toList(),
    isVisible: fabric.isVisible,
    createdAt: fabric.createdAt,
    updatedAt: fabric.updatedAt,
  );
}

extension FabricModelX on FabricModel {
  Fabric toEntity() => Fabric(
    id: id,
    name: name,
    category: category,
    pricePerYard: pricePerYard,
    stockQuantity: stockQuantity,
    sellerId: sellerId,
    imageUrls: imageUrls,
    composition: composition,
    weight: weight,
    origin: origin,
    availableColors: availableColors,
    variants: variants.map((v) => v.toEntity()).toList(),
    wholesaleTiers: wholesaleTiers.map((t) => t.toEntity()).toList(),
    isVisible: isVisible,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
