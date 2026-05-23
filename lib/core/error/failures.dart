import 'package:equatable/equatable.dart';

/// Result type for handling success and failure
sealed class Result<T> extends Equatable {
  const Result();

  /// Map success or failure to a new value
  R fold<R>(
    R Function(FailureType) onFailure,
    R Function(T) onSuccess,
  ) {
    return switch (this) {
      Success<T>(:final data) => onSuccess(data),
      Failure<T>(:final failure) => onFailure(failure),
    };
  }

  /// Get data or null
  T? getOrNull() {
    return switch (this) {
      Success<T>(:final data) => data,
      Failure<T>() => null,
    };
  }

  /// Get failure or null
  Failure<T>? getFailureOrNull() {
    return switch (this) {
      Success<T>() => null,
      Failure<T>() => this as Failure<T>,
    };
  }

  /// Check if result is success
  bool get isSuccess => this is Success<T>;

  /// Check if result is failure
  bool get isFailure => this is Failure<T>;
}

/// Success result
class Success<T> extends Result<T> {
  final T data;

  const Success(this.data);

  @override
  List<Object?> get props => [data];
}

/// Failure result
class Failure<T> extends Result<T> {
  final FailureType failure;

  const Failure(this.failure);

  @override
  List<Object?> get props => [failure];
}

/// Base failure type
abstract class FailureType extends Equatable {
  final String message;
  final String? code;

  const FailureType({
    required this.message,
    this.code,
  });

  @override
  String toString() => message;
}

/// Network failure
class NetworkFailure extends FailureType {
  const NetworkFailure({
    required super.message,
    super.code = 'NETWORK_ERROR',
  });

  @override
  List<Object?> get props => [message, code];
}

/// Server failure
class ServerFailure extends FailureType {
  final int? statusCode;

  const ServerFailure({
    required super.message,
    super.code = 'SERVER_ERROR',
    this.statusCode,
  });

  @override
  List<Object?> get props => [message, code, statusCode];
}

/// Authentication failure
class AuthFailure extends FailureType {
  const AuthFailure({
    required super.message,
    super.code = 'AUTH_ERROR',
  });

  @override
  List<Object?> get props => [message, code];
}

/// Authorization failure
class AuthorizationFailure extends FailureType {
  const AuthorizationFailure({
    required super.message,
    super.code = 'AUTHORIZATION_ERROR',
  });

  @override
  List<Object?> get props => [message, code];
}

/// Validation failure
class ValidationFailure extends FailureType {
  final Map<String, String>? errors;

  const ValidationFailure({
    required super.message,
    super.code = 'VALIDATION_ERROR',
    this.errors,
  });

  @override
  List<Object?> get props => [message, code, errors];
}

/// Cache failure
class CacheFailure extends FailureType {
  const CacheFailure({
    required super.message,
    super.code = 'CACHE_ERROR',
  });

  @override
  List<Object?> get props => [message, code];
}

/// Timeout failure
class TimeoutFailure extends FailureType {
  const TimeoutFailure({
    required super.message,
    super.code = 'TIMEOUT_ERROR',
  });

  @override
  List<Object?> get props => [message, code];
}

/// Unknown failure
class UnknownFailure extends FailureType {
  const UnknownFailure({
    required super.message,
    super.code = 'UNKNOWN_ERROR',
  });

  @override
  List<Object?> get props => [message, code];
}
