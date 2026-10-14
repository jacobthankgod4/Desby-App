import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/notification_repository.dart';

final _uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  caseSensitive: false,
);

class SupabaseNotificationRepository implements NotificationRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isValidUuid(String? id) =>
      id != null && id.isNotEmpty && _uuidPattern.hasMatch(id);

  @override
  Future<Result<List<AppNotification>>> getNotifications(String userId) async {
    if (!_isValidUuid(userId)) return const Success([]);
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);
      return Success(
        (response as List).map((data) => _mapToEntity(data)).toList(),
      );
    } catch (e) {
      debugPrint('[Notifications] Query failed: $e');
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
    if (!_isValidUuid(userId)) return const Success(null);
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
      await _supabase.from('notifications').delete().eq('id', notificationId);
      return const Success(null);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Stream<AppNotification> getNotificationStream(String userId) {
    if (!_isValidUuid(userId)) return const Stream.empty();
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
    final timestampStr = data['created_at'] as String? ?? '';
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
