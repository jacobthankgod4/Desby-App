import '../../../../core/error/failures.dart';
import '../entities/apprenticeship.dart';
import '../entities/apprentice_task.dart';
import '../entities/apprentice_module.dart';

abstract class ApprenticeshipRepository {
  // Apprenticeship Management
  Future<Result<List<Apprenticeship>>> getApprenticeships(String tailorId);
  Future<Result<Apprenticeship?>> getApprenticeship(String apprenticeId);
  Future<Result<Apprenticeship>> createApprenticeship(
    Apprenticeship apprenticeship,
  );
  Future<Result<Apprenticeship>> updateApprenticeship(
    Apprenticeship apprenticeship,
  );

  // Invite System
  Future<Result<Apprenticeship?>> getApprenticeshipByInviteToken(String token);
  Future<Result<String>> generateInviteToken(String apprenticeshipId);

  // Task Management
  Future<Result<List<ApprenticeTask>>> getApprenticeTasks(
    String apprenticeshipId,
  );
  Future<Result<ApprenticeTask>> createTask(ApprenticeTask task);
  Future<Result<ApprenticeTask>> updateTask(ApprenticeTask task);

  // Curriculum - Read
  Future<Result<List<ApprenticeModule>>> getCurriculum();
  Future<Result<List<ApprenticeLesson>>> getLessons(String moduleId);
  Future<Result<ApprenticeLesson>> getLessonById(String lessonId);

  // Curriculum - Write
  Future<Result<ApprenticeModule>> createModule(
    String title,
    String description,
    int orderIndex, {
    String? tailorId,
  });
  Future<Result<ApprenticeModule>> updateModule(
    String moduleId, {
    String? title,
    String? description,
    int? orderIndex,
  });
  Future<Result<void>> deleteModule(String moduleId);
  Future<Result<void>> reorderModules(List<String> moduleIds);

  // Lessons - Write
  Future<Result<ApprenticeLesson>> createLesson(
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
  });
  Future<Result<ApprenticeLesson>> updateLesson(
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
  });
  Future<Result<void>> deleteLesson(String lessonId);
  Future<Result<void>> reorderLessons(String moduleId, List<String> lessonIds);

  // Lesson Progress
  Future<Result<void>> markLessonComplete(
    String apprenticeshipId,
    String lessonId,
  );
  Future<Result<Set<String>>> getCompletedLessons(String apprenticeshipId);
  Future<Result<double>> calculateProgress(String apprenticeshipId);
}
