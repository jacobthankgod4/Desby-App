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
    // On web, flutter_dotenv cannot load files from disk.
    // Use dart-define environment variables instead: flutter run --dart-define=KEY=value
    if (!kIsWeb) {
      try {
        await dotenv.load(fileName: '.env');
      } catch (e) {
        // .env file not found on mobile/desktop, use defaults
        debugPrint('[ENV] Note: .env file not found, using default configuration');
      }
    }
    // Initialize the singleton
    _current = Environment._internal();
  }

  /// API Base URL
  String get apiBaseUrl =>
      _getEnv('API_BASE_URL') ?? 'http://localhost:3000/api';

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

  /// Firebase Project ID
  String? get firebaseProjectId => _getEnv('FIREBASE_PROJECT_ID');

  /// Firebase API Key
  String? get firebaseApiKey => _getEnv('FIREBASE_API_KEY');

  /// Feature Flags
  bool get enableAnalytics =>
      _getEnv('ENABLE_ANALYTICS') != 'false'; // Default true
  bool get enableCrashReporting =>
      _getEnv('ENABLE_CRASH_REPORTING') != 'false'; // Default true
  bool get enablePerformanceMonitoring =>
      _getEnv('ENABLE_PERFORMANCE_MONITORING') == 'true'; // Default false

  /// Auth Token Refresh Threshold (minutes)
  int get authTokenRefreshThresholdMinutes =>
      int.tryParse(_getEnv('AUTH_TOKEN_REFRESH_THRESHOLD_MINUTES') ?? '5') ??
      5;

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
