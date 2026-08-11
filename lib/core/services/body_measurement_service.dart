import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/environment.dart';
import '../network/korra_client.dart';

/// Body Measurement Service - AI-powered measurement extraction
///
/// This service connects to the Korra AI API
/// to extract body measurements from photos or height-only estimation.
///
/// Supports:
/// - Dual photo mode (front + side) — ±1-3cm accuracy
/// - Single photo mode (front only) — ±3-5cm accuracy
/// - Height-only estimation — ±5-8cm accuracy (no photos needed)
///
/// Auto-provisions Korra API keys for Desby users on first scan.
class BodyMeasurementService {
  final KorraClient _korra;

  BodyMeasurementService({KorraClient? korra})
    : _korra = korra ?? KorraClient() {
    final apiKey = Environment.current.korraApiKey;
    if (apiKey.isNotEmpty) {
      _korra.setApiKey(apiKey);
    }
  }

  /// Ensure we have a Korra API key — auto-provision if needed
  ///
  /// Checks (in order):
  /// 1. Already set via constructor (global key)
  /// 2. Stored in user's Supabase profile (korra_api_key field)
  /// 3. Auto-provision via partner endpoint
  Future<String?> _ensureApiKey() async {
    // Already have a key
    if (_korra.hasApiKey) return null; // null means "already set"

    final partnerKey = Environment.current.korraPartnerKey;
    if (partnerKey.isEmpty) {
      debugPrint('[KORRA] No partner key — using fallback');
      return null;
    }

    // Try to load from Supabase profile
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final profile = await Supabase.instance.client
            .from('users')
            .select('korra_api_key')
            .eq('id', user.id)
            .maybeSingle();

        if (profile != null && profile['korra_api_key'] != null) {
          final storedKey = profile['korra_api_key'] as String;
          if (storedKey.isNotEmpty) {
            _korra.setApiKey(storedKey);
            debugPrint('[KORRA] Loaded API key from profile');
            return storedKey;
          }
        }

        // Auto-provision via partner endpoint
        final newKey = await _korra.provisionApiKey(
          partnerUserId: user.id,
        );

        if (newKey != null) {
          // Store in profile for future use
          try {
            await Supabase.instance.client
                .from('users')
                .update({'korra_api_key': newKey}).eq('id', user.id);
            debugPrint('[KORRA] API key stored in profile');
          } catch (e) {
            debugPrint('[KORRA] Failed to store key in profile: $e');
          }
          return newKey;
        }
      }
    } catch (e) {
      debugPrint('[KORRA] Auto-provision failed: $e');
    }

    return null;
  }

  /// Check if the Korra service is available
  Future<bool> get isAvailable => _korra.isAvailable;

  /// Extract body measurements from DUAL photos (front + side)
  ///
  /// REQUIRES both front and side photos for ±1-3cm accuracy.
  ///
  /// [frontImage] - Path to front photo (REQUIRED)
  /// [sideImage] - Path to side photo (REQUIRED)
  /// [heightCm] - User's height in centimeters (required for scaling)
  /// [gender] - 'male' or 'female'
  ///
  /// Returns: Map of measurement names to values in cm
  Future<BodyMeasurementResult> extractMeasurements({
    required Uint8List frontImageBytes,
    required Uint8List sideImageBytes,
    required double heightCm,
    String gender = 'male',
  }) async {
    await _ensureApiKey();
    final korraResult = await _korra.extractMeasurements(
      frontImageBytes: frontImageBytes,
      sideImageBytes: sideImageBytes,
      heightCm: heightCm,
      gender: gender,
    );

    return BodyMeasurementResult(
      success: korraResult.success,
      measurements: korraResult.measurements,
      error: korraResult.error,
      processingTime: korraResult.processingTime,
      imageId: korraResult.measurementId,
      gender: korraResult.gender,
      userHeightCm: korraResult.heightCm,
      accuracyMode: korraResult.accuracyMode,
      accuracy: korraResult.accuracy,
    );
  }

  /// Extract measurements from a single front photo (lower accuracy)
  ///
  /// Uses single front photo for ±3-5cm accuracy.
  /// No side photo required — faster but less precise.
  Future<BodyMeasurementResult> extractSinglePhoto({
    required Uint8List frontImageBytes,
    required double heightCm,
    String gender = 'male',
  }) async {
    await _ensureApiKey();
    final korraResult = await _korra.extractSinglePhoto(
      frontImageBytes: frontImageBytes,
      heightCm: heightCm,
      gender: gender,
    );

    return BodyMeasurementResult(
      success: korraResult.success,
      measurements: korraResult.measurements,
      error: korraResult.error,
      processingTime: korraResult.processingTime,
      imageId: korraResult.measurementId,
      gender: korraResult.gender,
      userHeightCm: korraResult.heightCm,
      accuracyMode: korraResult.accuracyMode,
      accuracy: korraResult.accuracy,
    );
  }

  /// Estimate measurements from height only (no photos needed)
  ///
  /// Uses anthropometric ratios for ±5-8cm accuracy.
  /// Fastest method — no camera required.
  Future<BodyMeasurementResult> estimateFromHeight({
    required double heightCm,
    String gender = 'male',
  }) async {
    await _ensureApiKey();
    final korraResult = await _korra.estimateFromHeight(
      heightCm: heightCm,
      gender: gender,
    );

    return BodyMeasurementResult(
      success: korraResult.success,
      measurements: korraResult.measurements,
      error: korraResult.error,
      processingTime: korraResult.processingTime,
      imageId: korraResult.measurementId,
      gender: korraResult.gender,
      userHeightCm: korraResult.heightCm,
      accuracyMode: korraResult.accuracyMode,
      accuracy: korraResult.accuracy,
    );
  }

  /// List all past measurements for the current user
  Future<List<KorraMeasurementSummary>> listMeasurements() async {
    await _ensureApiKey();
    return _korra.listMeasurements();
  }

  /// Get a specific measurement by ID
  Future<KorraMeasurementResult?> getMeasurement(String measurementId) {
    return _korra.getMeasurement(measurementId);
  }

  /// Delete a measurement by ID
  Future<bool> deleteMeasurement(String measurementId) {
    return _korra.deleteMeasurement(measurementId);
  }

  /// Download measurement PDF as bytes
  Future<List<int>?> downloadMeasurementPdf(String measurementId) {
    return _korra.downloadMeasurementPdf(measurementId);
  }

  /// Check async extraction task status
  Future<KorraTaskStatus?> getTaskStatus(String taskId) {
    return _korra.getTaskStatus(taskId);
  }

  /// Back-calculate measurements from garment specifications
  Future<BodyMeasurementResult> backCalculate({
    required String measurementId,
    required Map<String, dynamic> garmentSpecs,
  }) async {
    final korraResult = await _korra.backCalculate(
      measurementId: measurementId,
      garmentSpecs: garmentSpecs,
    );

    return BodyMeasurementResult(
      success: korraResult.success,
      measurements: korraResult.measurements,
      error: korraResult.error,
      processingTime: korraResult.processingTime,
      imageId: korraResult.measurementId,
      gender: korraResult.gender,
      userHeightCm: korraResult.heightCm,
      accuracyMode: korraResult.accuracyMode,
      accuracy: korraResult.accuracy,
    );
  }

  /// Drape a garment on a scanned body
  Future<KorraDrapeResult> drapeGarment({
    required String scanId,
    required String garmentModel,
    Map<String, dynamic>? options,
  }) {
    return _korra.drapeGarment(
      scanId: scanId,
      garmentModel: garmentModel,
      options: options,
    );
  }

  /// Compute body shape from physiological parameters
  Future<KorraBodyShapeResult> computeBodyShape({
    required double gender,
    double age = 0.2,
    double muscle = 0.5,
    double weight = 0.5,
    double height = 0.5,
    double proportions = 0.5,
    double cupsize = 0.0,
    double firmness = 0.5,
    double african = 0.0,
    double asian = 0.0,
    double caucasian = 1.0,
  }) {
    return _korra.computeBodyShape(
      gender: gender,
      age: age,
      muscle: muscle,
      weight: weight,
      height: height,
      proportions: proportions,
      cupsize: cupsize,
      firmness: firmness,
      african: african,
      asian: asian,
      caucasian: caucasian,
    );
  }

  /// Refine / impute missing measurements
  Future<BodyMeasurementResult> refineMeasurements({
    required Map<String, double> measurements,
    required String gender,
    double? heightCm,
  }) async {
    final korraResult = await _korra.refineMeasurements(
      measurements: measurements,
      gender: gender,
      heightCm: heightCm,
    );

    return BodyMeasurementResult(
      success: korraResult.success,
      measurements: korraResult.measurements,
      error: korraResult.error,
      processingTime: korraResult.processingTime,
      imageId: korraResult.measurementId,
      gender: korraResult.gender,
      userHeightCm: korraResult.heightCm,
      accuracyMode: korraResult.accuracyMode,
      accuracy: korraResult.accuracy,
    );
  }

  /// Start a virtual try-on session
  Future<KorraTryOnSession?> startTryOn({
    required String scanId,
    required String garmentId,
  }) {
    return _korra.startTryOn(scanId: scanId, garmentId: garmentId);
  }

  /// Capture a try-on result
  Future<KorraTryOnCapture?> captureTryOn({
    required String sessionId,
    Map<String, dynamic>? metadata,
  }) {
    return _korra.captureTryOn(sessionId: sessionId, metadata: metadata);
  }

  void dispose() {
    _korra.dispose();
  }
}

