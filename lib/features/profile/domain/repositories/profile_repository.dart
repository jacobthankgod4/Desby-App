import '../../../../core/error/failures.dart';
import '../entities/user_profile.dart';

abstract class ProfileRepository {
  Future<Result<UserProfile>> getProfile(String userId);
  Future<Result<UserProfile>> updateProfile(UserProfile profile);
  Future<Result<void>> uploadProfileImage(String userId, String imagePath);
  Future<Result<void>> deleteProfile(String userId);
  Future<Result<List<UserProfile>>> searchMasters(String query);
}
