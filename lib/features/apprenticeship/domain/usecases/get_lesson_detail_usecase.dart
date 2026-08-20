import '../../../../core/error/failures.dart';
import '../entities/apprentice_module.dart';
import '../repositories/apprenticeship_repository.dart';

class GetLessonDetailUsecase {
  final ApprenticeshipRepository repository;
  GetLessonDetailUsecase(this.repository);
  Future<Result<ApprenticeLesson>> call(String lessonId) =>
      repository.getLessonById(lessonId);
}
