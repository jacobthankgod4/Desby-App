import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/apprenticeship.dart';
import '../../domain/entities/apprentice_task.dart';
import '../../domain/entities/apprentice_module.dart';
import '../../domain/repositories/apprenticeship_repository.dart';
import '../../domain/usecases/get_tailor_apprenticeships_usecase.dart';
import '../../domain/usecases/get_apprentice_apprenticeship_usecase.dart';
import '../../domain/usecases/get_apprentice_tasks_usecase.dart';
import '../../domain/usecases/get_curriculum_usecase.dart';
import '../../domain/usecases/get_module_lessons_usecase.dart';
import '../../domain/usecases/get_lesson_detail_usecase.dart';
import '../../data/repositories/supabase_apprenticeship_repository.dart';

final apprenticeshipRepositoryProvider = Provider<ApprenticeshipRepository>((ref) {
  return SupabaseApprenticeshipRepository();
});

final getTailorApprenticeshipsUsecaseProvider = Provider<GetTailorApprenticeshipsUsecase>((ref) {
  return GetTailorApprenticeshipsUsecase(ref.watch(apprenticeshipRepositoryProvider));
});

final getApprenticeApprenticeshipUsecaseProvider = Provider<GetApprenticeApprenticeshipUsecase>((ref) {
  return GetApprenticeApprenticeshipUsecase(ref.watch(apprenticeshipRepositoryProvider));
});

final getApprenticeTasksUsecaseProvider = Provider<GetApprenticeTasksUsecase>((ref) {
  return GetApprenticeTasksUsecase(ref.watch(apprenticeshipRepositoryProvider));
});

final getCurriculumUsecaseProvider = Provider<GetCurriculumUsecase>((ref) {
  return GetCurriculumUsecase(ref.watch(apprenticeshipRepositoryProvider));
});

final getModuleLessonsUsecaseProvider = Provider<GetModuleLessonsUsecase>((ref) {
  return GetModuleLessonsUsecase(ref.watch(apprenticeshipRepositoryProvider));
});

final getLessonDetailUsecaseProvider = Provider<GetLessonDetailUsecase>((ref) {
  return GetLessonDetailUsecase(ref.watch(apprenticeshipRepositoryProvider));
});

final tailorApprenticeshipsProvider = FutureProvider.family<List<Apprenticeship>, String>((ref, tailorId) async {
  final usecase = ref.watch(getTailorApprenticeshipsUsecaseProvider);
  final result = await usecase(tailorId);
  return result.fold(
    (failure) => throw failure,
    (apprenticeships) => apprenticeships,
  );
});

final apprenticeApprenticeshipProvider = FutureProvider.family<Apprenticeship?, String>((ref, apprenticeId) async {
  final usecase = ref.watch(getApprenticeApprenticeshipUsecaseProvider);
  final result = await usecase(apprenticeId);
  return result.fold(
    (failure) => throw failure,
    (apprenticeship) => apprenticeship,
  );
});

final apprenticeshipTasksProvider = FutureProvider.family<List<ApprenticeTask>, String>((ref, apprenticeshipId) async {
  final usecase = ref.watch(getApprenticeTasksUsecaseProvider);
  final result = await usecase(apprenticeshipId);
  return result.fold(
    (failure) => throw failure,
    (tasks) => tasks,
  );
});

final curriculumProvider = FutureProvider<List<ApprenticeModule>>((ref) async {
  final usecase = ref.watch(getCurriculumUsecaseProvider);
  final result = await usecase();
  return result.fold(
    (failure) => throw failure,
    (modules) => modules,
  );
});

final moduleLessonsProvider = FutureProvider.family<List<ApprenticeLesson>, String>((ref, moduleId) async {
  final usecase = ref.watch(getModuleLessonsUsecaseProvider);
  final result = await usecase(moduleId);
  return result.fold(
    (failure) => throw failure,
    (lessons) => lessons,
  );
});

final lessonDetailProvider = FutureProvider.family<ApprenticeLesson, String>((ref, lessonId) async {
  final usecase = ref.watch(getLessonDetailUsecaseProvider);
  final result = await usecase(lessonId);
  return result.fold(
    (failure) => throw failure,
    (lesson) => lesson,
  );
});
