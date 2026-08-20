import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/notification_repository.dart';

class SupabaseNotificationRepository implements NotificationRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<Result<List<AppNotification>>> getNotifications(String userId) async {
    try {
      // Try with user_id (snake_case) first, fallback to userId (camelCase)
      List<dynamic> response;
      try {
        response = await _supabase
            .from('notifications')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false);
      } catch (_) {
        // Fallback to camelCase column names
        response = await _supabase
            .from('notifications')
            .select()
            .eq('userId', userId)
            .order('timestamp', ascending: false);
      }

      return Success((response as List)
          .map((data) => _mapToEntity(data))
          .toList());
    } catch (e) {
      // Return empty list on any error (table may not exist yet)
      return const Success([]);
    }
  }

  @override
  Future<Result<void>> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
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
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
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
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .where((event) => event.isNotEmpty)
        .map((event) => _mapToEntity(event.first));
  }

  AppNotification _mapToEntity(Map<String, dynamic> data) {
    // Support both snake_case and camelCase column names
    final timestampStr = data['created_at'] as String? ?? data['timestamp'] as String? ?? '';
    DateTime timestamp;
    try {
      timestamp = DateTime.parse(timestampStr);
    } catch (_) {
      timestamp = DateTime.now();
    }

    return AppNotification(
      id: data['id']?.toString() ?? '',
      title: data['title'] as String? ?? 'Notification',
      body: data['body'] as String? ?? '',
      timestamp: timestamp,
      type: _parseType(data['type'] as String? ?? 'system'),
      isRead: data['is_read'] as bool? ?? data['isRead'] as bool? ?? false,
    );
  }

  NotificationType _parseType(String type) {
    return NotificationType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => NotificationType.system,
    );
  }
}
