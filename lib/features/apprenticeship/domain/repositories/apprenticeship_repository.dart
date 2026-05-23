import '../../../../core/error/failures.dart';
import '../entities/apprenticeship.dart';
import '../entities/apprentice_task.dart';
import '../entities/apprentice_module.dart';

abstract class ApprenticeshipRepository {
  // Apprenticeship Management
  Future<Result<List<Apprenticeship>>> getApprenticeships(String tailorId);
  Future<Result<Apprenticeship?>> getApprenticeship(String apprenticeId);
  Future<Result<Apprenticeship>> createApprenticeship(Apprenticeship apprenticeship);
  Future<Result<Apprenticeship>> updateApprenticeship(Apprenticeship apprenticeship);
  
  // Task Management
  Future<Result<List<ApprenticeTask>>> getApprenticeTasks(String apprenticeshipId);
  Future<Result<ApprenticeTask>> createTask(ApprenticeTask task);
  Future<Result<ApprenticeTask>> updateTask(ApprenticeTask task);
  
  // Curriculum
  Future<Result<List<ApprenticeModule>>> getCurriculum();
  Future<Result<List<ApprenticeLesson>>> getLessons(String moduleId);
  Future<Result<ApprenticeLesson>> getLessonById(String lessonId);
}
