import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/fabric.dart';

part 'fabric_model.freezed.dart';
part 'fabric_model.g.dart';

@freezed
class FabricModel with _$FabricModel {
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
    isVisible: isVisible,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
