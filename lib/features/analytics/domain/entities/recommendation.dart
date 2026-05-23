import 'package:equatable/equatable.dart';

enum RecommendationType {
  design,
  fabric,
  pricing,
  marketing
}

class Recommendation extends Equatable {
  final String id;
  final String title;
  final String description;
  final RecommendationType type;
  final double confidenceScore;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;

  const Recommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.confidenceScore,
    this.imageUrl,
    this.metadata,
  });

  @override
  List<Object?> get props => [id, title, description, type, confidenceScore, imageUrl, metadata];
}
