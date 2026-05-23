import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:desby_app/core/error/exceptions.dart';
import 'package:desby_app/core/error/failures.dart';
import 'package:desby_app/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:desby_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:desby_app/features/auth/data/models/auth_response_model.dart';
import 'package:desby_app/features/auth/data/models/user_model.dart';
import 'package:desby_app/features/auth/data/repositories/auth_repository_impl.dart';

class MockAuthRemoteDatasource extends Mock implements AuthRemoteDatasource {}

class MockAuthLocalDatasource extends Mock implements AuthLocalDatasource {}


void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDatasource mockRemoteDatasource;
  late MockAuthLocalDatasource mockLocalDatasource;

  setUp(() {
    mockRemoteDatasource = MockAuthRemoteDatasource();
    mockLocalDatasource = MockAuthLocalDatasource();
    repository = AuthRepositoryImpl(
      remoteDatasource: mockRemoteDatasource,
      localDatasource: mockLocalDatasource,
    );
  });

  group('AuthRepositoryImpl', () {
    final tUserModel = UserModel(
      id: '1',
      email: 'test@example.com',
      name: 'Test User',
      userType: 'tailor',
      createdAt: DateTime.now(),
    );

    final tAuthResponseModel = AuthResponseModel(
      user: tUserModel,
      accessToken: 'access_token',
      refreshToken: 'refresh_token',
      expiresIn: 3600,
    );

    group('login', () {
      test('should return AuthResponse when login is successful', () async {
        // Arrange
        when(mockRemoteDatasource.login('test@example.com', 'password'))
            .thenAnswer((_) async => tAuthResponseModel);
        when(mockLocalDatasource.saveTokens('access_token', 'refresh_token'))
            .thenAnswer((_) async => Future.value({}));


        // Act
        final result = await repository.login('test@example.com', 'password');

        // Assert
        expect(result, isA<Success>());
        result.fold(
          (failure) => fail('Should not return failure'),
          (authResponse) {
            expect(authResponse.user.email, 'test@example.com');
            expect(authResponse.accessToken, 'access_token');
          },
        );

        verify(mockRemoteDatasource.login('test@example.com', 'password'))
            .called(1);
        verify(mockLocalDatasource.saveTokens('access_token', 'refresh_token'))
            .called(1);
      });

      test('should return Failure when login fails', () async {
        // Arrange
        when(mockRemoteDatasource.login('test@example.com', 'password'))
            .thenThrow(ServerException(message: 'Login failed'));

        // Act
        final result = await repository.login('test@example.com', 'password');

        // Assert
        expect(result, isA<Failure>());
        result.fold(
          (failure) => expect(failure.message, contains('Login failed')),
          (authResponse) => fail('Should not return success'),
        );
      });
    });

    group('register', () {
      test('should return AuthResponse when registration is successful', () async {
        // Arrange
        when(mockRemoteDatasource.register(
          'test@example.com',
          'password',
          'Test User',
          'tailor',
        )).thenAnswer((_) async => tAuthResponseModel);
        when(mockLocalDatasource.saveTokens('access_token', 'refresh_token'))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.register(
          'test@example.com',
          'password',
          'Test User',
          'tailor',
        );

        // Assert
        expect(result, isA<Success>());
        verify(mockRemoteDatasource.register(
          'test@example.com',
          'password',
          'Test User',
          'tailor',
        )).called(1);
      });
    });

    group('logout', () {
      test('should clear tokens when logout is successful', () async {
        // Arrange
        when(mockRemoteDatasource.logout()).thenAnswer((_) async => {});
        when(mockLocalDatasource.clearTokens()).thenAnswer((_) async => {});

        // Act
        final result = await repository.logout();

        // Assert
        expect(result, isA<Success>());
        verify(mockRemoteDatasource.logout()).called(1);
        verify(mockLocalDatasource.clearTokens()).called(1);
      });
    });

    group('saveTokens', () {
      test('should save tokens successfully', () async {
        // Arrange
        when(mockLocalDatasource.saveTokens('access', 'refresh'))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.saveTokens('access', 'refresh');

        // Assert
        expect(result, isA<Success>());
        verify(mockLocalDatasource.saveTokens('access', 'refresh')).called(1);
      });
    });

    group('getAccessToken', () {
      test('should return access token', () async {
        // Arrange
        when(mockLocalDatasource.getAccessToken())
            .thenAnswer((_) async => 'access_token');

        // Act
        final result = await repository.getAccessToken();

        // Assert
        expect(result, isA<Success>());
        result.fold(
          (failure) => fail('Should not return failure'),
          (token) => expect(token, 'access_token'),
        );
      });
    });

    group('clearTokens', () {
      test('should clear tokens successfully', () async {
        // Arrange
        when(mockLocalDatasource.clearTokens()).thenAnswer((_) async => {});

        // Act
        final result = await repository.clearTokens();

        // Assert
        expect(result, isA<Success>());
        verify(mockLocalDatasource.clearTokens()).called(1);
      });
    });
  });
}
