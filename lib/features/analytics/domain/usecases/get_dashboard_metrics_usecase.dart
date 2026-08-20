import '../entities/analytics_event.dart';
import '../services/analytics_service.dart';

class GetDashboardMetricsUsecase {
  final AnalyticsService service;
  GetDashboardMetricsUsecase(this.service);
  Future<List<BusinessMetric>> call(String userId) =>
      service.getDashboardMetrics(userId);
}
