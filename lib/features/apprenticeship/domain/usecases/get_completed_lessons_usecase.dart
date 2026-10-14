import '../repositories/apprenticeship_repository.dart';
import '../../../../core/error/failures.dart';

class GetCompletedLessonsUsecase {
  final ApprenticeshipRepository repository;
  GetCompletedLessonsUsecase(this.repository);
  Future<Result<Set<String>>> call(String apprenticeshipId) =>
      repository.getCompletedLessons(apprenticeshipId);
}
