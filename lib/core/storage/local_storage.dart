import 'package:hive_flutter/hive_flutter.dart';
import '../logging/logger.dart';
import 'storage_keys.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();

  late final Box<dynamic> _authBox;
  late final Box<dynamic> _userBox;
  late final Box<dynamic> _cacheBox;
  late final Box<dynamic> _preferencesBox;
  late final Box<dynamic> _offlineBox;

  bool _initialized = false;

  factory LocalStorageService() {
    return _instance;
  }

  LocalStorageService._internal();

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Hive.initFlutter();

      _authBox = await Hive.openBox<dynamic>(StorageKeys.authBox);
      _userBox = await Hive.openBox<dynamic>(StorageKeys.userBox);
      _cacheBox = await Hive.openBox<dynamic>(StorageKeys.cacheBox);
      _preferencesBox = await Hive.openBox<dynamic>(StorageKeys.preferencesBox);
      _offlineBox = await Hive.openBox<dynamic>(StorageKeys.offlineBox);

      _initialized = true;
      logger.info('Local storage initialized successfully');
    } catch (e, stackTrace) {
      logger.error('Failed to initialize local storage', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

Future<void> saveAuthValue(String key, dynamic value) async {
    if (!_initialized) {
      // Silently return if not initialized - will be saved after init
      return;
    }
    await _authBox.put(key, value);
  }

  dynamic getAuthValue(String key, {dynamic defaultValue}) {
    if (!_initialized) {
      // Silently return default if not initialized - will be loaded after init
      return defaultValue;
    }
    return _authBox.get(key, defaultValue: defaultValue);
  }

  Future<void> deleteAuthValue(String key) async {
    if (!_initialized) return;
    await _authBox.delete(key);
  }

  Future<void> saveUserData(String key, dynamic value) async {
    await _userBox.put(key, value);
  }

  dynamic getUserData(String key, {dynamic defaultValue}) {
    return _userBox.get(key, defaultValue: defaultValue);
  }

  Future<void> savePreference(String key, dynamic value) async {
    await _preferencesBox.put(key, value);
  }

  dynamic getPreference(String key, {dynamic defaultValue}) {
    return _preferencesBox.get(key, defaultValue: defaultValue);
  }

  Future<void> clearAll() async {
    await Future.wait([
      _authBox.clear(),
      _userBox.clear(),
      _cacheBox.clear(),
      _preferencesBox.clear(),
      _offlineBox.clear(),
    ]);
  }

  Future<void> save(String key, dynamic value) => saveAuthValue(key, value);
  dynamic get(String key, {dynamic defaultValue}) => getAuthValue(key, defaultValue: defaultValue);
  Future<void> delete(String key) => deleteAuthValue(key);

  Future<void> saveCache(String key, dynamic value) async {
    if (!_initialized) return;
    await _cacheBox.put(key, value);
  }

  dynamic getCache(String key, {dynamic defaultValue}) {
    if (!_initialized) return defaultValue;
    return _cacheBox.get(key, defaultValue: defaultValue);
  }

  Future<void> deleteCache(String key) async {
    if (!_initialized) return;
    await _cacheBox.delete(key);
  }
}

final localStorage = LocalStorageService();
