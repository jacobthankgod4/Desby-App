import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:desby_app/core/error/failures.dart';
import 'package:desby_app/features/auth/domain/entities/auth_response.dart';
import 'package:desby_app/features/auth/domain/entities/user.dart';
import 'package:desby_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:desby_app/features/auth/domain/usecases/register_usecase.dart';

@GenerateMocks([AuthRepository])
import 'register_usecase_test.mocks.dart';

void main() {
  late RegisterUsecase usecase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = RegisterUsecase(mockRepository);
    provideDummy<Result<AuthResponse>>(Failure(ServerFailure(message: 'dummy')));
  });

  group('RegisterUsecase', () {
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

    test('should return AuthResponse when registration is successful', () async {
      when(mockRepository.register(
        'test@example.com',
        'password',
        'Test User',
        'tailor',
      )).thenAnswer((_) async => Success(tAuthResponse));

      final result = await usecase(
        'test@example.com',
        'password',
        'Test User',
        'tailor',
      );

      expect(result, isA<Success>());
      verify(mockRepository.register(
        'test@example.com',
        'password',
        'Test User',
        'tailor',
      )).called(1);
    });

    test('should return Failure when registration fails', () async {
      final tFailure = ServerFailure(message: 'Registration failed');
      when(mockRepository.register(
        'test@example.com',
        'password',
        'Test User',
        'tailor',
      )).thenAnswer((_) async => Failure(tFailure));

      final result = await usecase(
        'test@example.com',
        'password',
        'Test User',
        'tailor',
      );

      expect(result, isA<Failure>());
      result.fold(
        (failure) => expect(failure.message, 'Registration failed'),
        (authResponse) => fail('Should not return success'),
      );
    });
  });
}
