import '../../../../core/error/failures.dart';
import '../entities/notification.dart';

abstract class NotificationRepository {
  Future<Result<List<AppNotification>>> getNotifications(String userId);
  Future<Result<void>> markAsRead(String notificationId);
  Future<Result<void>> markAllAsRead(String userId);
  Future<Result<void>> deleteNotification(String notificationId);
  Stream<AppNotification> getNotificationStream(String userId);
}
