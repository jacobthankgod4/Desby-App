import '../services/analytics_service.dart';

class GetBusinessInsightsUsecase {
  final AnalyticsService service;
  GetBusinessInsightsUsecase(this.service);
  Future<Map<String, dynamic>> call(String userId) =>
      service.getBusinessInsights(userId);
}
