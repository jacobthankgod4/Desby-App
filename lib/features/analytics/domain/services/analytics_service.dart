import '../entities/analytics_event.dart';

abstract class AnalyticsService {
  Future<void> logEvent(AnalyticsEvent event);
  Future<void> setUserProperty(String name, String value);
  Future<List<BusinessMetric>> getDashboardMetrics(String userId);
  Future<Map<String, dynamic>> getRevenueReport(String userId, DateTime start, DateTime end);
}
