import '../../../../core/error/failures.dart';
import '../entities/notification.dart';
import '../repositories/notification_repository.dart';

class GetNotificationsUsecase {
  final NotificationRepository repository;
  GetNotificationsUsecase(this.repository);
  Future<Result<List<AppNotification>>> call(String userId) =>
      repository.getNotifications(userId);
}
