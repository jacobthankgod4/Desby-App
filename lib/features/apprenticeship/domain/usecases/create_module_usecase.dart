import '../entities/apprentice_module.dart';
import '../repositories/apprenticeship_repository.dart';
import '../../../../core/error/failures.dart';

class CreateModuleUsecase {
  final ApprenticeshipRepository repository;
  CreateModuleUsecase(this.repository);
  Future<Result<ApprenticeModule>> call(
    String title,
    String description,
    int orderIndex, {
    String? tailorId,
  }) => repository.createModule(
    title,
    description,
    orderIndex,
    tailorId: tailorId,
  );
}
