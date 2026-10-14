import 'package:equatable/equatable.dart';

class ApprenticeModule extends Equatable {
  final String id;
  final String title;
  final String description;
  final List<String> lessonIds;
  final int orderIndex;
  final String? masterclassThumbnail;
  final String? tailorId;

  const ApprenticeModule({
    required this.id,
    required this.title,
    required this.description,
    this.lessonIds = const [],
    required this.orderIndex,
    this.masterclassThumbnail,
    this.tailorId,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    lessonIds,
    orderIndex,
    masterclassThumbnail,
    tailorId,
  ];
}

class ApprenticeLesson extends Equatable {
  final String id;
  final String moduleId;
  final String title;
  final String content;
  final String? shortDescription;
  final String? videoUrl;
  final String? thumbnailUrl;
  final int? durationMinutes;
  final String lessonType;
  final bool isPublished;
  final bool isFreePreview;
  final List<String> attachments;
  final int orderIndex;

  const ApprenticeLesson({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.content,
    this.shortDescription,
    this.videoUrl,
    this.thumbnailUrl,
    this.durationMinutes,
    this.lessonType = 'video',
    this.isPublished = true,
    this.isFreePreview = false,
    this.attachments = const [],
    required this.orderIndex,
  });

  @override
  List<Object?> get props => [
    id,
    moduleId,
    title,
    content,
    shortDescription,
    videoUrl,
    thumbnailUrl,
    durationMinutes,
    lessonType,
    isPublished,
    isFreePreview,
    attachments,
    orderIndex,
  ];
}
