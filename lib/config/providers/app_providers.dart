import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/logger.dart';
import '../../core/storage/local_storage.dart';
import '../../core/storage/secure_storage.dart';

/// Core Application Providers
/// These providers are the foundation for dependency injection

/// Logger Provider
final loggerProvider = Provider<AppLogger>((ref) {
  return logger;
});

/// Local Storage Provider
final localStorageProvider = FutureProvider<LocalStorageService>((ref) async {
  logger.debug('Initializing local storage');
  try {
    await localStorage.initialize();
    return localStorage;
  } catch (e) {
    logger.warning('Failed to initialize local storage', error: e);
    return localStorage;
  }
});

/// Secure Storage Provider
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  logger.debug('Initializing secure storage');
  return secureStorage;
});

/// App Initialization Provider
/// Ensures all core services are initialized before app starts
final appInitializationProvider = FutureProvider<void>((ref) async {
  try {
    logger.info('Starting app initialization');
    
    // Initialize local storage
    await ref.watch(localStorageProvider.future);
    
    // Check for existing authentication
    logger.debug('Checking for existing authentication session');
    
    logger.info('App initialization completed successfully');
  } catch (e, stackTrace) {
    logger.error(
      'App initialization failed',
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }
});

/// App State Provider
/// Tracks overall app state
final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>(
  (ref) => AppStateNotifier(),
);

/// App State Notifier
class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(const AppState.idle());

  void setLoading() => state = const AppState.loading();
  void setReady() => state = const AppState.ready();
  void setError(String message) => state = AppState.error(message);
}

/// App State
sealed class AppState {
  const AppState();

  const factory AppState.idle() = _Idle;
  const factory AppState.loading() = _Loading;
  const factory AppState.ready() = _Ready;
  const factory AppState.error(String message) = _Error;

  bool get isLoading => this is _Loading;
  bool get isReady => this is _Ready;
  bool get isError => this is _Error;
}

class _Idle extends AppState {
  const _Idle();
}

class _Loading extends AppState {
  const _Loading();
}

class _Ready extends AppState {
  const _Ready();
}

class _Error extends AppState {
  final String message;
  const _Error(this.message);
}
