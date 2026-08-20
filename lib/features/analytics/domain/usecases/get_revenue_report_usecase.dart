import '../services/analytics_service.dart';

class GetRevenueReportUsecase {
  final AnalyticsService service;
  GetRevenueReportUsecase(this.service);
  Future<Map<String, dynamic>> call(String userId, DateTime start, DateTime end) =>
      service.getRevenueReport(userId, start, end);
}
