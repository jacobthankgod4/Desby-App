import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../logging/logger.dart';
import 'dio_client.dart';



/// Token Refresh Interceptor
/// Automatically refreshes access token when it expires (401 response)
class TokenRefreshInterceptor extends Interceptor {
  final WidgetRef ref;
  bool _isRefreshing = false;
  final List<RequestOptions> _requestsToRetry = [];

  TokenRefreshInterceptor(this.ref);

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Only handle 401 Unauthorized
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    // Prevent multiple simultaneous refresh attempts
    if (_isRefreshing) {
      _requestsToRetry.add(err.requestOptions);
      return;
    }

    _isRefreshing = true;

    try {
      // Attempt token refresh
      final refreshed = await _refreshToken();

      if (refreshed) {
        // Token refreshed successfully, retry original request
        _isRefreshing = false;
        _retryFailedRequests();
        handler.resolve(await _retry(err.requestOptions));
      } else {
        // Token refresh failed, logout user
        _isRefreshing = false;
        await ref.read(authStateProvider.notifier).logout();

        handler.next(err);
      }
    } catch (e) {
      _isRefreshing = false;
      logger.error('Token refresh failed', error: e);
      handler.next(err);
    }
  }

  /// Refresh access token using refresh token
  Future<bool> _refreshToken() async {
    try {
      final authRepository = ref.read(authRepositoryProvider);
      final refreshTokenResult = await authRepository.getRefreshToken();
      final refreshToken = refreshTokenResult.getOrNull();


      if (refreshToken == null) {
        return false;
      }

      final result = await authRepository.refreshToken(refreshToken);
      return result.fold(
        (failure) {
          logger.warning('Token refresh failed: ${failure.message}');
          return false;
        },
        (authResponse) {
          logger.info('Token refreshed successfully');
          return true;
        },
      );
    } catch (e) {
      logger.error('Token refresh error', error: e);
      return false;
    }
  }

  /// Retry failed requests after token refresh
  void _retryFailedRequests() {
    for (final request in _requestsToRetry) {
      _retry(request);
    }
    _requestsToRetry.clear();
  }

  /// Retry a request
  Future<Response> _retry(RequestOptions requestOptions) async {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
      contentType: requestOptions.contentType,
      responseType: requestOptions.responseType,
      validateStatus: requestOptions.validateStatus,
    );

    return ref.read(dioProvider).request<dynamic>(
          requestOptions.path,
          data: requestOptions.data,
          queryParameters: requestOptions.queryParameters,
          options: options,
        );
  }
}
