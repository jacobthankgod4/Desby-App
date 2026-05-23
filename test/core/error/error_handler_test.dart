import 'package:flutter_test/flutter_test.dart';
import 'package:desby_app/core/error/exceptions.dart';
import 'package:desby_app/core/error/failures.dart';
import 'package:desby_app/core/error/error_handler.dart';

void main() {
  group('ErrorHandler', () {
    group('mapExceptionToFailure', () {
      test('maps NetworkException to NetworkFailure', () {
        // Arrange
        final exception = NetworkException(
          message: 'No internet connection',
          code: 'NETWORK_ERROR',
        );

        // Act
        final failure = ErrorHandler.mapExceptionToFailure(exception);

        // Assert
        expect(failure, isA<NetworkFailure>());
        expect(failure.message, 'No internet connection');
        expect(failure.code, 'NETWORK_ERROR');
      });

      test('maps ServerException to ServerFailure', () {
        // Arrange
        final exception = ServerException(
          message: 'Internal server error',
          code: 'SERVER_ERROR',
          statusCode: 500,
        );

        // Act
        final failure = ErrorHandler.mapExceptionToFailure(exception);

        // Assert
        expect(failure, isA<ServerFailure>());
        expect(failure.message, 'Internal server error');
        expect((failure as ServerFailure).statusCode, 500);
      });

      test('maps AuthenticationException to AuthFailure', () {
        // Arrange
        final exception = AuthenticationException(
          message: 'Invalid credentials',
          code: 'AUTH_ERROR',
        );

        // Act
        final failure = ErrorHandler.mapExceptionToFailure(exception);

        // Assert
        expect(failure, isA<AuthFailure>());
        expect(failure.message, 'Invalid credentials');
      });

      test('maps ValidationException to ValidationFailure', () {
        // Arrange
        final exception = ValidationException(
          message: 'Validation failed',
          code: 'VALIDATION_ERROR',
          errors: {'email': 'Invalid email'},
        );

        // Act
        final failure = ErrorHandler.mapExceptionToFailure(exception);

        // Assert
        expect(failure, isA<ValidationFailure>());
        expect(failure.message, 'Validation failed');
        expect((failure as ValidationFailure).errors, {'email': 'Invalid email'});
      });

      test('maps TimeoutException to TimeoutFailure', () {
        // Arrange
        final exception = TimeoutException(
          message: 'Request timeout',
          code: 'TIMEOUT_ERROR',
        );

        // Act
        final failure = ErrorHandler.mapExceptionToFailure(exception);

        // Assert
        expect(failure, isA<TimeoutFailure>());
        expect(failure.message, 'Request timeout');
      });

      test('maps unknown exception to UnknownFailure', () {
        // Arrange
        final exception = Exception('Unknown error');

        // Act
        final failure = ErrorHandler.mapExceptionToFailure(exception);

        // Assert
        expect(failure, isA<UnknownFailure>());
      });
    });

    group('getUserMessage', () {
      test('returns appropriate message for NetworkFailure', () {
        // Arrange
        final failure = NetworkFailure(
          message: 'No internet connection',
        );

        // Act
        final message = ErrorHandler.getUserMessage(failure);

        // Assert
        expect(message, contains('internet'));
      });

      test('returns appropriate message for ServerFailure', () {
        // Arrange
        final failure = ServerFailure(
          message: 'Server error',
          statusCode: 500,
        );

        // Act
        final message = ErrorHandler.getUserMessage(failure);

        // Assert
        expect(message, isNotEmpty);
      });

      test('returns appropriate message for AuthFailure', () {
        // Arrange
        final failure = AuthFailure(
          message: 'Authentication failed',
        );

        // Act
        final message = ErrorHandler.getUserMessage(failure);

        // Assert
        expect(message, contains('login'));
      });

      test('returns appropriate message for ValidationFailure', () {
        // Arrange
        final failure = ValidationFailure(
          message: 'Validation failed',
        );

        // Act
        final message = ErrorHandler.getUserMessage(failure);

        // Assert
        expect(message, isNotEmpty);
      });

      test('returns appropriate message for TimeoutFailure', () {
        // Arrange
        final failure = TimeoutFailure(
          message: 'Request timeout',
        );

        // Act
        final message = ErrorHandler.getUserMessage(failure);

        // Assert
        expect(message, contains('timeout'));
      });
    });
  });

  group('Result Type', () {
    test('Success result returns data', () {
      // Arrange
      final result = Success<String>('test data');

      // Act & Assert
      expect(result.isSuccess, true);
      expect(result.isFailure, false);
      expect(result.getOrNull(), 'test data');
    });

    test('Failure result returns failure', () {
      // Arrange
      final failure = NetworkFailure(message: 'Network error');
      final result = Failure<String>(failure);

      // Act & Assert
      expect(result.isSuccess, false);
      expect(result.isFailure, true);
      expect(result.getFailureOrNull(), failure);
    });

    test('fold works correctly for Success', () {
      // Arrange
      final result = Success<int>(42);

      // Act
      final value = result.fold(
        (failure) => 0,
        (data) => data * 2,
      );

      // Assert
      expect(value, 84);
    });

    test('fold works correctly for Failure', () {
      // Arrange
      final failure = NetworkFailure(message: 'Network error');
      final result = Failure<int>(failure);

      // Act
      final value = result.fold(
        (f) => -1,
        (data) => data,
      );

      // Assert
      expect(value, -1);
    });
  });
}
