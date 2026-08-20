import '../services/analytics_service.dart';

class GetOrderCategoryDistributionUsecase {
  final AnalyticsService service;
  GetOrderCategoryDistributionUsecase(this.service);
  Future<Map<String, int>> call(String userId) =>
      service.getOrderCategoryDistribution(userId);
}
