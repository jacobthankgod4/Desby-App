import '../entities/analytics_event.dart';
import '../services/analytics_service.dart';

class LogEventUsecase {
  final AnalyticsService service;
  LogEventUsecase(this.service);
  Future<void> call(AnalyticsEvent event) => service.logEvent(event);
}
