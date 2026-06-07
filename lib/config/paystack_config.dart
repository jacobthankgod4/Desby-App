import 'package:flutter/foundation.dart';

/// Paystack Configuration
/// 
/// Configuration class for Paystack payment integration.
/// In production, these should be fetched from environment variables or secure storage.
class PaystackConfig {
  /// Whether Paystack is properly configured
  static bool isConfigured() {
    // In production, check if public key is set
    final key = getPublicKey();
    return key != null && key.isNotEmpty;
  }

  /// Get Paystack public key
  /// Returns null if not configured
  static String? getPublicKey() {
    // TODO: Load from environment or secure storage
    // For development, you can set this via environment variable
    const key = String.fromEnvironment('PAYSTACK_PUBLIC_KEY', defaultValue: '');
    return key.isEmpty ? null : key;
  }

  /// Get Paystack secret key
  static String? getSecretKey() {
    const key = String.fromEnvironment('PAYSTACK_SECRET_KEY', defaultValue: '');
    return key.isEmpty ? null : key;
  }

  /// Get Paystack API base URL
  static String getBaseUrl() {
    // Use test URL in development, live in production
    const env = String.fromEnvironment('FLUTTER_ENV', defaultValue: 'development');
    final isTestMode = env == 'development';
    return isTestMode 
      ? 'https://api.paystack.co' 
      : 'https://api.paystack.co';
  }

  /// Initialize Paystack SDK
  /// This is a stub for compatibility - actual initialization done via flutter_paystack_plus
  static Future<void> initialize() async {
    if (!isConfigured()) {
      debugPrint('[PaystackConfig] Warning: Paystack not configured, using stub mode');
    }
    debugPrint('[PaystackConfig] Initialized');
  }

  /// Get merchant email
  static String? getMerchantEmail() {
    const email = String.fromEnvironment('MERCHANT_EMAIL', defaultValue: '');
    return email.isEmpty ? null : email;
  }
}
