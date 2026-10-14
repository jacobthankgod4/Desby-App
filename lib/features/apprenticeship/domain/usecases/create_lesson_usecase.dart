import '../entities/apprentice_module.dart';
import '../repositories/apprenticeship_repository.dart';
import '../../../../core/error/failures.dart';

class CreateLessonUsecase {
  final ApprenticeshipRepository repository;
  CreateLessonUsecase(this.repository);
  Future<Result<ApprenticeLesson>> call(
    String moduleId,
    String title,
    String content,
    int orderIndex, {
    String? videoUrl,
    String? shortDescription,
    String? thumbnailUrl,
    int? durationMinutes,
    String? lessonType,
    bool? isPublished,
    bool? isFreePreview,
    List<String>? attachments,
  }) => repository.createLesson(
    moduleId,
    title,
    content,
    orderIndex,
    videoUrl: videoUrl,
    shortDescription: shortDescription,
    thumbnailUrl: thumbnailUrl,
    durationMinutes: durationMinutes,
    lessonType: lessonType,
    isPublished: isPublished,
    isFreePreview: isFreePreview,
    attachments: attachments,
  );
}
