/// Centralized Storage Keys
class StorageKeys {
  StorageKeys._(); // Private constructor

  // Authentication
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String rememberMe = "remember_me";
  static const String rememberedEmail = "remembered_email";
  static const String rememberedPassword = "remembered_password";
  static const String userCredentials = 'user_credentials';
  static const String isLoggedIn = 'is_logged_in';
  static const String userType = "user_type";

// User Data
  static const String currentUser = 'current_user';
  static const String userProfile = 'user_profile';
  static const String userPreferences = 'user_preferences';
  static const String userSettings = 'user_settings';

// Onboarding
  static const String tailorOnboardingComplete = 'tailor_onboarding_complete';
  static const String apprenticeOnboardingComplete = 'apprentice_onboarding_complete';
  static const String clientOnboardingComplete = 'client_onboarding_complete';
  
  // Fabric Seller Onboarding
  static const String fabricSellerOnboardingComplete = 'fabric_seller_onboarding_complete';

  // App State
  static const String appTheme = 'app_theme';
  static const String themeMode = 'theme_mode';
  static const String appLanguage = 'app_language';
  static const String appFirstLaunch = 'app_first_launch';
  static const String appVersion = 'app_version';

  // Cache
  static const String clientsCache = 'clients_cache';
  static const String ordersCache = 'orders_cache';
  static const String designsCache = 'designs_cache';
  static const String fabricsCache = 'fabrics_cache';
  static const String suppliersCache = 'suppliers_cache';
  static const String apprenticeshipsCache = 'apprenticeships_cache';
  static const String conversationsCache = 'conversations_cache';
  static const String notificationsCache = 'notifications_cache';

  // Hive Box Names
  static const String authBox = 'auth_box';
  static const String userBox = 'user_box';
  static const String cacheBox = 'cache_box';
  static const String preferencesBox = 'preferences_box';
  static const String offlineBox = 'offline_box';

  // Offline Queue
  static const String offlineQueue = 'offline_queue';
  static const String pendingRequests = 'pending_requests';

  // Analytics
  static const String analyticsEvents = 'analytics_events';
  static const String crashReports = 'crash_reports';

// Device Info
  static const String deviceId = 'device_id';
  static const String deviceToken = 'device_token';
  static const String lastSyncTime = 'last_sync_time';

  // Onboarding State
  static const String appOnboardingComplete = 'app_onboarding_complete';

  // Timestamps
  static const String lastAuthRefresh = 'last_auth_refresh';
  static const String lastDataSync = 'last_data_sync';
  static const String cacheTimestamp = 'cache_timestamp';
}

/// Cache duration constants
class CacheDuration {
  CacheDuration._(); // Private constructor

  static const Duration user = Duration(hours: 24);
  static const Duration clients = Duration(hours: 1);
  static const Duration orders = Duration(minutes: 30);
  static const Duration designs = Duration(hours: 2);
  static const Duration fabrics = Duration(hours: 4);
  static const Duration suppliers = Duration(hours: 4);
  static const Duration apprenticeships = Duration(hours: 1);
  static const Duration conversations = Duration(minutes: 15);
  static const Duration notifications = Duration(minutes: 5);
  static const Duration analytics = Duration(hours: 24);
  static const Duration default_ = Duration(hours: 1);
}
