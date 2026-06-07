import 'package:freezed_annotation/freezed_annotation.dart';

part 'ready_to_wear_garment.freezed.dart';
part 'ready_to_wear_garment.g.dart';

/// Ready-to-Wear Garment entity for favorites
/// Represents completed garments posted by tailors that users can save
@freezed
class ReadyToWearGarment with _$ReadyToWearGarment {
  const factory ReadyToWearGarment({
    required String id,
    required String tailorId,
    required String tailorName,
    required String imageUrl,
    required String garmentType,
    String? description,
    required double price,
    @Default([]) List<String> tags,
    required DateTime createdAt,
    @Default(true) bool isAvailable,
    String? category,
  }) = _ReadyToWearGarment;

  factory ReadyToWearGarment.fromJson(Map<String, dynamic> json) =>
      _$ReadyToWearGarmentFromJson(json);
}
