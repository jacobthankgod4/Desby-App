import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/analytics_service.dart';
import '../../data/repositories/analytics_service_impl.dart';
import '../../domain/entities/analytics_event.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsServiceImpl();
});

final dashboardMetricsProvider = FutureProvider<List<BusinessMetric>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  
  final service = ref.watch(analyticsServiceProvider);
  return await service.getDashboardMetrics(user.id);
});

final revenueReportProvider = FutureProvider.family<Map<String, dynamic>, ({DateTime start, DateTime end})>((ref, dateRange) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return {};
  
  final service = ref.watch(analyticsServiceProvider);
  return await service.getRevenueReport(user.id, dateRange.start, dateRange.end);
});
