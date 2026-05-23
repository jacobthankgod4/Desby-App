import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'interceptors.dart';

final dioProvider = Provider<Dio>((ref) => DioClient().dio);

/// Dio HTTP Client Configuration
class DioClient {
  static final DioClient _instance = DioClient._internal();

  late final Dio _dio;

  factory DioClient() {
    return _instance;
  }

  DioClient._internal() {
    _dio = Dio(
      BaseOptions(
        // On web, allow overriding via dart-define; otherwise fall back.
        baseUrl: _getEnv('API_BASE_URL') ?? const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3000/api'),
        connectTimeout: Duration(
          seconds: int.tryParse(
                _getEnv('API_TIMEOUT_SECONDS') ?? '30',
              ) ??
              30,
        ),
        receiveTimeout: Duration(
          seconds: int.tryParse(
                _getEnv('API_TIMEOUT_SECONDS') ?? '30',
              ) ??
              30,
        ),
        sendTimeout: Duration(
          seconds: int.tryParse(
                _getEnv('API_TIMEOUT_SECONDS') ?? '30',
              ) ??
              30,
        ),
        contentType: 'application/json',
        responseType: ResponseType.json,
        validateStatus: (status) {
          return status != null && status < 500;
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.addAll([
      LoggingInterceptor(),
      AuthInterceptor(),
      ErrorInterceptor(),
      RetryInterceptor(),
    ]);
  }

  /// Safe environment variable access
  static String? _getEnv(String key) {
    try {
      return dotenv.env[key];
    } catch (e) {
      return null;
    }
  }

  /// Get Dio instance
  Dio get dio => _dio;

  /// Set authorization token
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Clear authorization token
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// Set custom header
  void setHeader(String key, String value) {
    _dio.options.headers[key] = value;
  }

  /// Remove custom header
  void removeHeader(String key) {
    _dio.options.headers.remove(key);
  }

  /// Update base URL
  void updateBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
  }

  /// Update timeout
  void updateTimeout(Duration timeout) {
    _dio.options.connectTimeout = timeout;
    _dio.options.receiveTimeout = timeout;
    _dio.options.sendTimeout = timeout;
  }

  /// Close Dio instance
  void close() {
    _dio.close();
  }
}

/// Global Dio client instance (lazy initialization)
DioClient? _dioClientInstance;

DioClient get dioClient {
  return _dioClientInstance ??= DioClient();
}
