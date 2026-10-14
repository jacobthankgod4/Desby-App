import '../repositories/apprenticeship_repository.dart';
import '../../../../core/error/failures.dart';

class DeleteLessonUsecase {
  final ApprenticeshipRepository repository;
  DeleteLessonUsecase(this.repository);
  Future<Result<void>> call(String lessonId) =>
      repository.deleteLesson(lessonId);
}
