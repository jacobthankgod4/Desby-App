import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:desby_app/core/error/failures.dart';
import 'package:desby_app/features/apprenticeship/domain/entities/apprenticeship.dart';
import 'package:desby_app/features/apprenticeship/domain/entities/apprentice_task.dart';
import 'package:desby_app/features/apprenticeship/domain/entities/apprentice_module.dart';
import 'package:desby_app/features/apprenticeship/domain/repositories/apprenticeship_repository.dart';
import 'package:desby_app/features/apprenticeship/domain/usecases/get_tailor_apprenticeships_usecase.dart';
import 'package:desby_app/features/apprenticeship/domain/usecases/get_curriculum_usecase.dart';
import 'package:desby_app/features/apprenticeship/domain/usecases/get_apprentice_tasks_usecase.dart';

@GenerateMocks([ApprenticeshipRepository])
import 'tailor_test.mocks.dart';

void main() {
  late GetTailorApprenticeshipsUsecase getApprenticeships;
  late GetCurriculumUsecase getCurriculum;
  late GetApprenticeTasksUsecase getTasks;
  late MockApprenticeshipRepository mockRepo;

  setUp(() {
    mockRepo = MockApprenticeshipRepository();
    getApprenticeships = GetTailorApprenticeshipsUsecase(mockRepo);
    getCurriculum = GetCurriculumUsecase(mockRepo);
    getTasks = GetApprenticeTasksUsecase(mockRepo);
    provideDummy<Result<List<Apprenticeship>>>(Failure(ServerFailure(message: 'dummy')));
    provideDummy<Result<List<ApprenticeModule>>>(Failure(ServerFailure(message: 'dummy')));
    provideDummy<Result<List<ApprenticeTask>>>(Failure(ServerFailure(message: 'dummy')));
  });

  final tApprenticeship = Apprenticeship(
    id: 'app_1',
    tailorId: 'tailor_1',
    apprenticeId: 'apprentice_1',
    status: ApprenticeshipStatus.active,
    progress: 0.5,
    startDate: DateTime(2024),
  );

  final tTask = ApprenticeTask(
    id: 'task_1',
    apprenticeshipId: 'app_1',
    title: 'Learn pattern cutting',
    description: 'Master basic pattern cutting techniques',
    status: ApprenticeTaskStatus.todo,
    dueDate: DateTime(2024, 12, 31),
  );

  final tModule = ApprenticeModule(
    id: 'mod_1',
    title: 'Introduction to Tailoring',
    description: 'Learn the basics',
    orderIndex: 1,
  );

  group('GetTailorApprenticeshipsUsecase', () {
    test('should return list of apprenticeships', () async {
      when(mockRepo.getApprenticeships('tailor_1'))
          .thenAnswer((_) async => Success([tApprenticeship]));

      final result = await getApprenticeships('tailor_1');

      expect(result, isA<Success>());
      result.fold(
        (failure) => fail('Should not return failure'),
        (list) => expect(list.length, 1),
      );
    });

    test('should return Failure on error', () async {
      when(mockRepo.getApprenticeships('tailor_1'))
          .thenAnswer((_) async => Failure(ServerFailure(message: 'DB error')));

      final result = await getApprenticeships('tailor_1');

      expect(result, isA<Failure>());
    });
  });

  group('GetCurriculumUsecase', () {
    test('should return list of modules', () async {
      when(mockRepo.getCurriculum())
          .thenAnswer((_) async => Success([tModule]));

      final result = await getCurriculum();

      expect(result, isA<Success>());
      result.fold(
        (failure) => fail('Should not return failure'),
        (modules) => expect(modules.length, 1),
      );
    });
  });

  group('GetApprenticeTasksUsecase', () {
    test('should return list of tasks', () async {
      when(mockRepo.getApprenticeTasks('app_1'))
          .thenAnswer((_) async => Success([tTask]));

      final result = await getTasks('app_1');

      expect(result, isA<Success>());
      result.fold(
        (failure) => fail('Should not return failure'),
        (tasks) => expect(tasks.length, 1),
      );
    });
  });
}
