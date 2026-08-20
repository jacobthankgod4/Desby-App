import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/analytics_service.dart';
import '../../domain/usecases/get_dashboard_metrics_usecase.dart';
import '../../domain/usecases/get_revenue_report_usecase.dart';
import '../../data/repositories/analytics_service_impl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsServiceImpl();
});

final getDashboardMetricsUsecaseProvider = Provider<GetDashboardMetricsUsecase>((ref) {
  return GetDashboardMetricsUsecase(ref.watch(analyticsServiceProvider));
});

final getRevenueReportUsecaseProvider = Provider<GetRevenueReportUsecase>((ref) {
  return GetRevenueReportUsecase(ref.watch(analyticsServiceProvider));
});

final dashboardMetricsProvider = FutureProvider<List<BusinessMetric>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final usecase = ref.watch(getDashboardMetricsUsecaseProvider);
  return await usecase(user.id);
});

final revenueReportProvider = FutureProvider.family<Map<String, dynamic>, ({DateTime start, DateTime end})>((ref, dateRange) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return {};
  final usecase = ref.watch(getRevenueReportUsecaseProvider);
  return await usecase(user.id, dateRange.start, dateRange.end);
});
