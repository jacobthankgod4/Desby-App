import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../config/environment.dart';

/// Body Measurement Service - AI-powered measurement extraction
/// 
/// This service connects to the AI Body Scan SaaS API
/// to extract body measurements from DUAL photos (front + side).
/// 
/// REQUIRES both front and side photos for ±1-3cm accuracy.
/// SINGLE PHOTO MODE IS NOT SUPPORTED.

class BodyMeasurementService {
  // Use Environment for API URL - supports dev/prod via env var
String get _baseUrl => Environment.current.aiScanApiBaseUrl;
  
  // API key for subscription validation
  String? _apiKey;
  
  final Dio _dio;
  
  BodyMeasurementService({Dio? dio, String? apiKey}) : _dio = dio ?? Dio() {
    _apiKey = apiKey;
  }
  
  /// Set API key for subscription validation
  void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }
  
/// Check if the service is available
  Future<bool> get isAvailable async {
    try {
      final response = await _dio.get(
        '$_baseUrl/api/v2/health',
        options: Options(sendTimeout: const Duration(seconds: 5)),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Body Measurement Service unavailable: $e');
      return false;
    }
  }
  
  /// Extract body measurements from DUAL photos (front + side)
  /// 
  /// REQUIRES both front and side photos for accurate measurements.
  /// 
  /// [frontImage] - Path to front photo (REQUIRED)
  /// [sideImage] - Path to side photo (REQUIRED)
  /// [heightCm] - User's height in centimeters (required for scaling)
  /// [gender] - 'male' or 'female'
  /// 
  /// Returns: Map of measurement names to values in cm
  Future<BodyMeasurementResult> extractMeasurements({
    required File frontImage,
    required File sideImage,
    required double heightCm,
    String gender = 'male',
  }) async {
    try {
final formData = FormData.fromMap({
        'front': await MultipartFile.fromFile(
          frontImage.path,
          filename: 'front.jpg',
        ),
        'side': await MultipartFile.fromFile(
          sideImage.path,
          filename: 'side.jpg',
        ),
        'height': heightCm.toString(),
        'gender': gender,
      });
      
final response = await _dio.post(
        '$_baseUrl/api/v2/measurements/extract',
        data: formData,
        options: Options(
          headers: {
            if (_apiKey != null) 'X-API-Key': _apiKey,
          },
        ),
      );
      
      if (response.statusCode == 200) {
        return BodyMeasurementResult.fromJson(response.data);
      } else {
        return BodyMeasurementResult.error(response.data['error'] ?? 'Unknown error');
      }
    } catch (e) {
      return BodyMeasurementResult.error('Failed to connect: $e');
    }
}
  
  /// Validate measurements before saving
  /// 
  /// Checks for common measurement issues like
  /// impossible proportions or inconsistencies.
  Future<MeasurementValidation> validateMeasurements({
    required Map<String, double> measurements,
    required double userHeight,
  }) async {
try {
      final response = await _dio.post(
        '$_baseUrl/api/v2/measurements/validate',
        data: {
          'measurements': measurements,
          'height': userHeight,
        },
        options: Options(
          headers: {
            if (_apiKey != null) 'X-API-Key': _apiKey,
          },
        ),
      );
      
      if (response.statusCode == 200) {
        return MeasurementValidation.fromJson(response.data);
      } else {
        return MeasurementValidation(
          valid: true, // Assume valid if service unavailable
          issues: [],
          suggestions: [],
        );
      }
    } catch (e) {
      return MeasurementValidation(
        valid: true,
        issues: [],
        suggestions: ['Unable to validate - service unavailable'],
      );
    }
  }
  
  void dispose() {
    _dio.close();
  }
}

/// Result from body measurement extraction
/// 
/// Always uses dual photo mode for ±1-3cm accuracy
class BodyMeasurementResult {
  final bool success;
  final Map<String, double>? measurements;
  final String? error;
  final double? processingTime;
  final String? imageId;
  final String? gender;
  final double? userHeightCm;
  final String accuracyMode; // Always 'dual'
  final String accuracy; // Always '±1-3cm'
  
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
      imageId: json['image_id'],
      gender: json['gender'],
      userHeightCm: json['user_height_cm']?.toDouble(),
      accuracyMode: json['accuracy_mode'] ?? 'dual',
      accuracy: json['accuracy'] ?? '±1-3cm',
    );
  }
  
  factory BodyMeasurementResult.error(String error) {
    return BodyMeasurementResult(
      success: false,
      error: error,
      accuracyMode: 'dual',
      accuracy: '±1-3cm',
    );
  }
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
