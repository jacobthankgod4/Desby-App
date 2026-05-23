import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/apprenticeship.dart';
import '../../domain/entities/apprentice_task.dart';
import '../../domain/entities/apprentice_module.dart';
import '../../domain/repositories/apprenticeship_repository.dart';
import '../../data/repositories/firebase_apprenticeship_repository.dart';

// Repository Provider
final apprenticeshipRepositoryProvider = Provider<ApprenticeshipRepository>((ref) {
  return FirebaseApprenticeshipRepository();
});

// Apprenticeships for a Tailor
final tailorApprenticeshipsProvider = FutureProvider.family<List<Apprenticeship>, String>((ref, tailorId) async {
  final repository = ref.watch(apprenticeshipRepositoryProvider);
  final result = await repository.getApprenticeships(tailorId);
  return result.fold(
    (failure) => throw failure,
    (apprenticeships) => apprenticeships,
  );
});

// Single Apprenticeship for an Apprentice
final apprenticeApprenticeshipProvider = FutureProvider.family<Apprenticeship?, String>((ref, apprenticeId) async {
  final repository = ref.watch(apprenticeshipRepositoryProvider);
  final result = await repository.getApprenticeship(apprenticeId);
  return result.fold(
    (failure) => throw failure,
    (apprenticeship) => apprenticeship,
  );
});

// Tasks for an Apprenticeship
final apprenticeshipTasksProvider = FutureProvider.family<List<ApprenticeTask>, String>((ref, apprenticeshipId) async {
  final repository = ref.watch(apprenticeshipRepositoryProvider);
  final result = await repository.getApprenticeTasks(apprenticeshipId);
  return result.fold(
    (failure) => throw failure,
    (tasks) => tasks,
  );
});

// Curriculum Provider
final curriculumProvider = FutureProvider<List<ApprenticeModule>>((ref) async {
  final repository = ref.watch(apprenticeshipRepositoryProvider);
  final result = await repository.getCurriculum();
  return result.fold(
    (failure) => throw failure,
    (modules) => modules,
  );
});

// Lessons Provider
final moduleLessonsProvider = FutureProvider.family<List<ApprenticeLesson>, String>((ref, moduleId) async {
  final repository = ref.watch(apprenticeshipRepositoryProvider);
  final result = await repository.getLessons(moduleId);
  return result.fold(
    (failure) => throw failure,
    (lessons) => lessons,
  );
});

// Single Lesson Detail Provider
final lessonDetailProvider = FutureProvider.family<ApprenticeLesson, String>((ref, lessonId) async {
  final repository = ref.watch(apprenticeshipRepositoryProvider);
  final result = await repository.getLessonById(lessonId);
  return result.fold(
    (failure) => throw failure,
    (lesson) => lesson,
  );
});
