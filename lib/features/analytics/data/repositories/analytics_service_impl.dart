import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/analytics_event.dart';
import '../../domain/services/analytics_service.dart';

class AnalyticsServiceImpl implements AnalyticsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<void> logEvent(AnalyticsEvent event) async {
    try {
      debugPrint('Analytics: ${event.name} - ${event.parameters}');
      await _supabase.from('analytics_events').insert({
        'user_id': _supabase.auth.currentUser?.id,
        'event_name': event.name,
        'parameters': event.parameters,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error logging analytics event: $e');
    }
  }

  @override
  Future<void> setUserProperty(String name, String value) async {
     debugPrint('Analytics User Property: $name = $value');
  }

  @override
  Future<List<BusinessMetric>> getDashboardMetrics(String userId) async {
    return []; // Implementation simplified
  }

  @override
  Future<Map<String, dynamic>> getRevenueReport(String userId, DateTime start, DateTime end) async {
    return {}; // Implementation simplified
  }

  @override
  Future<Map<String, dynamic>> getBusinessInsights(String userId) async {
    try {
      final ordersResponse = await _supabase.from('orders').select().eq('tailor_id', userId);
      final clientsResponse = await _supabase.from('clients').select().eq('tailor_id', userId);

      final List<dynamic> orders = ordersResponse;
      final List<dynamic> clients = clientsResponse;

      return {
        'totalOrders': orders.length,
        'totalClients': clients.length,
        'totalRevenue': orders.fold(0.0, (sum, o) => sum + (o['total_amount'] as num).toDouble()),
        'completedOrders': orders.where((o) => o['status'] == 'completed' || o['status'] == 'delivered').length,
      };
    } catch (e) {
      debugPrint('Error getting business insights: $e');
      return {};
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getMonthlyRevenue(String userId) async {
    try {
      final response = await _supabase.from('orders').select('total_amount, created_at').eq('tailor_id', userId);
      final List<dynamic> orders = response;
      
      // Group by month
      final Map<String, double> monthlyData = {};
      for (final order in orders) {
        final date = DateTime.parse(order['created_at'] as String);
        final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + (order['total_amount'] as num).toDouble();
      }

      return monthlyData.entries.map((e) => {'month': e.key, 'revenue': e.value}).toList();
    } catch (e) {
      debugPrint('Error getting monthly revenue: $e');
      return [];
    }
  }

  @override
  Future<Map<String, int>> getOrderCategoryDistribution(String userId) async {
    try {
      final response = await _supabase.from('orders').select('items').eq('tailor_id', userId);
      final List<dynamic> orders = response;
      
      final Map<String, int> distribution = {};
      for (final order in orders) {
        final List<dynamic> items = order['items'] as List<dynamic>;
        for (final item in items) {
          final type = item['garmentType'] as String;
          distribution[type] = (distribution[type] ?? 0) + 1;
        }
      }

      return distribution;
    } catch (e) {
      debugPrint('Error getting category distribution: $e');
      return {};
    }
  }
}
