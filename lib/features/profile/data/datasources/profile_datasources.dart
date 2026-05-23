import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/storage/storage_keys.dart';
import '../models/user_profile_model.dart';

abstract class ProfileRemoteDatasource {
  Future<UserProfileModel> getProfile(String userId);
  Future<UserProfileModel> updateProfile(UserProfileModel profile);
  Future<void> uploadProfileImage(String userId, String imagePath);
}

class ProfileRemoteDatasourceImpl implements ProfileRemoteDatasource {
  final Dio dio;
  ProfileRemoteDatasourceImpl(this.dio);

  @override
  Future<UserProfileModel> getProfile(String userId) async {
    try {
      final response = await dio.get('${ApiEndpoints.userProfile}/$userId');
      return UserProfileModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(
        message: 'Failed to fetch profile',
        code: e.response?.statusCode.toString(),
        originalException: e,
      );
    }
  }

  @override
  Future<UserProfileModel> updateProfile(UserProfileModel profile) async {
    try {
      final response = await dio.put(
        '${ApiEndpoints.userProfile}/${profile.id}',
        data: profile.toJson(),
      );
      return UserProfileModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(
        message: 'Failed to update profile',
        code: e.response?.statusCode.toString(),
        originalException: e,
      );
    }
  }

  @override
  Future<void> uploadProfileImage(String userId, String imagePath) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imagePath),
      });
      await dio.post(
        '${ApiEndpoints.userProfile}/$userId/image',
        data: formData,
      );
    } on DioException catch (e) {
      throw ServerException(
        message: 'Failed to upload image',
        code: e.response?.statusCode.toString(),
        originalException: e,
      );
    }
  }
}

abstract class ProfileLocalDatasource {
  Future<void> cacheProfile(UserProfileModel profile);
  Future<UserProfileModel?> getCachedProfile(String userId);
  Future<void> clearProfile(String userId);
}

class ProfileLocalDatasourceImpl implements ProfileLocalDatasource {
  final LocalStorageService storage;
  ProfileLocalDatasourceImpl(this.storage);

  @override
  Future<void> cacheProfile(UserProfileModel profile) async {
    await storage.save(
      '${StorageKeys.userProfile}_${profile.id}',
      profile.toJson(),
    );
  }

  @override
  Future<UserProfileModel?> getCachedProfile(String userId) async {
    final data = storage.get('${StorageKeys.userProfile}_$userId');
    if (data == null) return null;
    return UserProfileModel.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<void> clearProfile(String userId) async {
    await storage.delete('${StorageKeys.userProfile}_$userId');
  }
}
