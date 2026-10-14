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
  ///
  /// Empty on web **by design**: desby.app serves nginx `location /api/` →
  /// `korra_backend`, so Dio resolving `/api/v2/...` against the page origin is
  /// the intended path and keeps the app same-origin (no CORS, no key in a
  /// cross-site request).
  ///
  /// The risk is everywhere else. `_getEnv` returns '' for
  /// `KORRA_API_BASE_URL=` (never null), so the default below can never fire,
  /// and a mobile/desktop build — or any deploy without that proxy — silently
  /// resolved every request against its own origin and failed with a baffling
  /// 404. Off-web there is no same-origin proxy to fall back on, so fall back to
  /// the absolute host and say so once.
  String get korraApiBaseUrl {
    final configured = _getEnv('KORRA_API_BASE_URL');
    if (configured != null && configured.trim().isNotEmpty) return configured.trim();
    if (kIsWeb) return '';
    debugPrint(
      '[ENV] KORRA_API_BASE_URL is empty and this is not web — '
      'there is no same-origin /api proxy, so falling back to korra.work. '
      'Set KORRA_API_BASE_URL explicitly to silence this.',
    );
    return 'https://korra.work/api/v2';
  }

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

  /// EachLabs API Base URL
  String get eachLabsBaseUrl =>
      _getEnv('EACHLABS_BASE_URL') ?? 'https://api.eachlabs.ai/v1/prediction';

  /// Magic Hour API Key (AI Clothes Changer)
  String get magicHourApiKey => _getEnv('MAGIC_HOUR_API_KEY') ?? '';

  /// Magic Hour API Base URL
  String get magicHourBaseUrl =>
      _getEnv('MAGIC_HOUR_BASE_URL') ?? 'https://api.magichour.ai';

  // ---------------------------------------------------------------------------
  // ZOE AI CHAT — Provider Cluster
  // ---------------------------------------------------------------------------

  /// Google Gemini (Priority 1)
  String get zoeGeminiApiKey => _getEnv('ZOE_GEMINI_API_KEY') ?? '';
  String get zoeGeminiBaseUrl =>
      _getEnv('ZOE_GEMINI_BASE_URL') ??
      'https://generativelanguage.googleapis.com/v1beta/openai/';
  String get zoeGeminiModel =>
      _getEnv('ZOE_GEMINI_MODEL') ?? 'gemini-2.5-flash';

  /// Groq (Priority 2)
  String get zoeGroqApiKey => _getEnv('ZOE_GROQ_API_KEY') ?? '';
  String get zoeGroqBaseUrl =>
      _getEnv('ZOE_GROQ_BASE_URL') ?? 'https://api.groq.com/openai/v1';
  String get zoeGroqModel =>
      _getEnv('ZOE_GROQ_MODEL') ?? 'llama-3.3-70b-versatile';

  /// Mistral (Priority 3)
  String get zoeMistralApiKey => _getEnv('ZOE_MISTRAL_API_KEY') ?? '';
  String get zoeMistralBaseUrl =>
      _getEnv('ZOE_MISTRAL_BASE_URL') ?? 'https://api.mistral.ai/v1';
  String get zoeMistralModel =>
      _getEnv('ZOE_MISTRAL_MODEL') ?? 'mistral-small-latest';

  /// DeepSeek (Priority 4)
  String get zoeDeepSeekApiKey => _getEnv('ZOE_DEEPSEEK_API_KEY') ?? '';
  String get zoeDeepSeekBaseUrl =>
      _getEnv('ZOE_DEEPSEEK_BASE_URL') ?? 'https://api.deepseek.com/v1';
  String get zoeDeepSeekModel =>
      _getEnv('ZOE_DEEPSEEK_MODEL') ?? 'deepseek-chat';

  // ---------------------------------------------------------------------------
  // BREVO EMAIL — Customer Support Escalation
  // ---------------------------------------------------------------------------

  String get brevoApiKey => _getEnv('BREVO_API_KEY') ?? '';
  String get brevoSmtpKey => _getEnv('BREVO_SMTP_KEY') ?? '';
  String get brevoSupportEmail =>
      _getEnv('BREVO_SUPPORT_EMAIL') ?? 'support@desby.app';

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

  /// Database URL
  String get databaseUrl => _getEnv('DATABASE_URL') ?? '';

  /// Fez Logistics Secret Key.
  ///
  /// Note: this is NOT a login credential. Fez's API authenticates with a
  /// per-account `user_id` + `password` (POST /user/authenticate) and issues a
  /// bearer token; the secret key alone cannot authenticate (verified against
  /// the sandbox: rejected as credentials, and 404 on header auth). Desby was
  /// never issued those account credentials, so the courier integration is
  /// dormant until Fez provides them.
  String get fezLogisticsSecretKey => _getEnv('FEZ_LOGISTICS_SECRET_KEY') ?? '';

  /// Whether Fez account credentials have been provisioned.
  ///
  /// False means delivery pricing and dispatch are unavailable — the app says
  /// so plainly instead of implying a courier quote it cannot get.
  bool get fezLogisticsProvisioned =>
      _getEnv('FEZ_LOGISTICS_USER_ID')?.isNotEmpty == true &&
      _getEnv('FEZ_LOGISTICS_PASSWORD')?.isNotEmpty == true;

  /// Fez account user id (issued by Fez; absent today).
  String get fezLogisticsUserId => _getEnv('FEZ_LOGISTICS_USER_ID') ?? '';

  /// Fez account password (issued by Fez; absent today).
  String get fezLogisticsPassword => _getEnv('FEZ_LOGISTICS_PASSWORD') ?? '';

  // ── Terminal Shipping (T-Ship) — multi-carrier aggregator ──────────────
  // Replaces the Fez single-courier dependency. Verified live on the sandbox
  // 2026-10-10: a Lagos->Lagos 2kg quote returned six priced carriers
  // (GIG, GIGM, DHL, Redstar, Dellyman, Chowdeck, Fez, ...).
  //
  // IMPORTANT: never commit the live key. It can book real, paid shipments.

  /// Terminal API secret key. Sandbox and live keys share this field; the base
  /// URL decides which environment is hit.
  String get terminalShippingSecretKey =>
      _getEnv('TERMINAL_API_SECRET_KEY') ?? '';

  /// Terminal API base URL. Defaults to SANDBOX so a missing/incorrect
  /// environment variable can never book a live shipment by accident.
  String get terminalShippingBaseUrl =>
      _getEnv('TERMINAL_API_BASE_URL') ??
      'https://sandbox.terminal.africa/v1';

  bool get terminalShippingConfigured => terminalShippingSecretKey.isNotEmpty;

  // Desby's pickup point — every order leaves from the same workshop, so this
  // is registered once and reused.
  String get logisticsPickupName =>
      _getEnv('LOGISTICS_PICKUP_NAME') ?? 'Desby';
  String get logisticsPickupPhone =>
      _getEnv('LOGISTICS_PICKUP_PHONE') ?? '08000000000';
  String get logisticsPickupAddress =>
      _getEnv('LOGISTICS_PICKUP_ADDRESS') ?? '1 Allen Avenue';
  String get logisticsPickupCity =>
      _getEnv('LOGISTICS_PICKUP_CITY') ?? 'Ikeja';
  String get logisticsPickupState =>
      _getEnv('LOGISTICS_PICKUP_STATE') ?? 'Lagos';
  String get logisticsPickupZip =>
      _getEnv('LOGISTICS_PICKUP_ZIP') ?? '101123';
  /// Terminal rejects persisted quotes whose line2 is empty, so this must carry
  /// a real value.
  String get logisticsPickupAddressLine2 =>
      _getEnv('LOGISTICS_PICKUP_ADDRESS_LINE2') ?? '';

  /// Used only when an order carries no recipient number.
  ///
  /// Terminal validates phone numbers against the address country and rejects
  /// local-format numbers for NG (it wants +234...). This default is therefore
  /// in international form.
  String get logisticsFallbackPhone =>
      _getEnv('LOGISTICS_FALLBACK_PHONE') ?? '+2348000000000';

  /// Fez Logistics Base URL (legacy — superseded by Terminal Shipping)
  String get fezLogisticsBaseUrl =>
      _getEnv('FEZ_LOGISTICS_BASE_URL') ??
      'https://apisandbox.fezdelivery.co/v1';

  /// Vimeo Client ID
  String get vimeoClientId => _getEnv('VIMEO_CLIENT_ID') ?? '';

  /// Vimeo Client Secret
  String get vimeoClientSecret => _getEnv('VIMEO_CLIENT_SECRET') ?? '';

  /// Vimeo Personal Access Token
  String get vimeoAccessToken => _getEnv('VIMEO_ACCESS_TOKEN') ?? '';

  /// Vimeo Webhook Secret
  String get vimeoWebhookSecret => _getEnv('VIMEO_WEBHOOK_SECRET') ?? '';

  /// Hyperserve API Key (free video hosting)
  String get hyperserveApiKey => _getEnv('HYPERSERVE_API_KEY') ?? '';

  /// Flutterwave Payment
  ///
  /// Only the PUBLIC key belongs in the browser. The secret key is deliberately
  /// absent: it was previously read here and shipped in the web bundle, where
  /// anyone could extract it and move money from the merchant account. All
  /// secret-key operations (subaccounts, transfers, refunds) now run in a
  /// Supabase Edge Function.
  String get flutterwavePublicKey => _getEnv('FLUTTERWAVE_PUBLIC_KEY') ?? '';
  String get flutterwaveEncryptionKey =>
      _getEnv('FLUTTERWAVE_ENCRYPTION_KEY') ?? '';

  /// Payment Redirect URL
  String get paymentRedirectUrl =>
      _getEnv('PAYMENT_REDIRECT_URL') ?? 'https://desby.app/payment-callback';

  /// App Logo URL
  ///
  /// Derived from the active Supabase project so it can never drift back to a
  /// previous project's ref. The old fallback named a retired project outright.
  String get appLogoUrl {
    final configured = _getEnv('APP_LOGO_URL');
    if (configured != null && configured.trim().isNotEmpty) {
      return configured.trim();
    }
    final base = supabaseUrl.trim();
    if (base.isNotEmpty) {
      return '$base/storage/v1/object/public/assets/logo.png';
    }
    return 'assets/images/logo.png';
  }

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
