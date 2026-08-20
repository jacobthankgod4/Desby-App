import '../entities/notification.dart';
import '../repositories/notification_repository.dart';

class GetNotificationStreamUsecase {
  final NotificationRepository repository;
  GetNotificationStreamUsecase(this.repository);
  Stream<AppNotification> call(String userId) =>
      repository.getNotificationStream(userId);
}
