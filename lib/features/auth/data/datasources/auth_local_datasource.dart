import '../../../../core/storage/local_storage.dart';
import '../../../../core/storage/storage_keys.dart';

abstract class AuthLocalDatasource {
  Future<void> saveTokens(String accessToken, String refreshToken);
  String? getAccessToken();
  String? getRefreshToken();
  Future<void> clearTokens();
}

class AuthLocalDatasourceImpl implements AuthLocalDatasource {
  final LocalStorageService storage;

  AuthLocalDatasourceImpl(this.storage);

  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await storage.save(StorageKeys.accessToken, accessToken);
    await storage.save(StorageKeys.refreshToken, refreshToken);
  }

  @override
  String? getAccessToken() {
    return storage.get(StorageKeys.accessToken);
  }

  @override
  String? getRefreshToken() {
    return storage.get(StorageKeys.refreshToken);
  }

  @override
  Future<void> clearTokens() async {
    await storage.delete(StorageKeys.accessToken);
    await storage.delete(StorageKeys.refreshToken);
  }
}
