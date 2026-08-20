import '../services/analytics_service.dart';

class GetMonthlyRevenueUsecase {
  final AnalyticsService service;
  GetMonthlyRevenueUsecase(this.service);
  Future<List<Map<String, dynamic>>> call(String userId) =>
      service.getMonthlyRevenue(userId);
}
