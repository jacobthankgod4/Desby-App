import '../../../../core/error/failures.dart';
import '../entities/apprentice_task.dart';
import '../repositories/apprenticeship_repository.dart';

class GetApprenticeTasksUsecase {
  final ApprenticeshipRepository repository;
  GetApprenticeTasksUsecase(this.repository);
  Future<Result<List<ApprenticeTask>>> call(String apprenticeshipId) =>
      repository.getApprenticeTasks(apprenticeshipId);
}
