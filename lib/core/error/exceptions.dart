/// Custom exception hierarchy for Desby OS
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalException;
  final StackTrace? stackTrace;

  AppException({
    required this.message,
    this.code,
    this.originalException,
    this.stackTrace,
  });

  @override
  String toString() => message;
}

/// Network-related exceptions
class NetworkException extends AppException {
  NetworkException({
    required super.message,
    super.code = 'NETWORK_ERROR',
    super.originalException,
    super.stackTrace,
  });
}

/// Server-related exceptions
class ServerException extends AppException {
  final int? statusCode;

  ServerException({
    required super.message,
    super.code = 'SERVER_ERROR',
    this.statusCode,
    super.originalException,
    super.stackTrace,
  });
}

/// Authentication exceptions
class AuthenticationException extends AppException {
  AuthenticationException({
    required super.message,
    super.code = 'AUTH_ERROR',
    super.originalException,
    super.stackTrace,
  });
}

/// Authorization exceptions
class AuthorizationException extends AppException {
  AuthorizationException({
    required super.message,
    super.code = 'AUTHORIZATION_ERROR',
    super.originalException,
    super.stackTrace,
  });
}

/// Validation exceptions
class ValidationException extends AppException {
  final Map<String, String>? errors;

  ValidationException({
    required super.message,
    super.code = 'VALIDATION_ERROR',
    this.errors,
    super.originalException,
    super.stackTrace,
  });
}

/// Storage exceptions
class StorageException extends AppException {
  StorageException({
    required super.message,
    super.code = 'STORAGE_ERROR',
    super.originalException,
    super.stackTrace,
  });
}

/// Cache exceptions
class CacheException extends AppException {
  CacheException({
    required super.message,
    super.code = 'CACHE_ERROR',
    super.originalException,
    super.stackTrace,
  });
}

/// Timeout exceptions
class TimeoutException extends AppException {
  TimeoutException({
    required super.message,
    super.code = 'TIMEOUT_ERROR',
    super.originalException,
    super.stackTrace,
  });
}

/// Unknown exceptions
class UnknownException extends AppException {
  UnknownException({
    required super.message,
    super.code = 'UNKNOWN_ERROR',
    super.originalException,
    super.stackTrace,
  });
}
