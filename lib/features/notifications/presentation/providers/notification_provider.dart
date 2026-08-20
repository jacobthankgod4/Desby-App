import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/get_notification_stream_usecase.dart';
import '../../data/repositories/supabase_notification_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return SupabaseNotificationRepository();
});

final getNotificationsUsecaseProvider = Provider<GetNotificationsUsecase>((ref) {
  return GetNotificationsUsecase(ref.watch(notificationRepositoryProvider));
});

final getNotificationStreamUsecaseProvider = Provider<GetNotificationStreamUsecase>((ref) {
  return GetNotificationStreamUsecase(ref.watch(notificationRepositoryProvider));
});

final notificationsProvider = FutureProvider<List<AppNotification>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final usecase = ref.watch(getNotificationsUsecaseProvider);
  final result = await usecase(user.id);
  return result.fold(
    (failure) => throw failure,
    (notifications) => notifications,
  );
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationsProvider);
  return notificationsAsync.when(
    data: (notifications) => notifications.where((n) => !n.isRead).length,
    loading: () => 0,
    error: (error, stack) => 0,
  );
});

final notificationStreamProvider = StreamProvider<AppNotification>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  final usecase = ref.watch(getNotificationStreamUsecaseProvider);
  return usecase(user.id);
});
