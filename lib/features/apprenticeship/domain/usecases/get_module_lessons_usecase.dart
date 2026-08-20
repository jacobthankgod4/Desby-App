import '../../../../core/error/failures.dart';
import '../entities/apprentice_module.dart';
import '../repositories/apprenticeship_repository.dart';

class GetModuleLessonsUsecase {
  final ApprenticeshipRepository repository;
  GetModuleLessonsUsecase(this.repository);
  Future<Result<List<ApprenticeLesson>>> call(String moduleId) =>
      repository.getLessons(moduleId);
}
