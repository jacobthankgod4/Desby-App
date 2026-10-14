import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/design.dart';

part 'design_model.freezed.dart';
part 'design_model.g.dart';

@freezed
class DesignModel with _$DesignModel {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory DesignModel({
    required String id,
    required String title,
    required String category,
    required double price,
    required String tailorId,
    required String tailorName,
    String? tailorAvatarUrl,
    String? tailorLocation,
    String? tailorState,
    String? tailorLga,
    @Default(0) int tailorOrderCount,
    @Default(0.0) double tailorRating,
    @Default(0) int tailorReviewCount,
    required List<String> imageUrls,
    String? description,
    @Default('unisex') String gender,
    @Default(0) int likesCount,
    @Default(false) bool isFeatured,
    @Default(true) bool isVisible,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _DesignModel;

  factory DesignModel.fromJson(Map<String, dynamic> json) =>
      _$DesignModelFromJson(json);

  factory DesignModel.fromEntity(Design entity) => DesignModel(
    id: entity.id,
    title: entity.title,
    category: entity.category,
    price: entity.price,
    tailorId: entity.tailorId,
    tailorName: entity.tailorName,
    tailorAvatarUrl: entity.tailorAvatarUrl,
    tailorLocation: entity.tailorLocation,
    tailorState: entity.tailorState,
    tailorLga: entity.tailorLga,
    tailorOrderCount: entity.tailorOrderCount,
    tailorRating: entity.tailorRating,
    tailorReviewCount: entity.tailorReviewCount,
    imageUrls: entity.imageUrls,
    description: entity.description,
    gender: entity.gender,
    likesCount: entity.likesCount,
    isFeatured: entity.isFeatured,
    isVisible: entity.isVisible,
    createdAt: entity.createdAt,
    updatedAt: entity.updatedAt,
  );
}

extension DesignModelX on DesignModel {
  Design toEntity() => Design(
    id: id,
    title: title,
    category: category,
    price: price,
    tailorId: tailorId,
    tailorName: tailorName,
    tailorAvatarUrl: tailorAvatarUrl,
    tailorLocation: tailorLocation,
    tailorState: tailorState,
    tailorLga: tailorLga,
    tailorOrderCount: tailorOrderCount,
    tailorRating: tailorRating,
    tailorReviewCount: tailorReviewCount,
    imageUrls: imageUrls,
    description: description,
    gender: gender,
    likesCount: likesCount,
    isFeatured: isFeatured,
    isVisible: isVisible,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

/// Parses raw `designs` rows leniently: a single malformed record is logged and
/// skipped instead of throwing away the whole feed (the strict freezed parser
/// throws on the first bad row, which used to blank out entire sections).
List<Design> parseDesignRows(Iterable<dynamic> rows) {
  final designs = <Design>[];
  for (final row in rows) {
    try {
      designs.add(DesignModel.fromJson(row as Map<String, dynamic>).toEntity());
    } catch (e) {
      debugPrint('[DESIGN_MODEL] skipping malformed row: $e');
    }
  }
  return designs;
}
