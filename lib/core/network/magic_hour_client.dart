import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../config/environment.dart';

/// Magic Hour API Client - AI Clothes Changer
/// Replaces EachLabs for Virtual Try-On
class MagicHourClient {
  final Dio _dio;

  String get _apiKey => Environment.current.magicHourApiKey;
  String get _baseUrl => Environment.current.magicHourBaseUrl;

  MagicHourClient({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.headers = {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
    };
  }

  /// Creates an AI Clothes Changer prediction
  /// [humanImg] - URL of the person photo (Supabase public URL)
  /// [garmImg] - URL of the garment image (Supabase public URL)
  /// [category] - 'upper_body', 'lower_body', or 'dresses'
  Future<String?> createPrediction({
    required String humanImg,
    required String garmImg,
    String description = '',
    String category = 'upper_body',
  }) async {
    try {
      debugPrint('[MAGIC_HOUR] Creating clothes changer prediction...');

      final garmentType = _mapCategory(category);

      final response = await _dio.post(
        '/v1/ai-clothes-changer',
        data: {
          'name': 'Desby Try-On ${DateTime.now().millisecondsSinceEpoch}',
          'assets': {
            'person_file_path': humanImg,
            'garment_file_path': garmImg,
            'garment_type': garmentType,
          },
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final id = response.data['id'] as String?;
        final credits = response.data['credits_charged'] ?? 0;
        debugPrint('[MAGIC_HOUR] Prediction created: $id ($credits credits)');
        return id;
      }
      debugPrint('[MAGIC_HOUR] Unexpected status: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('[MAGIC_HOUR] Prediction creation failed: $e');
      return null;
    }
  }

  /// Checks the status of a prediction
  Future<MagicHourResult> getPrediction(String id) async {
    try {
      final response = await _dio.get('/v1/image-projects/$id');
      return MagicHourResult.fromJson(response.data);
    } catch (e) {
      debugPrint('[MAGIC_HOUR] Error checking prediction $id: $e');
      return MagicHourResult(status: 'error', error: e.toString());
    }
  }

  /// Waits for completion with intelligent polling
  Future<MagicHourResult> waitForResult(String id) async {
    int attempts = 0;
    const maxAttempts = 90; // 3 minutes max (Magic Hour can take longer)

    while (attempts < maxAttempts) {
      final result = await getPrediction(id);

      if (result.status == 'complete') return result;
      if (result.status == 'error' || result.status == 'canceled')
        return result;

      attempts++;
      await Future.delayed(const Duration(seconds: 2));
    }

    return MagicHourResult(
      status: 'timeout',
      error: 'Rendering timed out after 3 minutes',
    );
  }

  /// Maps our category strings to Magic Hour garment types
  String _mapCategory(String category) {
    switch (category) {
      case 'upper_body':
        return 'upper_body';
      case 'lower_body':
        return 'lower_body';
      case 'dresses':
        return 'entire_outfit';
      default:
        return 'entire_outfit';
    }
  }
}

class MagicHourResult {
  final String status; // 'queued', 'rendering', 'complete', 'error', 'canceled'
  final String? output;
  final String? error;

  MagicHourResult({required this.status, this.output, this.error});

  factory MagicHourResult.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as String? ?? 'queued';
    String? output;

    if (status == 'complete') {
      final downloads = json['downloads'] as List<dynamic>?;
      if (downloads != null && downloads.isNotEmpty) {
        output = (downloads[0] as Map<String, dynamic>?)?['url'] as String?;
      }
    }

    final errorData = json['error'];
    String? errorMsg;
    if (errorData is Map) {
      errorMsg = errorData['message'] as String?;
    }

    return MagicHourResult(status: status, output: output, error: errorMsg);
  }
}
