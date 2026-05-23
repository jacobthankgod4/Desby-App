import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:desby_app/core/error/failures.dart';
import 'package:desby_app/features/auth/domain/entities/auth_response.dart';
import 'package:desby_app/features/auth/domain/entities/user.dart';
import 'package:desby_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:desby_app/features/auth/domain/usecases/login_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}




void main() {
  late LoginUsecase usecase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = LoginUsecase(mockRepository);
  });

  group('LoginUsecase', () {
    final tUser = User(
      id: '1',
      email: 'test@example.com',
      name: 'Test User',
      userType: 'tailor',
      createdAt: DateTime.now(),
    );

    final tAuthResponse = AuthResponse(
      user: tUser,
      accessToken: 'access_token',
      refreshToken: 'refresh_token',
      expiresIn: 3600,
    );

    test('should return AuthResponse when login is successful', () async {
      // Arrange
      when(mockRepository.login('test@example.com', 'password'))
          .thenAnswer((_) async => Success(tAuthResponse));

      // Act
      final result = await usecase('test@example.com', 'password');


      // Assert
      expect(result, isA<Success>());
      result.fold(
        (failure) => fail('Should not return failure'),
        (authResponse) {
          expect(authResponse.user.email, 'test@example.com');
          expect(authResponse.accessToken, 'access_token');
        },
      );

      verify(mockRepository.login('test@example.com', 'password')).called(1);
    });

    test('should return Failure when login fails', () async {
      // Arrange
      final tFailure = ServerFailure(message: 'Login failed');
      when(mockRepository.login('test@example.com', 'password'))
          .thenAnswer((_) async => Failure(tFailure));

      // Act
      final result = await usecase('test@example.com', 'password');

      // Assert
      expect(result, isA<Failure>());
      result.fold(
        (failure) => expect(failure.message, 'Login failed'),
        (authResponse) => fail('Should not return success'),
      );
    });
  });
}
