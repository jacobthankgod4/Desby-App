import 'dart:async';
import '../../features/notifications/domain/entities/notification.dart';

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
  final StreamController<RealtimeEvent> _eventController = StreamController<RealtimeEvent>.broadcast();
  bool _isConnected = false;
  Timer? _realtimeTimer;

  @override
  Stream<RealtimeEvent> get eventStream => _eventController.stream;

  @override
  bool get isConnected => _isConnected;

  @override
  Future<void> connect(String userId) async {
    if (_isConnected) return;
    
    // Simulate connection delay
    await Future.delayed(const Duration(seconds: 1));
    _isConnected = true;
    
    // Start realtime event generation for demonstration
    _startRealtimeEvents();
  }

  @override
  Future<void> disconnect() async {
    _realtimeTimer?.cancel();
    _isConnected = false;
  }

  void _startRealtimeEvents() {
    _realtimeTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_isConnected) return;

      // Randomly emit a firebase event
      final event = RealtimeEvent(
        type: RealtimeEventType.newNotification,
        data: AppNotification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'Real-time Update',
          body: 'This is a live notification from the system.',
          type: NotificationType.system,
          timestamp: DateTime.now(),
        ),
        timestamp: DateTime.now(),
      );
      
      _eventController.add(event);
    });
  }
}
