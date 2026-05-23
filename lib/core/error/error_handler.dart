import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';

import 'exceptions.dart';
import 'failures.dart';

/// Error handler for mapping exceptions to failures
class ErrorHandler {
  ErrorHandler._(); // Private constructor

  /// Map exception to failure
  static FailureType mapExceptionToFailure(dynamic exception) {
    // Handle Firebase exceptions (including web interop issues)
    if (exception is FirebaseException) {
      return _mapFirebaseException(exception);
    } else if (exception is AppException) {
      return _mapAppException(exception);
    } else if (exception is DioException) {
      return _mapDioException(exception);
    } else if (exception is Exception) {
      return UnknownFailure(
        message: safeExceptionString(exception),
        code: 'UNKNOWN_ERROR',
      );
    } else {
      return UnknownFailure(
        message: 'An unexpected error occurred',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Safely convert exception to string (handles Firebase web interop issues)
  /// Public method for use in repositories
  static String safeExceptionString(dynamic e) {
    if (e == null) return 'Unknown error';
    try {
      final str = e.toString();
      return str.isEmpty ? 'Unknown error' : str;
    } catch (_) {
      // Handle JavaScript interop errors on web
      return 'An error occurred (type: ${e.runtimeType})';
    }
  }

  /// Map Firebase exception to failure
  static FailureType _mapFirebaseException(FirebaseException exception) {
    final message = exception.message ?? 'Firebase error';
    final code = exception.code;

    // Common Firebase auth errors
    return switch (code) {
      'user-not-found' => AuthFailure(
        message: 'User not found. Please check your email.',
        code: code,
      ),
      'wrong-password' => AuthFailure(
        message: 'Incorrect password. Please try again.',
        code: code,
      ),
      'invalid-email' => ValidationFailure(
        message: 'Invalid email address.',
        code: code,
      ),
      'email-already-in-use' => ValidationFailure(
        message: 'Email is already registered.',
        code: code,
      ),
      'weak-password' => ValidationFailure(
        message: 'Password is too weak. Use at least 6 characters.',
        code: code,
      ),
      'operation-not-allowed' => AuthFailure(
        message: 'This operation is not allowed.',
        code: code,
      ),
      'network-request-failed' => NetworkFailure(
        message: 'Network error. Please check your connection.',
        code: code,
      ),
      'too-many-requests' => AuthFailure(
        message: 'Too many failed attempts. Please try again later.',
        code: code,
      ),
      _ => AuthFailure(
        message: message,
        code: code,
      ),
    };
  }

  /// Map app exception to failure
  static FailureType _mapAppException(AppException exception) {
    if (exception is NetworkException) {
      return NetworkFailure(
        message: exception.message,
        code: exception.code,
      );
    } else if (exception is ServerException) {
      return ServerFailure(
        message: exception.message,
        code: exception.code,
        statusCode: exception.statusCode,
      );
    } else if (exception is AuthenticationException) {
      return AuthFailure(
        message: exception.message,
        code: exception.code,
      );
    } else if (exception is AuthorizationException) {
      return AuthorizationFailure(
        message: exception.message,
        code: exception.code,
      );
    } else if (exception is ValidationException) {
      return ValidationFailure(
        message: exception.message,
        code: exception.code,
        errors: exception.errors,
      );
    } else if (exception is StorageException) {
      return CacheFailure(
        message: exception.message,
        code: exception.code,
      );
    } else if (exception is CacheException) {
      return CacheFailure(
        message: exception.message,
        code: exception.code,
      );
    } else if (exception is TimeoutException) {
      return TimeoutFailure(
        message: exception.message,
        code: exception.code,
      );
    } else if (exception is UnknownException) {
      return UnknownFailure(
        message: exception.message,
        code: exception.code,
      );
    } else {
      return UnknownFailure(
        message: 'An unexpected error occurred',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Map Dio exception to failure
  static FailureType _mapDioException(DioException exception) {
    return switch (exception.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout =>
        TimeoutFailure(
          message: 'Request timeout. Please try again.',
          code: 'TIMEOUT_ERROR',
        ),
      DioExceptionType.badResponse => ServerFailure(
        message: _getServerErrorMessage(exception.response?.statusCode),
        code: 'SERVER_ERROR',
        statusCode: exception.response?.statusCode,
      ),
      DioExceptionType.connectionError => NetworkFailure(
        message: 'No internet connection. Please check your network.',
        code: 'NETWORK_ERROR',
      ),
      DioExceptionType.cancel => UnknownFailure(
        message: 'Request cancelled',
        code: 'REQUEST_CANCELLED',
      ),
      DioExceptionType.unknown => UnknownFailure(
        message: exception.message ?? 'An unexpected error occurred',
        code: 'UNKNOWN_ERROR',
      ),
      _ => UnknownFailure(
        message: 'An unexpected error occurred',
        code: 'UNKNOWN_ERROR',
      ),
    };
  }

  /// Get user-friendly server error message
  static String _getServerErrorMessage(int? statusCode) {
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

  /// Get user-friendly error message
  static String getUserMessage(FailureType failure) {
    if (failure is NetworkFailure) {
      return 'No internet connection. Please check your network.';
    } else if (failure is ServerFailure) {
      return _getServerErrorMessage(failure.statusCode);
    } else if (failure is AuthFailure) {
      return failure.message;
    } else if (failure is AuthorizationFailure) {
      return 'You do not have permission to perform this action.';
    } else if (failure is ValidationFailure) {
      return failure.message;
    } else if (failure is CacheFailure) {
      return 'Failed to load data. Please try again.';
    } else if (failure is TimeoutFailure) {
      return 'Request timeout. Please try again.';
    } else if (failure is UnknownFailure) {
      return failure.message;
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }
}
