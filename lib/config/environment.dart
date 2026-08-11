import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment Configuration
class Environment {
  Environment._internal();

  /// Current environment
  static Environment get current => _current;
  static late Environment _current;

  /// Initialize environment from .env file
  static Future<void> initialize() async {
    try {
      // Load .env from assets (works on Web and Mobile/Desktop)
      await dotenv.load(fileName: '.env');
      debugPrint('[ENV] Configuration loaded successfully');
    } catch (e) {
      debugPrint('[ENV] Error loading .env file: $e');
      if (kIsWeb) {
        debugPrint('[ENV] Note: Ensure .env is added to pubspec.yaml assets');
      }
    }
    // Initialize the singleton
    _current = Environment._internal();
  }

  /// API Base URL
  String get apiBaseUrl =>
      _getEnv('API_BASE_URL') ?? 'http://localhost:3000/api';

  /// Korra AI API Base URL (primary measurement/try-on service)
  String get korraApiBaseUrl =>
      _getEnv('KORRA_API_BASE_URL') ?? 'https://korra.work/api/v2';

  /// Korra API Key (for authenticated requests)
  String get korraApiKey => _getEnv('KORRA_API_KEY') ?? '';

  /// Korra Webhook Secret (for verifying incoming webhooks)
  String get korraWebhookSecret => _getEnv('KORRA_WEBHOOK_SECRET') ?? '';

  /// Korra Partner Key (for auto-provisioning API keys for Desby users)
  String get korraPartnerKey => _getEnv('KORRA_PARTNER_KEY') ?? '';

  /// AI Scan API Base URL (legacy alias, points to Korra)
  String get aiScanApiBaseUrl =>
      _getEnv('AI_SCAN_API_BASE_URL') ??
      _getEnv('KORRA_API_BASE_URL') ??
      'https://korra.work/api/v2';

  /// EachLabs API Key (Professional Virtual Try-On)
  String get eachLabsApiKey => _getEnv('EACHLABS_API_KEY') ?? '';

  /// API Timeout (seconds)
  int get apiTimeoutSeconds =>
      int.tryParse(_getEnv('API_TIMEOUT_SECONDS') ?? '30') ?? 30;

  /// API Retry Attempts
  int get apiRetryAttempts =>
      int.tryParse(_getEnv('API_RETRY_ATTEMPTS') ?? '3') ?? 3;

  /// App Environment (development, staging, production)
  String get appEnv => _getEnv('APP_ENV') ?? 'development';

  /// Debug Mode
  bool get debugMode => _getEnv('APP_DEBUG') == 'true';

  /// Supabase URL
  String get supabaseUrl => _getEnv('SUPABASE_URL') ?? '';

  /// Supabase Anon Key
  String get supabaseAnonKey => _getEnv('SUPABASE_ANON_KEY') ?? '';

  /// Supabase Service Role Key
  String get supabaseServiceRoleKey =>
      _getEnv('SUPABASE_SERVICE_ROLE_KEY') ?? '';

  /// Database URL
  String get databaseUrl => _getEnv('DATABASE_URL') ?? '';

  /// Fez Logistics Secret Key
  String get fezLogisticsSecretKey => _getEnv('FEZ_LOGISTICS_SECRET_KEY') ?? '';

  /// Fez Logistics Base URL
  String get fezLogisticsBaseUrl =>
      _getEnv('FEZ_LOGISTICS_BASE_URL') ?? 'https://apisandbox.fezdelivery.co/v1';

  /// Vimeo Client ID
  String get vimeoClientId => _getEnv('VIMEO_CLIENT_ID') ?? '';

  /// Vimeo Client Secret
  String get vimeoClientSecret => _getEnv('VIMEO_CLIENT_SECRET') ?? '';

  /// Vimeo Personal Access Token
  String get vimeoAccessToken => _getEnv('VIMEO_ACCESS_TOKEN') ?? '';

  /// Vimeo Webhook Secret
  String get vimeoWebhookSecret => _getEnv('VIMEO_WEBHOOK_SECRET') ?? '';

  /// Payment Redirect URL
  String get paymentRedirectUrl =>
      _getEnv('PAYMENT_REDIRECT_URL') ?? 'https://desby.app/payment-callback';

  /// App Logo URL
  String get appLogoUrl =>
      _getEnv('APP_LOGO_URL') ??
      'https://aemumiyzowraoachzxtu.supabase.co/storage/v1/object/public/assets/logo.png';

  /// Feature Flags
  bool get enableAnalytics =>
      _getEnv('ENABLE_ANALYTICS') != 'false'; // Default true
  bool get enableCrashReporting =>
      _getEnv('ENABLE_CRASH_REPORTING') != 'false'; // Default true
  bool get enablePerformanceMonitoring =>
      _getEnv('ENABLE_PERFORMANCE_MONITORING') == 'true'; // Default false

  /// Auth Token Refresh Threshold (minutes)
  int get authTokenRefreshThresholdMinutes =>
      int.tryParse(_getEnv('AUTH_TOKEN_REFRESH_THRESHOLD_MINUTES') ?? '5') ?? 5;

  /// Logging
  String get logLevel => _getEnv('LOG_LEVEL') ?? 'debug';
  bool get logToFile => _getEnv('LOG_TO_FILE') == 'true';

  /// Storage
  bool get secureStorageEnabled =>
      _getEnv('SECURE_STORAGE_ENABLED') != 'false'; // Default true
  int get cacheDurationHours =>
      int.tryParse(_getEnv('CACHE_DURATION_HOURS') ?? '24') ?? 24;

  /// Get environment variable safely
  static String? _getEnv(String key) {
    try {
      return dotenv.env[key];
    } catch (e) {
      return null;
    }
  }

  /// Internal: expose env lookup for other config helpers.
  /// Not public API; used by build-time config providers.
  static String? envValue(String key) => _getEnv(key);

  /// Check if staging environment
  bool get isStaging => appEnv == 'staging';

  /// Check if production environment
  bool get isProduction => appEnv == 'production';

  /// Get environment display name
  String get displayName {
    return switch (appEnv) {
      'development' => 'Development',
      'staging' => 'Staging',
      'production' => 'Production',
      _ => 'Unknown',
    };
  }

  /// Print environment info (for debugging)
  void printEnvironmentInfo() {
    debugPrint('''
╔════════════════════════════════════════╗
║     DESBY OS - ENVIRONMENT CONFIG      ║
╠════════════════════════════════════════╣
║ Environment: $displayName
║ Debug Mode: $debugMode
║ API Base URL: $apiBaseUrl
║ API Timeout: ${apiTimeoutSeconds}s
║ Analytics: $enableAnalytics
║ Crash Reporting: $enableCrashReporting
║ Performance Monitoring: $enablePerformanceMonitoring
╚════════════════════════════════════════╝
    ''');
  }
}
