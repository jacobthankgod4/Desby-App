import '../repositories/apprenticeship_repository.dart';
import '../../../../core/error/failures.dart';

class DeleteModuleUsecase {
  final ApprenticeshipRepository repository;
  DeleteModuleUsecase(this.repository);
  Future<Result<void>> call(String moduleId) =>
      repository.deleteModule(moduleId);
}
