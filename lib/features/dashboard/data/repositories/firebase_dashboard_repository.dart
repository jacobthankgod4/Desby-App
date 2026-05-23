import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/repositories/dashboard_repository.dart';

class FirebaseDashboardRepository implements DashboardRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<Result<DashboardStats>> getDashboardStats(String userId) async {
    try {
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('tailorId', isEqualTo: userId)
          .get();
      
      final clientsSnapshot = await _firestore
          .collection('clients')
          .where('tailorId', isEqualTo: userId)
          .get();
      
      final apprenticeSnapshot = await _firestore
          .collection('apprenticeships')
          .where('tailorId', isEqualTo: userId)
          .get();

      final pendingOrders = ordersSnapshot.docs
          .where((doc) => (doc.data()['status'] ?? 'pending') != 'delivered' && (doc.data()['status'] ?? 'pending') != 'cancelled')
          .length;
      
final completedOrders = ordersSnapshot.docs
          .where((doc) => (doc.data()['status'] ?? 'pending') == 'delivered')
          .length;

      // Calculate REAL revenue from completed orders (not mock data!)
      double totalRevenueValue = 0.0;
      for (final doc in ordersSnapshot.docs) {
        final status = doc.data()['status'] ?? 'pending';
        if (status == 'delivered' || status == 'completed') {
          final amount = doc.data()['totalAmount'] ?? doc.data()['amount'] ?? 0;
          totalRevenueValue += (amount as num).toDouble();
        }
      }

      // Calculate Urgent Deadlines (due in next 4 days)
      final now = DateTime.now();
      final urgentThreshold = now.add(const Duration(days: 4));
      final urgentCount = ordersSnapshot.docs.where((doc) {
        final dueDateData = doc.data()['dueDate'];
        if (dueDateData == null) return false;
        final dueDate = (dueDateData as Timestamp).toDate();
        final status = doc.data()['status'] ?? 'pending';
        return dueDate.isBefore(urgentThreshold) && status != 'delivered' && status != 'cancelled';
      }).length;

return Success(DashboardStats(
        totalOrders: ordersSnapshot.docs.length,
        pendingOrders: pendingOrders,
        completedOrders: completedOrders,
        totalRevenue: totalRevenueValue, // FIXED: Now uses real Firebase data
        totalClients: clientsSnapshot.docs.length,
        urgentDeadlines: urgentCount,
        totalApprentices: apprenticeSnapshot.docs.length,
        fabricInventoryLevel: 0.75,
        growthPercentage: 15.5,
        unreadMessages: 3,
        lastUpdated: DateTime.now(),
      ));
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<dynamic>>> getRecentOrders(String userId, {int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('tailorId', isEqualTo: userId)
          .limit(limit)
          .get();
      return Success(snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<dynamic>>> getRecentClients(String userId, {int limit = 5}) async {
    try {
      final snapshot = await _firestore
          .collection('clients')
          .where('tailorId', isEqualTo: userId)
          .limit(limit)
          .get();
      return Success(snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }
}
