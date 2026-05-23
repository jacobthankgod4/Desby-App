import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/analytics_event.dart';
import '../../domain/services/analytics_service.dart';

class AnalyticsServiceImpl implements AnalyticsService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  @override
  Future<void> logEvent(AnalyticsEvent event) async {
    // In production, this would go to Firebase Analytics
    debugPrint('Analytics: ${event.name} - ${event.parameters}');
  }

  @override
  Future<void> setUserProperty(String name, String value) async {
    debugPrint('UserProperty: $name = $value');
  }

  @override
  Future<List<BusinessMetric>> getDashboardMetrics(String userId) async {
    try {
      // 1. Get real orders count
      final ordersSnapshot = await _firestore.collection('orders').get();
      final totalOrders = ordersSnapshot.docs.length.toDouble();

      // 2. Aggregate real revenue
      double totalRevenue = 0;
      for (var doc in ordersSnapshot.docs) {
        final data = doc.data();
        totalRevenue += (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
      }

      // 3. Get total clients
      final clientsSnapshot = await _firestore.collection('clients').get();
      final totalClients = clientsSnapshot.docs.length.toDouble();

      // 4. Calculate Turnaround (Mocked for now as we need date diff logic)
      const avgTurnaround = 4.2;

      return [
        BusinessMetric(
          label: 'Total Revenue', 
          value: totalRevenue / 1000, // Dashboard multiplies by 1000
          trend: 'up', 
          changePercentage: 0.0
        ),
        BusinessMetric(
          label: 'Active Orders', 
          value: totalOrders, 
          trend: 'stable', 
          changePercentage: 0.0
        ),
        BusinessMetric(
          label: 'Client Base', 
          value: totalClients, 
          trend: 'up', 
          changePercentage: 0.0
        ),
        BusinessMetric(
          label: 'Avg Turnaround', 
          value: avgTurnaround, 
          trend: 'down', 
          changePercentage: 0.0
        ),
      ];
    } catch (e) {
      debugPrint('Error fetching metrics: $e');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> getRevenueReport(String userId, DateTime start, DateTime end) async {
    try {
      final snapshot = await _firestore.collection('orders').get();
      
      double totalRevenue = 0;
      Map<String, double> periods = {};
      Map<String, double> garments = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final amount = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
        totalRevenue += amount;

        // Simple period grouping (by month)
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        final monthKey = '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-01';
        periods[monthKey] = (periods[monthKey] ?? 0) + amount;

        // Garment breakdown
        final items = data['items'] as List?;
        if (items != null) {
          for (var item in items) {
            final type = item['garmentType'] as String? ?? 'Other';
            final itemPrice = (item['price'] as num?)?.toDouble() ?? 0.0;
            garments[type] = (garments[type] ?? 0.0) + itemPrice;
          }
        }
      }

      return {
        'total_revenue': totalRevenue,
        'periods': periods.entries.map((e) => {'date': e.key, 'amount': e.value}).toList(),
        'garment_breakdown': garments.entries.map((e) => {'type': e.key, 'amount': e.value}).toList(),
      };
    } catch (e) {
      debugPrint('Error fetching revenue report: $e');
      return {'total_revenue': 0.0, 'periods': [], 'garment_breakdown': []};
    }
  }
}
