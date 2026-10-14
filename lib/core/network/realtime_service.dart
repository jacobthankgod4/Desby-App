import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/notifications/domain/entities/notification.dart';
import '../logging/logger.dart';

enum RealtimeEventType {
  newMessage,
  newNotification,
  orderStatusChanged,
  taskUpdated,
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
  Future<void> connect(String userId, {String? userType});
  Future<void> disconnect();
  bool get isConnected;
}

class RealtimeServiceImpl implements RealtimeService {
  final StreamController<RealtimeEvent> _eventController =
      StreamController<RealtimeEvent>.broadcast();
  bool _isConnected = false;
  RealtimeChannel? _channel;
  String? _userId;
  String? _userType;
  int _retryCount = 0;
  static const int _maxRetries = 5;
  Timer? _retryTimer;
  bool _disposed = false;

  @override
  Stream<RealtimeEvent> get eventStream => _eventController.stream;

  @override
  bool get isConnected => _isConnected;

  @override
  Future<void> connect(String userId, {String? userType}) async {
    if (_isConnected || userId.isEmpty || _disposed) return;
    _userId = userId;
    _userType = userType;

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
              _eventController.add(
                RealtimeEvent(
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
                ),
              );
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'orders',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'tailor_id',
              value: userId,
            ),
            callback: (payload) {
              logger.debug('Realtime order update received');
              _eventController.add(
                RealtimeEvent(
                  type: RealtimeEventType.orderStatusChanged,
                  data: payload.newRecord,
                  timestamp: DateTime.now(),
                ),
              );
            },
          )
          .subscribe((status, [error]) {
if (error != null) {
        // "table not in publication" is a server configuration gap. Retrying
        // cannot fix it and just floods the log every few seconds, so treat it
        // as terminal alongside auth failures.
        final message = error.toString();
        if (message.contains('not in publication') ||
            message.contains('Unable to subscribe')) {
          debugPrint(
            '[Realtime] Subscription unsupported by server, '
            'disabling live updates: $message',
          );
          disconnect();
          return;
        }
        debugPrint('[Realtime] Subscribe error: $error');
        _onError(message);
        return;
      }
            if (status == RealtimeSubscribeStatus.subscribed) {
              _retryCount = 0;
              _isConnected = true;
              logger.info('Realtime connected for user: $userId');
            } else if (status == RealtimeSubscribeStatus.channelError ||
                status == RealtimeSubscribeStatus.timedOut) {
              _onError('Channel status: $status');
            }
          });
    } catch (e) {
      debugPrint('[Realtime] Connection failed: $e');
      _isConnected = false;
      _onError(e.toString());
    }
  }

  void _onError(String error) {
    _isConnected = false;

    // Non-retryable: JWT issues, permission errors
    if (error.contains('Token') ||
        error.contains('JWT') ||
        error.contains('permission') ||
        error.contains('403')) {
      debugPrint('[Realtime] Non-retryable error, disconnecting: $error');
      disconnect();
      return;
    }

    _scheduleRetry();
  }

  void _scheduleRetry() {
    if (_disposed || _retryCount >= _maxRetries) {
      debugPrint('[Realtime] Max retries ($_maxRetries) reached, giving up');
      disconnect();
      return;
    }

    _retryCount++;
    final delaySeconds = (5 * _retryCount).clamp(5, 30);
    debugPrint(
      '[Realtime] Retry $_retryCount/$_maxRetries in ${delaySeconds}s',
    );

    _retryTimer?.cancel();
    _retryTimer = Timer(Duration(seconds: delaySeconds), () async {
      if (_disposed || _userId == null) return;

      // Tear down old channel before reconnecting
      if (_channel != null) {
        try {
          await Supabase.instance.client.removeChannel(_channel!);
        } catch (e) {
          debugPrint('[REALTIME] Error removing channel: $e');
        }
        _channel = null;
      }

      // Re-subscribe
      await connect(_userId!, userType: _userType);
    });
  }

  @override
  Future<void> disconnect() async {
    _retryTimer?.cancel();
    if (_channel != null) {
      try {
        await Supabase.instance.client.removeChannel(_channel!);
      } catch (e) {
        debugPrint('[Realtime] Disconnect error: $e');
      }
      _channel = null;
    }
    _isConnected = false;
    _retryCount = 0;
    logger.info('Realtime disconnected');
  }

  void dispose() {
    _disposed = true;
    _retryTimer?.cancel();
    _eventController.close();
  }
}
