import '../entities/apprentice_module.dart';
import '../repositories/apprenticeship_repository.dart';
import '../../../../core/error/failures.dart';

class UpdateLessonUsecase {
  final ApprenticeshipRepository repository;
  UpdateLessonUsecase(this.repository);
  Future<Result<ApprenticeLesson>> call(
    String lessonId, {
    String? title,
    String? content,
    String? videoUrl,
    int? orderIndex,
    String? shortDescription,
    String? thumbnailUrl,
    int? durationMinutes,
    String? lessonType,
    bool? isPublished,
    bool? isFreePreview,
    List<String>? attachments,
  }) => repository.updateLesson(
    lessonId,
    title: title,
    content: content,
    videoUrl: videoUrl,
    orderIndex: orderIndex,
    shortDescription: shortDescription,
    thumbnailUrl: thumbnailUrl,
    durationMinutes: durationMinutes,
    lessonType: lessonType,
    isPublished: isPublished,
    isFreePreview: isFreePreview,
    attachments: attachments,
  );
}
