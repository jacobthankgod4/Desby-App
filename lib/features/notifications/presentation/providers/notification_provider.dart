import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../data/repositories/firebase_notification_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// Repository Provider
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return FirebaseNotificationRepository();
});

// Notifications List Provider
final notificationsProvider = FutureProvider<List<AppNotification>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  
  final repository = ref.watch(notificationRepositoryProvider);
  final result = await repository.getNotifications(user.id);
  return result.fold(
    (failure) => throw failure,
    (notifications) => notifications,
  );
});

// Unread Count Provider
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationsProvider);
  return notificationsAsync.when(
    data: (notifications) => notifications.where((n) => !n.isRead).length,
    loading: () => 0,
    error: (error, stack) => 0,
  );
});

// Real-time Notification Stream Provider
final notificationStreamProvider = StreamProvider<AppNotification>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getNotificationStream(user.id);
});
