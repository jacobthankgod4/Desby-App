import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/notification_repository.dart';

class SupabaseNotificationRepository implements NotificationRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<Result<List<AppNotification>>> getNotifications(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('userId', userId)
          .order('timestamp', ascending: false);
      
      return Success((response as List)
          .map((data) => _mapToEntity(data['id'], data))
          .toList());
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'isRead': true})
          .eq('id', notificationId);
      return const Success(null);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> markAllAsRead(String userId) async {
     try {
      await _supabase
          .from('notifications')
          .update({'isRead': true})
          .eq('userId', userId)
          .eq('isRead', false);
      return const Success(null);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId);
      return const Success(null);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Stream<AppNotification> getNotificationStream(String userId) {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('userId', userId)
        .order('timestamp', ascending: false)
        .limit(1)
        .where((event) => event.isNotEmpty)
        .map((event) => _mapToEntity(event.first['id'], event.first));
  }

  AppNotification _mapToEntity(String id, Map<String, dynamic> data) {
    return AppNotification(
      id: id,
      title: data['title'] as String? ?? 'Notification',
      body: data['body'] as String? ?? '',
      timestamp: DateTime.parse(data['timestamp'] as String),
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
