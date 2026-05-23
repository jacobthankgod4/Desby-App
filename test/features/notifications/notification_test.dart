import 'package:flutter_test/flutter_test.dart';
import 'package:desby_app/features/notifications/domain/entities/notification.dart';

void main() {
  group('Notification Entity Tests', () {
    test('should identify notification type correctly', () {
      final notification = AppNotification(
        id: '1',
        title: 'Title',
        body: 'Body',
        type: NotificationType.orderUpdate,
        timestamp: DateTime.now(),
      );

      expect(notification.type, NotificationType.orderUpdate);
    });
  });
}
