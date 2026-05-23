import 'package:equatable/equatable.dart';

class ApprenticeModule extends Equatable {
  final String id;
  final String title;
  final String description;
  final List<String> lessonIds;
  final int orderIndex;
  final String? masterclassThumbnail; // Added for video visual entry

  const ApprenticeModule({
    required this.id,
    required this.title,
    required this.description,
    this.lessonIds = const [],
    required this.orderIndex,
    this.masterclassThumbnail,
  });

  @override
  List<Object?> get props => [id, title, description, lessonIds, orderIndex, masterclassThumbnail];
}

class ApprenticeLesson extends Equatable {
  final String id;
  final String moduleId;
  final String title;
  final String content; 
  final String? videoUrl; // The master's process video
  final int orderIndex;

  const ApprenticeLesson({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.content,
    this.videoUrl,
    required this.orderIndex,
  });

  @override
  List<Object?> get props => [id, moduleId, title, content, videoUrl, orderIndex];
}
