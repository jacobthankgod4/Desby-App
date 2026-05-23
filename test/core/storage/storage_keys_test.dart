import 'package:flutter_test/flutter_test.dart';
import 'package:desby_app/core/storage/storage_keys.dart';

void main() {
  group('StorageKeys', () {
    test('authentication keys are defined', () {
      expect(StorageKeys.accessToken, 'access_token');
      expect(StorageKeys.refreshToken, 'refresh_token');
      expect(StorageKeys.userCredentials, 'user_credentials');
      expect(StorageKeys.isLoggedIn, 'is_logged_in');
    });

    test('user data keys are defined', () {
      expect(StorageKeys.currentUser, 'current_user');
      expect(StorageKeys.userProfile, 'user_profile');
      expect(StorageKeys.userPreferences, 'user_preferences');
      expect(StorageKeys.userSettings, 'user_settings');
    });

    test('app state keys are defined', () {
      expect(StorageKeys.appTheme, 'app_theme');
      expect(StorageKeys.appLanguage, 'app_language');
      expect(StorageKeys.appFirstLaunch, 'app_first_launch');
      expect(StorageKeys.appVersion, 'app_version');
    });

    test('cache keys are defined', () {
      expect(StorageKeys.clientsCache, 'clients_cache');
      expect(StorageKeys.ordersCache, 'orders_cache');
      expect(StorageKeys.designsCache, 'designs_cache');
      expect(StorageKeys.fabricsCache, 'fabrics_cache');
    });

    test('hive box names are defined', () {
      expect(StorageKeys.authBox, 'auth_box');
      expect(StorageKeys.userBox, 'user_box');
      expect(StorageKeys.cacheBox, 'cache_box');
      expect(StorageKeys.preferencesBox, 'preferences_box');
      expect(StorageKeys.offlineBox, 'offline_box');
    });

    test('all keys are unique', () {
      final keys = [
        StorageKeys.accessToken,
        StorageKeys.refreshToken,
        StorageKeys.currentUser,
        StorageKeys.appTheme,
        StorageKeys.clientsCache,
        StorageKeys.authBox,
      ];

      final uniqueKeys = keys.toSet();
      expect(keys.length, uniqueKeys.length, reason: 'Duplicate keys found');
    });
  });

  group('CacheDuration', () {
    test('cache durations are defined', () {
      expect(CacheDuration.user, const Duration(hours: 24));
      expect(CacheDuration.clients, const Duration(hours: 1));
      expect(CacheDuration.orders, const Duration(minutes: 30));
      expect(CacheDuration.designs, const Duration(hours: 2));
      expect(CacheDuration.fabrics, const Duration(hours: 4));
    });

    test('default cache duration is 1 hour', () {
      expect(CacheDuration.default_, const Duration(hours: 1));
    });

    test('cache durations are reasonable', () {
      expect(CacheDuration.user.inHours, greaterThan(0));
      expect(CacheDuration.clients.inMinutes, greaterThan(0));
      expect(CacheDuration.orders.inMinutes, greaterThan(0));
    });
  });
}
