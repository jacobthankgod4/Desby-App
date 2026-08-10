import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../config/environment.dart';

/// EachLabs API Client - State-of-the-art Virtual Try-On using IDM-VTON
class EachLabsClient {
  final Dio _dio;
  
  String get _apiKey => Environment.current.eachLabsApiKey;
  static const String _baseUrl = 'https://api.eachlabs.ai/v1/prediction';

  EachLabsClient({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.headers = {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
    };
  }

  /// Initiates a Virtual Try-On task using IDM-VTON
  /// [humanImg] - URL of the person
  /// [garmImg] - URL of the garment
  /// [description] - Text description of the garment for prompt guidance
  /// [category] - 'upper_body', 'lower_body', or 'dresses'
  Future<String?> createPrediction({
    required String humanImg,
    required String garmImg,
    required String description,
    String category = 'upper_body',
  }) async {
    try {
      debugPrint('[EACHLABS] Creating prediction for: $description');
      
      final response = await _dio.post('/', data: {
        'model': 'idm-vton',
        'version': '0.0.1',
        'input': {
          'crop': true,
          'seed': 42,
          'steps': 30,
          'category': category,
          'garm_img': garmImg,
          'human_img': humanImg,
          'garment_des': description,
        },
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['id'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('[EACHLABS] Prediction initiation failed: $e');
      return null;
    }
  }

  /// Checks the status of a prediction
  Future<EachLabsResult> getPrediction(String id) async {
    try {
      final response = await _dio.get('/$id');
      return EachLabsResult.fromJson(response.data);
    } catch (e) {
      debugPrint('[EACHLABS] Error checking prediction $id: $e');
      return EachLabsResult(status: 'failed', error: e.toString());
    }
  }

  /// Waits for completion with intelligent polling
  Future<EachLabsResult> waitForResult(String id) async {
    int attempts = 0;
    const maxAttempts = 60; // 2 minutes max
    
    while (attempts < maxAttempts) {
      final result = await getPrediction(id);
      
      if (result.status == 'success') return result;
      if (result.status == 'failed' || result.status == 'error') return result;
      
      attempts++;
      await Future.delayed(const Duration(seconds: 2));
    }
    
    return EachLabsResult(status: 'timeout', error: 'Rendering timed out after 2 minutes');
  }
}

class EachLabsResult {
  final String status; // 'processing', 'success', 'failed'
  final String? output;
  final String? error;

  EachLabsResult({required this.status, this.output, this.error});

  factory EachLabsResult.fromJson(Map<String, dynamic> json) {
    // API returns 'success' on completion, and 'output' contains the image URL
    return EachLabsResult(
      status: json['status'] as String? ?? 'processing',
      output: json['output'] as String?,
      error: json['error'] as String?,
    );
  }
}
