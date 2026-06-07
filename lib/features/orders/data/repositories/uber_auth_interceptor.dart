import 'package:dio/dio.dart';
import '../../domain/repositories/uber_auth_repository.dart';

class UberAuthInterceptor extends Interceptor {
  final UberAuthRepository _authRepository;

  UberAuthInterceptor(this._authRepository);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await _authRepository.getAccessToken();
      options.headers['Authorization'] = 'Bearer $token';
      handler.next(options);
    } catch (e) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: 'Failed to fetch Uber access token: $e',
        ),
      );
    }
  }
}
