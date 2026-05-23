import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../logging/logger.dart';

/// State Synchronization Manager
/// Handles synchronization of app state across different instances
class StateSynchronizationManager {
  final Map<String, StreamController<dynamic>> _stateControllers = {};

  /// Register a state stream for synchronization
  void registerStateStream<T>(
    String key,
    Stream<T> stream,
    Function(T) onStateChange,
  ) {
    _stateControllers[key] = StreamController<T>();

    stream.listen(
      (state) {
        _stateControllers[key]?.add(state);
        onStateChange(state);
        logger.debug('State synchronized: $key');
      },
      onError: (error) {
        logger.error('State synchronization error for $key', error: error);
      },
    );
  }

  /// Broadcast state change to all listeners
  void broadcastStateChange<T>(String key, T state) {
    _stateControllers[key]?.add(state);
    logger.debug('State broadcasted: $key');
  }

  /// Get state stream
  Stream<T>? getStateStream<T>(String key) {
    return _stateControllers[key]?.stream as Stream<T>?;
  }

  /// Dispose all streams
  void dispose() {
    for (final controller in _stateControllers.values) {
      controller.close();
    }
    _stateControllers.clear();
  }
}

/// State Synchronization Provider
final stateSynchronizationProvider = Provider((ref) {
  final manager = StateSynchronizationManager();
  ref.onDispose(() => manager.dispose());
  return manager;
});

/// Auth State Synchronization
final authStateSynchronizationProvider = Provider((ref) {
  final syncManager = ref.watch(stateSynchronizationProvider);
  final authState = ref.watch(authStateProvider);

  // Broadcast auth state for synchronization
  syncManager.broadcastStateChange('auth_state', authState);

  return authState;
});
