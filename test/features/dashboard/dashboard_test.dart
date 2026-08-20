import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:desby_app/core/error/failures.dart';
import 'package:desby_app/features/dashboard/domain/entities/dashboard_stats.dart';
import 'package:desby_app/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:desby_app/features/dashboard/domain/usecases/dashboard_usecases.dart';

@GenerateMocks([DashboardRepository])
import 'dashboard_test.mocks.dart';

void main() {
  late GetDashboardStatsUsecase usecase;
  late MockDashboardRepository mockRepository;

  setUp(() {
    mockRepository = MockDashboardRepository();
    usecase = GetDashboardStatsUsecase(mockRepository);
    provideDummy<Result<DashboardStats>>(Failure(ServerFailure(message: 'dummy')));
  });

  final tStats = DashboardStats(
    totalOrders: 10,
    pendingOrders: 3,
    completedOrders: 7,
    totalRevenue: 5000.0,
    totalClients: 25,
    urgentDeadlines: 2,
    totalApprentices: 2,
    fabricInventoryLevel: 0.75,
    growthPercentage: 15.5,
    unreadMessages: 5,
    lastUpdated: DateTime(2024),
  );

  group('GetDashboardStatsUsecase', () {
    test('should return DashboardStats when repository call succeeds', () async {
      when(mockRepository.getDashboardStats(any))
          .thenAnswer((_) async => Success(tStats));

      final result = await usecase('user1');

      expect(result, isA<Success>());
      result.fold(
        (failure) => fail('Should not return failure'),
        (stats) => expect(stats.totalOrders, 10),
      );
      verify(mockRepository.getDashboardStats('user1')).called(1);
    });

    test('should return Failure when repository call fails', () async {
      when(mockRepository.getDashboardStats(any))
          .thenAnswer((_) async => Failure(ServerFailure(message: 'Server error')));

      final result = await usecase('user1');

      expect(result, isA<Failure>());
      result.fold(
        (failure) => expect(failure.message, 'Server error'),
        (_) => fail('Should not return success'),
      );
    });
  });
}