/// Result from body measurement extraction
///
/// Supports dual photo, single photo, and height-only estimation modes.
class BodyMeasurementResult {
  final bool success;
  final Map<String, double>? measurements;
  final String? error;
  final double? processingTime;
  final String? imageId;
  final String? gender;
  final double? userHeightCm;
  final String accuracyMode; // 'dual', 'single', 'estimate'
  final String accuracy; // '±1-3cm', '±3-5cm', '±5-8cm'

  BodyMeasurementResult({
    required this.success,
    this.measurements,
    this.error,
    this.processingTime,
    this.imageId,
    this.gender,
    this.userHeightCm,
    this.accuracyMode = 'dual',
    this.accuracy = '±1-3cm',
  });

  factory BodyMeasurementResult.fromJson(Map<String, dynamic> json) {
    return BodyMeasurementResult(
      success: json['success'] ?? false,
      measurements: (json['measurements'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
      error: json['error'],
      processingTime: json['processing_time_seconds']?.toDouble(),
      imageId: json['image_id'] ?? json['measurement_id'],
      gender: json['gender'],
      userHeightCm:
          json['user_height_cm']?.toDouble() ?? json['height']?.toDouble(),
      accuracyMode: json['accuracy_mode'] ?? 'dual',
      accuracy: json['accuracy'] ?? '±1-3cm',
    );
  }

  factory BodyMeasurementResult.error(String error) {
    return BodyMeasurementResult(success: false, error: error);
  }

  /// Get a user-friendly accuracy description
  String get accuracyDescription {
    switch (accuracyMode) {
      case 'dual':
        return 'Professional accuracy (±1-3cm)';
      case 'single':
        return 'Good accuracy (±3-5cm)';
      case 'estimate':
        return 'Estimated (±5-8cm)';
      default:
        return accuracy;
    }
  }

  /// Get the measurement count
  int get measurementCount => measurements?.length ?? 0;
}

/// Measurement validation result
class MeasurementValidation {
  final bool valid;
  final List<String> issues;
  final List<String> suggestions;

  MeasurementValidation({
    required this.valid,
    required this.issues,
    required this.suggestions,
  });

  factory MeasurementValidation.fromJson(Map<String, dynamic> json) {
    return MeasurementValidation(
      valid: json['valid'] ?? true,
      issues: List<String>.from(json['issues'] ?? []),
      suggestions: List<String>.from(json['suggestions'] ?? []),
    );
  }
}
