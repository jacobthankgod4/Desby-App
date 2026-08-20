import '../../../../core/error/failures.dart';
import '../entities/apprenticeship.dart';
import '../repositories/apprenticeship_repository.dart';

class GetTailorApprenticeshipsUsecase {
  final ApprenticeshipRepository repository;
  GetTailorApprenticeshipsUsecase(this.repository);
  Future<Result<List<Apprenticeship>>> call(String tailorId) =>
      repository.getApprenticeships(tailorId);
}
