import 'package:dio/dio.dart';


import '../error/exceptions.dart';
import '../logging/logger.dart';

/// Logging Interceptor
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    logger.logRequest(
      options.method,
      options.path,
      headers: options.headers.cast<String, dynamic>(),
      body: options.data,
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    logger.logResponse(
      response.requestOptions.method,
      response.requestOptions.path,
      response.statusCode ?? 0,
      body: response.data,
      duration: response.requestOptions.extra['duration'] as Duration?,
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    logger.logNetworkError(
      err.requestOptions.method,
      err.requestOptions.path,
      err.message,
      stackTrace: err.stackTrace,
    );
    handler.next(err);
  }
}

/// Authentication Interceptor
/// Injects access token in all requests
/// Handles token refresh on 401 responses
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Token is already set in DioClient if available
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Handle 401 Unauthorized
    if (err.response?.statusCode == 401) {
      logger.warning('Unauthorized - Token may be expired');
      // Token refresh logic will be implemented in Phase 4
    }
    handler.next(err);
  }
}

/// Error Interceptor
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final exception = _mapDioExceptionToAppException(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: exception,
        type: err.type,
        response: err.response,
      ),
    );
  }

  AppException _mapDioExceptionToAppException(DioException dioException) {
    return switch (dioException.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout =>
        TimeoutException(
          message: 'Request timeout. Please try again.',
          code: 'TIMEOUT_ERROR',
          originalException: dioException,
          stackTrace: dioException.stackTrace,
        ),
      DioExceptionType.badResponse => _mapServerError(dioException),
      DioExceptionType.connectionError => NetworkException(
        message: 'No internet connection. Please check your network.',
        code: 'NETWORK_ERROR',
        originalException: dioException,
        stackTrace: dioException.stackTrace,
      ),
      DioExceptionType.cancel => UnknownException(
        message: 'Request cancelled',
        code: 'REQUEST_CANCELLED',
        originalException: dioException,
        stackTrace: dioException.stackTrace,
      ),
      DioExceptionType.unknown => UnknownException(
        message: dioException.message ?? 'An unexpected error occurred',
        code: 'UNKNOWN_ERROR',
        originalException: dioException,
        stackTrace: dioException.stackTrace,
      ),
      _ => UnknownException(
        message: 'An unexpected error occurred',
        code: 'UNKNOWN_ERROR',
        originalException: dioException,
        stackTrace: dioException.stackTrace,
      ),
    };
  }

  AppException _mapServerError(DioException dioException) {
    final statusCode = dioException.response?.statusCode;
    final responseData = dioException.response?.data;

    final message = _getErrorMessage(statusCode, responseData);

    return switch (statusCode) {
      400 => ValidationException(
        message: message,
        code: 'VALIDATION_ERROR',
        originalException: dioException,
        stackTrace: dioException.stackTrace,
      ),
      401 => AuthenticationException(
        message: message,
        code: 'AUTH_ERROR',
        originalException: dioException,
        stackTrace: dioException.stackTrace,
      ),
      403 => AuthorizationException(
        message: message,
        code: 'AUTHORIZATION_ERROR',
        originalException: dioException,
        stackTrace: dioException.stackTrace,
      ),
      _ => ServerException(
        message: message,
        code: 'SERVER_ERROR',
        statusCode: statusCode,
        originalException: dioException,
        stackTrace: dioException.stackTrace,
      ),
    };
  }

  String _getErrorMessage(int? statusCode, dynamic responseData) {
    // Try to extract error message from response
    if (responseData is Map<String, dynamic>) {
      if (responseData.containsKey('message')) {
        return responseData['message'] as String;
      }
      if (responseData.containsKey('error')) {
        return responseData['error'] as String;
      }
    }

    // Fallback to status code message
    return switch (statusCode) {
      400 => 'Invalid request. Please check your input.',
      401 => 'Unauthorized. Please login again.',
      403 => 'Access denied. You do not have permission.',
      404 => 'Resource not found.',
      409 => 'Conflict. This resource already exists.',
      422 => 'Validation failed. Please check your input.',
      429 => 'Too many requests. Please try again later.',
      500 => 'Server error. Please try again later.',
      502 => 'Bad gateway. Please try again later.',
      503 => 'Service unavailable. Please try again later.',
      504 => 'Gateway timeout. Please try again later.',
      _ => 'Server error. Please try again later.',
    };
  }
}

/// Retry Interceptor with exponential backoff
class RetryInterceptor extends Interceptor {
  static const int _maxRetries = 3;
  static const Duration _initialDelay = Duration(milliseconds: 100);

  final Map<String, int> _retryCount = {};

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final key = '${err.requestOptions.method}:${err.requestOptions.path}';
    final retryCount = _retryCount[key] ?? 0;

    // Only retry on specific conditions
    final shouldRetry = _shouldRetry(err, retryCount);

    if (shouldRetry && retryCount < _maxRetries) {
      _retryCount[key] = retryCount + 1;

      final delay = _calculateDelay(retryCount);
      logger.info('Retrying request (attempt ${retryCount + 1}/$_maxRetries) after ${delay.inMilliseconds}ms');

      Future.delayed(delay, () async {
        final response = await _retry(err.requestOptions);
        handler.resolve(response);
      });
    } else {
      _retryCount.remove(key);
      handler.next(err);
    }
  }

  bool _shouldRetry(DioException err, int retryCount) {
    // Don't retry if max retries reached
    if (retryCount >= _maxRetries) return false;

    // Retry on timeout
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      return true;
    }

    // Retry on connection error
    if (err.type == DioExceptionType.connectionError) {
      return true;
    }

    // Retry on 5xx server errors
    if (err.response?.statusCode != null &&
        err.response!.statusCode! >= 500) {
      return true;
    }

    // Retry on 429 (Too Many Requests)
    if (err.response?.statusCode == 429) {
      return true;
    }

    return false;
  }

  Duration _calculateDelay(int retryCount) {
    // Exponential backoff: 100ms, 200ms, 400ms
    return _initialDelay * (1 << retryCount);
  }

  Future<Response> _retry(RequestOptions requestOptions) async {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
      contentType: requestOptions.contentType,
      responseType: requestOptions.responseType,
      validateStatus: requestOptions.validateStatus,
    );

    final dio = Dio();
    return dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
}
