import '../../../../core/error/failures.dart';
import '../entities/apprenticeship.dart';
import '../repositories/apprenticeship_repository.dart';

class GetApprenticeApprenticeshipUsecase {
  final ApprenticeshipRepository repository;
  GetApprenticeApprenticeshipUsecase(this.repository);
  Future<Result<Apprenticeship?>> call(String apprenticeId) =>
      repository.getApprenticeship(apprenticeId);
}
