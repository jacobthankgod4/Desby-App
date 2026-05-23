import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../logging/logger.dart';
import 'storage_keys.dart';

/// Secure Storage Service
/// Handles secure storage of tokens and sensitive data
class SecureStorageService {
  static final SecureStorageService _instance =
      SecureStorageService._internal();

  late final FlutterSecureStorage _storage;

  factory SecureStorageService() {
    return _instance;
  }

  SecureStorageService._internal() {
    _storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
        storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
      ),
    );
  }

  /// Save access token
  Future<void> saveAccessToken(String token) async {
    try {
      await _storage.write(
        key: StorageKeys.accessToken,
        value: token,
      );
      logger.debug('Access token saved securely');
    } catch (e, stackTrace) {
      logger.error(
        'Failed to save access token',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: StorageKeys.accessToken);
    } catch (e, stackTrace) {
      logger.error(
        'Failed to read access token',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    try {
      await _storage.write(
        key: StorageKeys.refreshToken,
        value: token,
      );
      logger.debug('Refresh token saved securely');
    } catch (e, stackTrace) {
      logger.error(
        'Failed to save refresh token',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: StorageKeys.refreshToken);
    } catch (e, stackTrace) {
      logger.error(
        'Failed to read refresh token',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Save both tokens
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      await Future.wait([
        saveAccessToken(accessToken),
        saveRefreshToken(refreshToken),
      ]);
      logger.debug('Tokens saved securely');
    } catch (e, stackTrace) {
      logger.error(
        'Failed to save tokens',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Clear all tokens
  Future<void> clearTokens() async {
    try {
      await Future.wait([
        _storage.delete(key: StorageKeys.accessToken),
        _storage.delete(key: StorageKeys.refreshToken),
      ]);
      logger.debug('Tokens cleared');
    } catch (e, stackTrace) {
      logger.error(
        'Failed to clear tokens',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Save user credentials
  Future<void> saveCredentials({
    required String email,
    required String password,
  }) async {
    try {
      await _storage.write(
        key: StorageKeys.userCredentials,
        value: '$email:$password',
      );
      logger.debug('Credentials saved securely');
    } catch (e, stackTrace) {
      logger.error(
        'Failed to save credentials',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get user credentials
  Future<Map<String, String>?> getCredentials() async {
    try {
      final credentials =
          await _storage.read(key: StorageKeys.userCredentials);
      if (credentials == null) return null;

      final parts = credentials.split(':');
      if (parts.length != 2) return null;

      return {
        'email': parts[0],
        'password': parts[1],
      };
    } catch (e, stackTrace) {
      logger.error(
        'Failed to read credentials',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Clear credentials
  Future<void> clearCredentials() async {
    try {
      await _storage.delete(key: StorageKeys.userCredentials);
      logger.debug('Credentials cleared');
    } catch (e, stackTrace) {
      logger.error(
        'Failed to clear credentials',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Save generic secure value
  Future<void> saveSecureValue(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      logger.debug('Secure value saved: $key');
    } catch (e, stackTrace) {
      logger.error(
        'Failed to save secure value: $key',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get generic secure value
  Future<String?> getSecureValue(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e, stackTrace) {
      logger.error(
        'Failed to read secure value: $key',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Delete generic secure value
  Future<void> deleteSecureValue(String key) async {
    try {
      await _storage.delete(key: key);
      logger.debug('Secure value deleted: $key');
    } catch (e, stackTrace) {
      logger.error(
        'Failed to delete secure value: $key',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Clear all secure storage
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
      logger.debug('All secure storage cleared');
    } catch (e, stackTrace) {
      logger.error(
        'Failed to clear all secure storage',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}

/// Global secure storage instance
final secureStorage = SecureStorageService();
