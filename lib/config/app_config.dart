/// App Configuration
class AppConfig {
  AppConfig._(); // Private constructor

  // App Metadata
  static const String appName = 'Desby OS';
  static const String appDescription =
      'Digital operating system for tailors and fashion entrepreneurs';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // Feature Flags
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  static const bool enablePerformanceMonitoring = false;
  static const bool enableOfflineMode = true;
  static const bool enableDebugLogging = true;

  // App Settings
  static const Duration tokenRefreshThreshold = Duration(minutes: 5);
  static const Duration cacheDefaultDuration = Duration(hours: 1);
  static const int maxRetryAttempts = 3;
  static const Duration initialRetryDelay = Duration(milliseconds: 100);

  // UI Settings
  static const bool enableAnimations = true;
  static const bool enableHapticFeedback = true;
  static const bool enableSoundEffects = false;

  // Security Settings
  static const bool enableBiometricAuth = true;
  static const bool enablePinAuth = true;
  static const bool enableTwoFactorAuth = false;

  // API Settings
  static const int apiTimeoutSeconds = 30;
  static const int maxConcurrentRequests = 5;

  // Storage Settings
  static const bool enableLocalCaching = true;
  static const bool enableSecureStorage = true;
  static const int maxCacheSize = 100; // MB

  // Logging Settings
  static const bool logNetworkRequests = true;
  static const bool logNetworkResponses = true;
  static const bool logErrors = true;
  static const bool logAnalyticsEvents = true;

  // Supported Languages
  static const List<String> supportedLanguages = ['en', 'es', 'fr', 'de'];
  static const String defaultLanguage = 'en';

  // Supported Currencies
  static const List<String> supportedCurrencies = ['USD', 'EUR', 'GBP', 'INR'];
  static const String defaultCurrency = 'USD';

  // Contact & Support
  static const String supportEmail = 'support@desby.app';
  static const String supportPhone = '+1-800-DESBY-OS';
  static const String websiteUrl = 'https://desby.app';
  static const String privacyPolicyUrl = 'https://desby.app/privacy';
  static const String termsOfServiceUrl = 'https://desby.app/terms';

  // Social Media
  static const String twitterHandle = '@desbyos';
  static const String instagramHandle = '@desbyos';
  static const String linkedinUrl = 'https://linkedin.com/company/desby';

  // Rate Limiting
  static const int rateLimitRequestsPerMinute = 60;
  static const int rateLimitRequestsPerHour = 1000;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Search
  static const int minSearchQueryLength = 2;
  static const int maxSearchResults = 50;

  // File Upload
  static const int maxFileUploadSizeMB = 50;
  static const List<String> allowedFileTypes = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'pdf',
    'doc',
    'docx'
  ];

  // Image Settings
  static const int imageCompressionQuality = 85;
  static const int thumbnailSize = 200;
  static const int previewSize = 800;

  // Notification Settings
  static const bool enablePushNotifications = true;
  static const bool enableEmailNotifications = true;
  static const bool enableSmsNotifications = false;

  // Analytics Events
  static const bool trackUserActions = true;
  static const bool trackPageViews = true;
  static const bool trackErrors = true;
  static const bool trackPerformance = true;

  /// Get app version string
  static String get versionString => '$appVersion+$appBuildNumber';

  /// Check if app is in debug mode
  static bool get isDebugMode {
    bool inDebugMode = false;
    assert(inDebugMode = true);
    return inDebugMode;
  }

  /// Check if app is in production mode
  static bool get isProduction => !isDebugMode;
}
