import 'package:equatable/equatable.dart';

class Design extends Equatable {
  final String id;
  final String title;
  final String category;
  final double price;
  final String tailorId;
  final String tailorName;
  final String? tailorAvatarUrl;
  final String? tailorLocation;
  final String? tailorState;
  final String? tailorLga;
  final int tailorOrderCount;
  final double tailorRating;
  final int tailorReviewCount;
  final List<String> imageUrls;
  final String? description;
  final String gender;
  final int likesCount;
  final bool isFeatured;
  final bool isVisible;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Design({
    required this.id,
    required this.title,
    required this.category,
    required this.price,
    required this.tailorId,
    required this.tailorName,
    this.tailorAvatarUrl,
    this.tailorLocation,
    this.tailorState,
    this.tailorLga,
    this.tailorOrderCount = 0,
    this.tailorRating = 0.0,
    this.tailorReviewCount = 0,
    required this.imageUrls,
    this.description,
    this.gender = 'unisex',
    this.likesCount = 0,
    this.isFeatured = false,
    this.isVisible = true,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    category,
    price,
    tailorId,
    tailorName,
    tailorAvatarUrl,
    tailorLocation,
    tailorState,
    tailorLga,
    tailorOrderCount,
    tailorRating,
    tailorReviewCount,
    imageUrls,
    description,
    gender,
    likesCount,
    isFeatured,
    isVisible,
    createdAt,
    updatedAt,
  ];

  Design copyWith({
    String? id,
    String? title,
    String? category,
    double? price,
    String? tailorId,
    String? tailorName,
    String? tailorAvatarUrl,
    String? tailorLocation,
    String? tailorState,
    String? tailorLga,
    int? tailorOrderCount,
    double? tailorRating,
    int? tailorReviewCount,
    List<String>? imageUrls,
    String? description,
    String? gender,
    int? likesCount,
    bool? isFeatured,
    bool? isVisible,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Design(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      price: price ?? this.price,
      tailorId: tailorId ?? this.tailorId,
      tailorName: tailorName ?? this.tailorName,
      tailorAvatarUrl: tailorAvatarUrl ?? this.tailorAvatarUrl,
      tailorLocation: tailorLocation ?? this.tailorLocation,
      tailorState: tailorState ?? this.tailorState,
      tailorLga: tailorLga ?? this.tailorLga,
      tailorOrderCount: tailorOrderCount ?? this.tailorOrderCount,
      tailorRating: tailorRating ?? this.tailorRating,
      tailorReviewCount: tailorReviewCount ?? this.tailorReviewCount,
      imageUrls: imageUrls ?? this.imageUrls,
      description: description ?? this.description,
      gender: gender ?? this.gender,
      likesCount: likesCount ?? this.likesCount,
      isFeatured: isFeatured ?? this.isFeatured,
      isVisible: isVisible ?? this.isVisible,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
