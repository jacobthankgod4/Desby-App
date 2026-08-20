import '../../../../core/error/failures.dart';
import '../entities/apprentice_module.dart';
import '../repositories/apprenticeship_repository.dart';

class GetCurriculumUsecase {
  final ApprenticeshipRepository repository;
  GetCurriculumUsecase(this.repository);
  Future<Result<List<ApprenticeModule>>> call() => repository.getCurriculum();
}
