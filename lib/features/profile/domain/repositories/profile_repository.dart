import 'dart:typed_data';
import '../../../../core/error/failures.dart';
import '../entities/user_profile.dart';

abstract class ProfileRepository {
  Future<Result<UserProfile>> getProfile(String userId);
  Future<Result<UserProfile>> updateProfile(UserProfile profile);
  Future<Result<void>> uploadProfileImage(String userId, String imagePath);
  Future<Result<void>> uploadProfileImageBytes(String userId, Uint8List bytes);
  Future<Result<void>> deleteProfile(String userId);
  Future<Result<List<UserProfile>>> searchMasters(String query);
}
