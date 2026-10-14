import '../repositories/apprenticeship_repository.dart';
import '../../../../core/error/failures.dart';

class ReorderModulesUsecase {
  final ApprenticeshipRepository repository;
  ReorderModulesUsecase(this.repository);
  Future<Result<void>> call(List<String> moduleIds) =>
      repository.reorderModules(moduleIds);
}
