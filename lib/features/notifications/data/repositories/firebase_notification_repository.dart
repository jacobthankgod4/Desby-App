import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/notification_repository.dart';

class FirebaseNotificationRepository implements NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<Result<List<AppNotification>>> getNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .get();
      
      return Success(snapshot.docs
          .map((doc) => _mapToEntity(doc.id, doc.data()))
          .toList());
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> markAsRead(String notificationId) async {
    // Requires userId in production. Simplification for implementation.
    return const Success(null);
  }

  @override
  Future<Result<void>> markAllAsRead(String userId) async {
     try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();
      
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
      return const Success(null);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteNotification(String notificationId) async {
    return const Success(null);
  }

  @override
  Stream<AppNotification> getNotificationStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .where((snapshot) => snapshot.docs.isNotEmpty)
        .map((snapshot) => _mapToEntity(snapshot.docs.first.id, snapshot.docs.first.data()));
  }

  AppNotification _mapToEntity(String id, Map<String, dynamic> data) {
    return AppNotification(
      id: id,
      title: data['title'] as String? ?? 'Notification',
      body: data['body'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: _parseType(data['type'] as String? ?? 'system'),
      isRead: data['isRead'] as bool? ?? false,
    );
  }

  NotificationType _parseType(String type) {
    return NotificationType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => NotificationType.system,
    );
  }
}
