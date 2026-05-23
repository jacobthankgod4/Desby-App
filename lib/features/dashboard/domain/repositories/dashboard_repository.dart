import '../../../../core/error/failures.dart';
import '../entities/dashboard_stats.dart';

abstract class DashboardRepository {
  Future<Result<DashboardStats>> getDashboardStats(String userId);
  Future<Result<List<dynamic>>> getRecentOrders(String userId, {int limit = 10});
  Future<Result<List<dynamic>>> getRecentClients(String userId, {int limit = 5});
}
