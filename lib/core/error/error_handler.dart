import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'exceptions.dart' as local_ex;
import 'failures.dart';

/// Centralized error handler to map exceptions to failures
class ErrorHandler {
  /// Map any exception to a failure type
  static FailureType mapExceptionToFailure(dynamic exception) {
    // Handle Supabase exceptions
    if (exception is sb.AuthException) {
      if (exception.message.contains('SyntaxError') || exception.message.contains('JSON')) {
        return const AuthFailure(message: 'Login service handshake failed. Check your internet connection or Supabase project status.');
      }
      return AuthFailure(message: exception.message);
    }
    
    if (exception is FormatException) {
      return const AuthFailure(message: 'Malformed response from authentication server.');
    }
    if (exception is sb.PostgrestException) {
      return ServerFailure(message: exception.message);
    }
    if (exception is sb.StorageException) {
      return StorageFailure(message: exception.message);
    }

    // Handle local exceptions
    if (exception is local_ex.AppException) {
      return _mapAppException(exception);
    }

    // Default unknown failure
    return UnknownFailure(
      message: exception.toString(),
    );
  }

  /// Map app exception to failure
  static FailureType _mapAppException(local_ex.AppException exception) {
    return switch (exception) {
      local_ex.NetworkException(:final message) => NetworkFailure(
          message: message,
        ),
      local_ex.ServerException(:final message, :final code) => ServerFailure(
          message: message,
          code: code,
        ),
      local_ex.CacheException(:final message) => CacheFailure(
          message: message,
        ),
      local_ex.ValidationException(:final message) => ValidationFailure(
          message: message,
        ),
      local_ex.AuthenticationException(:final message) => AuthFailure(
          message: message,
        ),
      local_ex.AuthorizationException(:final message) => AuthorizationFailure(
          message: message,
        ),
      local_ex.StorageException(:final message) => StorageFailure(
          message: message,
        ),
      local_ex.TimeoutException(:final message) => TimeoutFailure(
          message: message,
        ),
      local_ex.UnknownException(:final message) => UnknownFailure(
          message: message,
        ),
      _ => UnknownFailure(message: exception.toString()),
    };
  }

  /// Get user-friendly message for a failure
  static String getUserMessage(FailureType failure) {
    return failure.message;
  }

  /// Safely convert exception to string
  static String safeExceptionString(dynamic exception) {
    try {
      return exception.toString();
    } catch (e) {
      return 'Unknown error occurred';
    }
  }
}
