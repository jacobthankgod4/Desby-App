import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

/// Token Refresh Helper
/// Handles automatic token refresh when access token expires
class TokenRefreshHelper {
  static Future<bool> refreshTokenIfNeeded(Ref ref) async {
    try {
      final authRepository = ref.read(authRepositoryProvider);
      final refreshTokenResult = await authRepository.getRefreshToken();
      final refreshToken = refreshTokenResult.getOrNull();

      if (refreshToken == null) {
        return false;
      }

      final result = await authRepository.refreshToken(refreshToken);
      return result.fold(
        (failure) => false,
        (authResponse) => true,
      );
    } catch (e) {
      return false;
    }
  }

  static Future<void> handleUnauthorized(Ref ref) async {
    final refreshed = await refreshTokenIfNeeded(ref);
    if (!refreshed) {
      // Token refresh failed, logout user
      await ref.read(authStateProvider.notifier).logout();
    }
  }
}
