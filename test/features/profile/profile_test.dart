import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:desby_app/core/error/failures.dart';
import 'package:desby_app/features/profile/domain/entities/user_profile.dart';
import 'package:desby_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:desby_app/features/profile/domain/usecases/profile_usecases.dart';

@GenerateMocks([ProfileRepository])
import 'profile_test.mocks.dart';

void main() {
  late GetProfileUsecase getProfile;
  late UpdateProfileUsecase updateProfile;
  late MockProfileRepository mockRepository;

  setUp(() {
    mockRepository = MockProfileRepository();
    getProfile = GetProfileUsecase(mockRepository);
    updateProfile = UpdateProfileUsecase(mockRepository);
    provideDummy<Result<UserProfile>>(Failure(ServerFailure(message: 'dummy')));
  });

  final tProfile = UserProfile(
    id: 'user_1',
    email: 'test@example.com',
    name: 'Test User',
    userType: 'tailor',
    phone: '+2348012345678',
    createdAt: DateTime(2024),
  );

  group('GetProfileUsecase', () {
    test('should return UserProfile on success', () async {
      when(mockRepository.getProfile(any))
          .thenAnswer((_) async => Success(tProfile));

      final result = await getProfile('user_1');

      expect(result, isA<Success>());
      result.fold(
        (failure) => fail('Should not return failure'),
        (profile) => expect(profile.name, 'Test User'),
      );
    });

    test('should return Failure when profile not found', () async {
      when(mockRepository.getProfile(any))
          .thenAnswer((_) async => Failure(ServerFailure(message: 'Not found')));

      final result = await getProfile('user_1');

      expect(result, isA<Failure>());
    });
  });

  group('UpdateProfileUsecase', () {
    test('should update profile successfully', () async {
      when(mockRepository.updateProfile(any))
          .thenAnswer((_) async => Success(tProfile));

      final result = await updateProfile(tProfile);

      expect(result, isA<Success>());
      verify(mockRepository.updateProfile(tProfile)).called(1);
    });

    test('should return Failure on update error', () async {
      when(mockRepository.updateProfile(any))
          .thenAnswer((_) async => Failure(ValidationFailure(message: 'Invalid data')));

      final result = await updateProfile(tProfile);

      expect(result, isA<Failure>());
    });
  });
}
