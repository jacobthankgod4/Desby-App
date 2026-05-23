import '../../../../core/error/failures.dart';
import '../entities/user_profile.dart';
import '../repositories/profile_repository.dart';

class GetProfileUsecase {
  final ProfileRepository repository;
  GetProfileUsecase(this.repository);
  Future<Result<UserProfile>> call(String userId) => repository.getProfile(userId);
}

class UpdateProfileUsecase {
  final ProfileRepository repository;
  UpdateProfileUsecase(this.repository);
  Future<Result<UserProfile>> call(UserProfile profile) => repository.updateProfile(profile);
}

class UploadProfileImageUsecase {
  final ProfileRepository repository;
  UploadProfileImageUsecase(this.repository);
  Future<Result<void>> call(String userId, String imagePath) => 
    repository.uploadProfileImage(userId, imagePath);
}
