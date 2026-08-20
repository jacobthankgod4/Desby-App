import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/notifications/domain/entities/notification.dart';
import '../logging/logger.dart';

enum RealtimeEventType {
  newMessage,
  newNotification,
  orderStatusChanged,
  taskUpdated
}

class RealtimeEvent {
  final RealtimeEventType type;
  final dynamic data;
  final DateTime timestamp;

  RealtimeEvent({
    required this.type,
    required this.data,
    required this.timestamp,
  });
}

abstract class RealtimeService {
  Stream<RealtimeEvent> get eventStream;
  Future<void> connect(String userId);
  Future<void> disconnect();
  bool get isConnected;
}

class RealtimeServiceImpl implements RealtimeService {
  final StreamController<RealtimeEvent> _eventController =
      StreamController<RealtimeEvent>.broadcast();
  bool _isConnected = false;
  RealtimeChannel? _channel;

  @override
  Stream<RealtimeEvent> get eventStream => _eventController.stream;

  @override
  bool get isConnected => _isConnected;

  @override
  Future<void> connect(String userId) async {
    if (_isConnected) return;

    try {
      final supabase = Supabase.instance.client;

      _channel = supabase.channel('user_$userId');

      _channel!
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (payload) {
              logger.debug('Realtime notification received');
              final data = payload.newRecord;
              _eventController.add(RealtimeEvent(
                type: RealtimeEventType.newNotification,
                data: AppNotification(
                  id: data['id'] as String? ?? '',
                  title: data['title'] as String? ?? '',
                  body: data['body'] as String? ?? '',
                  type: NotificationType.values.firstWhere(
                    (e) => e.name == data['type'],
                    orElse: () => NotificationType.system,
                  ),
                  timestamp: DateTime.now(),
                ),
                timestamp: DateTime.now(),
              ));
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'orders',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (payload) {
              logger.debug('Realtime order update received');
              _eventController.add(RealtimeEvent(
                type: RealtimeEventType.orderStatusChanged,
                data: payload.newRecord,
                timestamp: DateTime.now(),
              ));
            },
          )
          .subscribe();

      _isConnected = true;
      logger.info('Realtime connected for user: $userId');
    } catch (e) {
      logger.error('Realtime connection failed', error: e);
      _isConnected = false;
    }
  }

  @override
  Future<void> disconnect() async {
    if (_channel != null) {
      await Supabase.instance.client.removeChannel(_channel!);
      _channel = null;
    }
    _isConnected = false;
    logger.info('Realtime disconnected');
  }
}
