import '../entities/apprentice_module.dart';
import '../repositories/apprenticeship_repository.dart';
import '../../../../core/error/failures.dart';

class UpdateModuleUsecase {
  final ApprenticeshipRepository repository;
  UpdateModuleUsecase(this.repository);
  Future<Result<ApprenticeModule>> call(
    String moduleId, {
    String? title,
    String? description,
    int? orderIndex,
  }) => repository.updateModule(
    moduleId,
    title: title,
    description: description,
    orderIndex: orderIndex,
  );
}
