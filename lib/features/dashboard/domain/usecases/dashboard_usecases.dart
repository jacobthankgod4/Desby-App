import '../../../../core/error/failures.dart';
import '../entities/dashboard_stats.dart';
import '../repositories/dashboard_repository.dart';

class GetDashboardStatsUsecase {
  final DashboardRepository repository;
  GetDashboardStatsUsecase(this.repository);
  Future<Result<DashboardStats>> call(String userId) => 
    repository.getDashboardStats(userId);
}

class GetRecentOrdersUsecase {
  final DashboardRepository repository;
  GetRecentOrdersUsecase(this.repository);
  Future<Result<List<dynamic>>> call(String userId, {int limit = 10}) => 
    repository.getRecentOrders(userId, limit: limit);
}

class GetRecentClientsUsecase {
  final DashboardRepository repository;
  GetRecentClientsUsecase(this.repository);
  Future<Result<List<dynamic>>> call(String userId, {int limit = 5}) => 
    repository.getRecentClients(userId, limit: limit);
}
