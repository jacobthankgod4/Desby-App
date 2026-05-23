import 'package:equatable/equatable.dart';

class DashboardStats extends Equatable {
  final int totalOrders;
  final int pendingOrders;
  final int completedOrders;
  final double totalRevenue;
  final int totalClients;
  final int urgentDeadlines; // High priority: Orders due soon
  final int totalApprentices;
  final double fabricInventoryLevel;
  final double growthPercentage;
  final int unreadMessages;
  final DateTime lastUpdated;

  const DashboardStats({
    required this.totalOrders,
    required this.pendingOrders,
    required this.completedOrders,
    required this.totalRevenue,
    required this.totalClients,
    required this.urgentDeadlines,
    required this.totalApprentices,
    required this.fabricInventoryLevel,
    required this.growthPercentage,
    required this.unreadMessages,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [
        totalOrders,
        pendingOrders,
        completedOrders,
        totalRevenue,
        totalClients,
        urgentDeadlines,
        totalApprentices,
        fabricInventoryLevel,
        growthPercentage,
        unreadMessages,
        lastUpdated,
      ];

  DashboardStats copyWith({
    int? totalOrders,
    int? pendingOrders,
    int? completedOrders,
    double? totalRevenue,
    int? totalClients,
    int? urgentDeadlines,
    int? totalApprentices,
    double? fabricInventoryLevel,
    double? growthPercentage,
    int? unreadMessages,
    DateTime? lastUpdated,
  }) {
    return DashboardStats(
      totalOrders: totalOrders ?? this.totalOrders,
      pendingOrders: pendingOrders ?? this.pendingOrders,
      completedOrders: completedOrders ?? this.completedOrders,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalClients: totalClients ?? this.totalClients,
      urgentDeadlines: urgentDeadlines ?? this.urgentDeadlines,
      totalApprentices: totalApprentices ?? this.totalApprentices,
      fabricInventoryLevel: fabricInventoryLevel ?? this.fabricInventoryLevel,
      growthPercentage: growthPercentage ?? this.growthPercentage,
      unreadMessages: unreadMessages ?? this.unreadMessages,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
