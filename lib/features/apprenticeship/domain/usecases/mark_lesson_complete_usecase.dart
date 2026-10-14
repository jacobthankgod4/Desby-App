import '../repositories/apprenticeship_repository.dart';
import '../../../../core/error/failures.dart';

class MarkLessonCompleteUsecase {
  final ApprenticeshipRepository repository;
  MarkLessonCompleteUsecase(this.repository);
  Future<Result<void>> call(String apprenticeshipId, String lessonId) =>
      repository.markLessonComplete(apprenticeshipId, lessonId);
}
