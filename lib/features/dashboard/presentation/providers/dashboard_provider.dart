import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/usecases/dashboard_usecases.dart';
import '../../data/repositories/firebase_dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return FirebaseDashboardRepository();
});

final getDashboardStatsUsecaseProvider = Provider((ref) {
  return GetDashboardStatsUsecase(ref.watch(dashboardRepositoryProvider));
});

final getRecentOrdersUsecaseProvider = Provider((ref) {
  return GetRecentOrdersUsecase(ref.watch(dashboardRepositoryProvider));
});

final getRecentClientsUsecaseProvider = Provider((ref) {
  return GetRecentClientsUsecase(ref.watch(dashboardRepositoryProvider));
});

final dashboardStatsProvider = FutureProvider.family((ref, String userId) async {
  final usecase = ref.watch(getDashboardStatsUsecaseProvider);
  final result = await usecase(userId);
  return result.fold(
    (failure) => throw Exception(failure.toString()),
    (stats) => stats,
  );
});

final recentOrdersProvider = FutureProvider.family((ref, String userId) async {
  final usecase = ref.watch(getRecentOrdersUsecaseProvider);
  final result = await usecase(userId, limit: 10);
  return result.fold(
    (failure) => throw Exception(failure.toString()),
    (orders) => orders,
  );
});

final recentClientsProvider = FutureProvider.family((ref, String userId) async {
  final usecase = ref.watch(getRecentClientsUsecaseProvider);
  final result = await usecase(userId, limit: 5);
  return result.fold(
    (failure) => throw Exception(failure.toString()),
    (clients) => clients,
  );
});
