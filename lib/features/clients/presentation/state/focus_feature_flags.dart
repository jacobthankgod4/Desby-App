import 'package:flutter/foundation.dart';

/// Implements Step 12: Rollout Plan with Feature Flags
///
/// Feature flags for controlling focus system behavior at runtime.
/// Allows gradual rollout and easy rollback.

class FocusFeatureFlags {
  FocusFeatureFlags._();

  /// Master kill switch - disables all v2 focus features
  static bool get focusV2RegistryEnabled => _focusV2RegistryEnabled;
  static bool _focusV2RegistryEnabled = true;

  /// Enable deterministic quality scoring
  static bool get focusQualityScorerEnabled => _focusQualityScorerEnabled;
  static bool _focusQualityScorerEnabled = true;

  /// Enable automatic fallback when quality is low
  static bool get focusAutoFallbackEnabled => _focusAutoFallbackEnabled;
  static bool _focusAutoFallbackEnabled = true;

  /// Enable rig overlay markers (debug mode)
  static bool get focusRigOverlayEnabled => _focusRigOverlayEnabled;
  static bool _focusRigOverlayEnabled = false;

  /// Telemetry: log focus events for calibration
  static bool get focusTelemetryEnabled => kDebugMode || _forceTelemetry;
  static bool _forceTelemetry = false;

  /// Enable debug overlay UI toggle
  static bool _showDebugOverlay = false;
  static bool get showDebugOverlay => _showDebugOverlay;

  /// Setters for runtime control (e.g., from settings UI)
  static void setFocusV2Registry(bool value) {
    _focusV2RegistryEnabled = value;
    _logFlagChange('focus_v2_registry', value);
  }

  static void setQualityScorer(bool value) {
    _focusQualityScorerEnabled = value;
    _logFlagChange('focus_quality_scorer', value);
  }

  static void setAutoFallback(bool value) {
    _focusAutoFallbackEnabled = value;
    _logFlagChange('focus_auto_fallback', value);
  }

  static void setRigOverlay(bool value) {
    _focusRigOverlayEnabled = value;
    _logFlagChange('focus_rig_overlay', value);
  }

  static void setDebugOverlay(bool value) {
    _showDebugOverlay = value;
  }

  static void enableTelemetry() {
    _forceTelemetry = true;
  }

  /// Check if v2 features are active
  static bool get isV2Active =>
      focusV2RegistryEnabled && focusQualityScorerEnabled;

  /// Reset all flags to defaults
  static void resetToDefaults() {
    _focusV2RegistryEnabled = true;
    _focusQualityScorerEnabled = true;
    _focusAutoFallbackEnabled = true;
    _focusRigOverlayEnabled = false;
    _forceTelemetry = false;
    _showDebugOverlay = false;
    debugPrint('[FLAGS] Reset to defaults');
  }

  /// Get all flag states (for debugging/UI)
  static Map<String, dynamic> get allFlags => {
        'focus_v2_registry': _focusV2RegistryEnabled,
        'focus_quality_scorer': _focusQualityScorerEnabled,
        'focus_auto_fallback': _focusAutoFallbackEnabled,
        'focus_rig_overlay': _focusRigOverlayEnabled,
        'show_debug_overlay': _showDebugOverlay,
        'telemetry_enabled': focusTelemetryEnabled,
      };

  static void _logFlagChange(String flag, bool value) {
    debugPrint('[FLAGS] $flag = $value');
  }
}
