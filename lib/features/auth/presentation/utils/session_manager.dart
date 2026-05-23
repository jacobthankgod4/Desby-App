import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../providers/auth_provider.dart';

/// Session Manager
/// Handles session restoration on app restart and session timeout
class SessionManager {
  // Extended session timeout to 7 days for better UX
  // Users should not be logged out for typical app usage patterns
  static const Duration _sessionTimeout = Duration(days: 7);
  Timer? _sessionTimer;
  final Ref _ref;

  SessionManager(this._ref);

  /// Restore session from stored tokens
  Future<bool> restoreSession() async {
    try {
      final authRepository = _ref.read(authRepositoryProvider);
      final accessTokenResult = await authRepository.getAccessToken();
      final accessToken = accessTokenResult.getOrNull();

      if (accessToken == null) {
        return false;
      }

      // Session restored successfully
      _startSessionTimer();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Start session timeout timer
  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(_sessionTimeout, () {
      _handleSessionTimeout();
    });
  }

  /// Handle session timeout
  Future<void> _handleSessionTimeout() async {
    await _ref.read(authStateProvider.notifier).logout();
  }

  /// Reset session timer (call on user activity)
  void resetSessionTimer() {
    _startSessionTimer();
  }

  /// Dispose session manager
  void dispose() {
    _sessionTimer?.cancel();
  }
}

/// Session Manager Provider
final sessionManagerProvider = Provider((ref) {
  final manager = SessionManager(ref);
  ref.onDispose(() => manager.dispose());
  return manager;
});

/// Session Restoration Provider
final sessionRestorationProvider = FutureProvider((ref) async {
  final sessionManager = ref.watch(sessionManagerProvider);
  return await sessionManager.restoreSession();
});
