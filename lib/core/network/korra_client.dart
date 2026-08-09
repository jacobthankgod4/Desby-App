import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../config/environment.dart';

/// Korra AI API Client
///
/// Unified client for all Korra AI endpoints.
/// Handles authentication, error mapping, and request/response logging.
class KorraClient {
  static KorraClient? _instance;
  late final Dio _dio;

  String get _baseUrl => Environment.current.korraApiBaseUrl;
  String? _apiKey;

  KorraClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint('[KORRA] $obj'),
      ),
    );
  }

  factory KorraClient() {
    _instance ??= KorraClient._internal();
    return _instance!;
  }

  /// Set API key for authenticated requests
  void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  Options get _authOptions =>
      Options(headers: {if (_apiKey != null) 'X-API-Key': _apiKey});

  // ---------------------------------------------------------------------------
  // HEALTH
  // ---------------------------------------------------------------------------

  /// Check API health
  Future<bool> get isAvailable async {
    try {
      final response = await _dio.get(
        '/api/v2/health',
        options: Options(sendTimeout: const Duration(seconds: 5)),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[KORRA] Health check failed: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // MEASUREMENTS - Extract
  // ---------------------------------------------------------------------------

  /// Extract body measurements from dual photos (front + side)
  Future<KorraMeasurementResult> extractMeasurements({
    required File frontImage,
    required File sideImage,
    required double heightCm,
    required String gender,
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
        '/api/v2/measurements/extract',
        data: formData,
        options: _authOptions,
      );

      return KorraMeasurementResult.fromJson(response.data);
    } on DioException catch (e) {
      return KorraMeasurementResult.error(_dioError(e));
    } catch (e) {
      return KorraMeasurementResult.error('Unexpected error: $e');
    }
  }

  /// Extract measurements from a single front photo (lower accuracy)
  Future<KorraMeasurementResult> extractSinglePhoto({
    required File frontImage,
    required double heightCm,
    required String gender,
  }) async {
    try {
      final formData = FormData.fromMap({
        'front': await MultipartFile.fromFile(
          frontImage.path,
          filename: 'front.jpg',
        ),
        'height': heightCm.toString(),
        'gender': gender,
      });

      final response = await _dio.post(
        '/api/v2/measurements/extract',
        data: formData,
        options: _authOptions,
      );

      return KorraMeasurementResult.fromJson(response.data);
    } on DioException catch (e) {
      return KorraMeasurementResult.error(_dioError(e));
    } catch (e) {
      return KorraMeasurementResult.error('Unexpected error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // MEASUREMENTS - Estimate (height-only fallback)
  // ---------------------------------------------------------------------------

  /// Estimate measurements from height only (no photos needed)
  ///
  /// Uses Form data (not JSON) per Korra API spec.
  Future<KorraMeasurementResult> estimateFromHeight({
    required double heightCm,
    required String gender,
  }) async {
    try {
      final formData = FormData.fromMap({
        'height': heightCm.toString(),
        'gender': gender,
      });

      final response = await _dio.post(
        '/api/v2/measurements/estimate',
        data: formData,
        options: _authOptions,
      );

      return KorraMeasurementResult.fromJson(response.data);
    } on DioException catch (e) {
      return KorraMeasurementResult.error(_dioError(e));
    } catch (e) {
      return KorraMeasurementResult.error('Unexpected error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // MEASUREMENTS - CRUD
  // ---------------------------------------------------------------------------

  /// List all measurements for the current user
  Future<List<KorraMeasurementSummary>> listMeasurements() async {
    try {
      final response = await _dio.get(
        '/api/v2/measurements',
        options: _authOptions,
      );

      final data = response.data;
      if (data is Map && data.containsKey('measurements')) {
        return (data['measurements'] as List)
            .map((e) => KorraMeasurementSummary.fromJson(e))
            .toList();
      }
      if (data is List) {
        return data.map((e) => KorraMeasurementSummary.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('[KORRA] List measurements failed: ${_dioError(e)}');
      return [];
    } catch (e) {
      debugPrint('[KORRA] List measurements error: $e');
      return [];
    }
  }

  /// Get a specific measurement by ID
  Future<KorraMeasurementResult?> getMeasurement(String measurementId) async {
    try {
      final response = await _dio.get(
        '/api/v2/measurements/$measurementId',
        options: _authOptions,
      );

      return KorraMeasurementResult.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('[KORRA] Get measurement failed: ${_dioError(e)}');
      return null;
    } catch (e) {
      debugPrint('[KORRA] Get measurement error: $e');
      return null;
    }
  }

  /// Delete a measurement by ID
  Future<bool> deleteMeasurement(String measurementId) async {
    try {
      await _dio.delete(
        '/api/v2/measurements/$measurementId',
        options: _authOptions,
      );
      return true;
    } on DioException catch (e) {
      debugPrint('[KORRA] Delete measurement failed: ${_dioError(e)}');
      return false;
    } catch (e) {
      debugPrint('[KORRA] Delete measurement error: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // MEASUREMENTS - PDF
  // ---------------------------------------------------------------------------

  /// Download measurement PDF as bytes
  Future<List<int>?> downloadMeasurementPdf(String measurementId) async {
    try {
      final response = await _dio.get(
        '/api/v2/measurements/$measurementId/pdf',
        options: Options(
          headers: {
            if (_apiKey != null) 'X-API-Key': _apiKey,
            'Accept': 'application/pdf',
          },
          responseType: ResponseType.bytes,
        ),
      );

      return response.data as List<int>;
    } on DioException catch (e) {
      debugPrint('[KORRA] Download PDF failed: ${_dioError(e)}');
      return null;
    } catch (e) {
      debugPrint('[KORRA] Download PDF error: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // MEASUREMENTS - Task Status (async polling)
  // ---------------------------------------------------------------------------

  /// Check async extraction task status
  Future<KorraTaskStatus?> getTaskStatus(String taskId) async {
    try {
      final response = await _dio.get(
        '/api/v2/measurements/status/$taskId',
        options: _authOptions,
      );

      return KorraTaskStatus.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('[KORRA] Task status failed: ${_dioError(e)}');
      return null;
    } catch (e) {
      debugPrint('[KORRA] Task status error: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // MEASUREMENTS - Back-calculate
  // ---------------------------------------------------------------------------

  /// Back-calculate measurements from garment specifications
  Future<KorraMeasurementResult> backCalculate({
    required String measurementId,
    required Map<String, dynamic> garmentSpecs,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v2/measurements/$measurementId/back-calculate',
        data: garmentSpecs,
        options: _authOptions,
      );

      return KorraMeasurementResult.fromJson(response.data);
    } on DioException catch (e) {
      return KorraMeasurementResult.error(_dioError(e));
    } catch (e) {
      return KorraMeasurementResult.error('Unexpected error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // MEASUREMENTS - Garment Drape
  // ---------------------------------------------------------------------------

  /// Drape a garment on a scanned body
  Future<KorraDrapeResult> drapeGarment({
    required String scanId,
    required String garmentModel,
    Map<String, dynamic>? options,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v2/measurements/$scanId/garment/drape',
        data: {'garment_model': garmentModel, if (options != null) ...options},
        options: _authOptions,
      );

      return KorraDrapeResult.fromJson(response.data);
    } on DioException catch (e) {
      return KorraDrapeResult.error(_dioError(e));
    } catch (e) {
      return KorraDrapeResult.error('Unexpected error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // BODY SHAPE
  // ---------------------------------------------------------------------------

  /// Compute body shape from physiological parameters
  ///
  /// Korra uses an ML model with these float parameters:
  /// [gender] 0.0=female, 1.0=male
  /// [age] 0.0-1.0 normalized
  /// [muscle] 0.0-1.0 muscle mass level
  /// [weight] 0.0-1.0 normalized weight
  /// [height] 0.0-1.0 normalized height
  /// [proportions] 0.0-1.0 body proportions
  /// [cupsize] 0.0-1.0 (female only)
  /// [firmness] 0.0-1.0 body firmness
  /// Race params: [african], [asian], [caucasian] (0.0 or 1.0)
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
  }) async {
    try {
      final response = await _dio.post(
        '/api/v2/body-shape/compute',
        data: {
          'gender': gender,
          'age': age,
          'muscle': muscle,
          'weight': weight,
          'height': height,
          'proportions': proportions,
          'cupsize': cupsize,
          'firmness': firmness,
          'african': african,
          'asian': asian,
          'caucasian': caucasian,
        },
        options: _authOptions,
      );

      return KorraBodyShapeResult.fromJson(response.data);
    } on DioException catch (e) {
      return KorraBodyShapeResult.error(_dioError(e));
    } catch (e) {
      return KorraBodyShapeResult.error('Unexpected error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // TRY-ON
  // ---------------------------------------------------------------------------

  /// Start a virtual try-on session
  Future<KorraTryOnSession?> startTryOn({
    required String scanId,
    required String garmentId,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v2/tryon',
        data: {'scan_id': scanId, 'garment_id': garmentId},
        options: _authOptions,
      );

      return KorraTryOnSession.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('[KORRA] Try-on failed: ${_dioError(e)}');
      return null;
    } catch (e) {
      debugPrint('[KORRA] Try-on error: $e');
      return null;
    }
  }

  /// Capture a try-on result
  Future<KorraTryOnCapture?> captureTryOn({
    required String sessionId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v2/tryon/capture',
        data: {'session_id': sessionId, if (metadata != null) ...metadata},
        options: _authOptions,
      );

      return KorraTryOnCapture.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('[KORRA] Capture try-on failed: ${_dioError(e)}');
      return null;
    } catch (e) {
      debugPrint('[KORRA] Capture try-on error: $e');
      return null;
    }
  }

  /// List try-on captures
  Future<List<KorraTryOnCapture>> listTryOnCaptures() async {
    try {
      final response = await _dio.get(
        '/api/v2/tryon/captures',
        options: _authOptions,
      );

      final data = response.data;
      if (data is Map && data.containsKey('captures')) {
        return (data['captures'] as List)
            .map((e) => KorraTryOnCapture.fromJson(e))
            .toList();
      }
      if (data is List) {
        return data.map((e) => KorraTryOnCapture.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('[KORRA] List captures failed: ${_dioError(e)}');
      return [];
    } catch (e) {
      debugPrint('[KORRA] List captures error: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // GARMENT MODELS
  // ---------------------------------------------------------------------------

  /// Download a garment model (GLB binary file)
  ///
  /// Returns the raw bytes of the GLB file. Caller should save to disk.
  /// [type] is 'agbada' or 'huipil'.
  Future<Uint8List?> downloadGarmentModel(String type) async {
    try {
      final response = await _dio.get(
        '/api/v2/garment-models/$type',
        options: _authOptions.copyWith(responseType: ResponseType.bytes),
      );
      return response.data as Uint8List?;
    } on DioException catch (e) {
      debugPrint('[KORRA] Download garment model $type failed: $e');
      return null;
    } catch (e) {
      debugPrint('[KORRA] Download garment model $type failed: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // CLIENTS
  // ---------------------------------------------------------------------------

  /// List clients from Korra
  Future<List<KorraClientInfo>> listClients() async {
    try {
      final response = await _dio.get('/api/v2/clients', options: _authOptions);

      final data = response.data;
      if (data is Map && data.containsKey('clients')) {
        return (data['clients'] as List)
            .map((e) => KorraClientInfo.fromJson(e))
            .toList();
      }
      if (data is List) {
        return data.map((e) => KorraClientInfo.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('[KORRA] List clients failed: ${_dioError(e)}');
      return [];
    } catch (e) {
      debugPrint('[KORRA] List clients error: $e');
      return [];
    }
  }

  /// Get client measurements from Korra
  Future<List<KorraMeasurementSummary>> getClientMeasurements(
    String clientName,
  ) async {
    try {
      final response = await _dio.get(
        '/api/v2/clients/$clientName/measurements',
        options: _authOptions,
      );

      final data = response.data;
      if (data is Map && data.containsKey('measurements')) {
        return (data['measurements'] as List)
            .map((e) => KorraMeasurementSummary.fromJson(e))
            .toList();
      }
      if (data is List) {
        return data.map((e) => KorraMeasurementSummary.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('[KORRA] Get client measurements failed: ${_dioError(e)}');
      return [];
    } catch (e) {
      debugPrint('[KORRA] Get client measurements error: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // PROFILE
  // ---------------------------------------------------------------------------

  /// Get user profile from Korra
  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final response = await _dio.get('/api/v2/profile', options: _authOptions);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      debugPrint('[KORRA] Get profile failed: ${_dioError(e)}');
      return null;
    } catch (e) {
      debugPrint('[KORRA] Get profile error: $e');
      return null;
    }
  }

  /// Update user profile on Korra
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      await _dio.put('/api/v2/profile', data: data, options: _authOptions);
      return true;
    } on DioException catch (e) {
      debugPrint('[KORRA] Update profile failed: ${_dioError(e)}');
      return false;
    } catch (e) {
      debugPrint('[KORRA] Update profile error: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // SUBSCRIPTIONS
  // ---------------------------------------------------------------------------

  /// Get subscription status
  Future<KorraSubscriptionStatus?> getSubscriptionStatus() async {
    try {
      final response = await _dio.get(
        '/api/v2/subscriptions/status',
        options: _authOptions,
      );
      return KorraSubscriptionStatus.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('[KORRA] Get subscription failed: ${_dioError(e)}');
      return null;
    } catch (e) {
      debugPrint('[KORRA] Get subscription error: $e');
      return null;
    }
  }

  /// Get available subscription plans
  Future<List<KorraSubscriptionPlan>> getSubscriptionPlans() async {
    try {
      final response = await _dio.get(
        '/api/v2/subscription-plans',
        options: _authOptions,
      );

      final data = response.data;
      if (data is Map && data.containsKey('plans')) {
        return (data['plans'] as List)
            .map((e) => KorraSubscriptionPlan.fromJson(e))
            .toList();
      }
      if (data is List) {
        return data.map((e) => KorraSubscriptionPlan.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('[KORRA] Get plans failed: ${_dioError(e)}');
      return [];
    } catch (e) {
      debugPrint('[KORRA] Get plans error: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // INVOICES
  // ---------------------------------------------------------------------------

  /// List invoices
  Future<List<KorraInvoice>> listInvoices() async {
    try {
      final response = await _dio.get(
        '/api/v2/invoices',
        options: _authOptions,
      );

      final data = response.data;
      if (data is Map && data.containsKey('invoices')) {
        return (data['invoices'] as List)
            .map((e) => KorraInvoice.fromJson(e))
            .toList();
      }
      if (data is List) {
        return data.map((e) => KorraInvoice.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('[KORRA] List invoices failed: ${_dioError(e)}');
      return [];
    } catch (e) {
      debugPrint('[KORRA] List invoices error: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // NOTIFICATIONS
  // ---------------------------------------------------------------------------

  /// List notifications
  Future<List<KorraNotification>> listNotifications() async {
    try {
      final response = await _dio.get(
        '/api/v2/notifications',
        options: _authOptions,
      );

      final data = response.data;
      if (data is Map && data.containsKey('notifications')) {
        return (data['notifications'] as List)
            .map((e) => KorraNotification.fromJson(e))
            .toList();
      }
      if (data is List) {
        return data.map((e) => KorraNotification.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('[KORRA] List notifications failed: ${_dioError(e)}');
      return [];
    } catch (e) {
      debugPrint('[KORRA] List notifications error: $e');
      return [];
    }
  }

  /// Get unread notification count
  Future<int> getUnreadNotificationCount() async {
    try {
      final response = await _dio.get(
        '/api/v2/notifications/unread-count',
        options: _authOptions,
      );
      return response.data['count'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // ---------------------------------------------------------------------------
  // AI ASSISTANT
  // ---------------------------------------------------------------------------

  /// Ask AI fashion assistant
  Future<String?> aiAssist({
    required String query,
    Map<String, dynamic>? context,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v2/ai/assist',
        data: {'prompt': query, if (context != null) ...context},
        options: _authOptions,
      );
      return response.data['response'] ?? response.data['answer'];
    } on DioException catch (e) {
      debugPrint('[KORRA] AI assist failed: ${_dioError(e)}');
      return null;
    } catch (e) {
      debugPrint('[KORRA] AI assist error: $e');
      return null;
    }
  }

  /// Refine / impute missing measurements
  Future<KorraMeasurementResult> refineMeasurements({
    required Map<String, double> measurements,
    required String gender,
    double? heightCm,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v2/refinement/impute',
        data: {
          'measurements': measurements,
          'gender': gender,
          if (heightCm != null) 'height': heightCm,
        },
        options: _authOptions,
      );

      return KorraMeasurementResult.fromJson(response.data);
    } on DioException catch (e) {
      return KorraMeasurementResult.error(_dioError(e));
    } catch (e) {
      return KorraMeasurementResult.error('Unexpected error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  String _dioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please try again.';
      case DioExceptionType.connectionError:
        return 'Cannot reach Korra AI service. Check your connection.';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message =
            e.response?.data?['error'] ?? e.response?.data?['detail'];
        return 'Server error ${statusCode ?? ""}: ${message ?? "Unknown error"}';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      default:
        return 'Network error: ${e.message}';
    }
  }

  void dispose() {
    _dio.close();
  }
}

// =============================================================================
// DATA MODELS
// =============================================================================

/// Measurement result from Korra extraction
class KorraMeasurementResult {
  final bool success;
  final Map<String, double>? measurements;
  final String? error;
  final double? processingTime;
  final String? measurementId;
  final String? gender;
  final double? heightCm;
  final String accuracyMode;
  final String accuracy;

  KorraMeasurementResult({
    required this.success,
    this.measurements,
    this.error,
    this.processingTime,
    this.measurementId,
    this.gender,
    this.heightCm,
    this.accuracyMode = 'dual',
    this.accuracy = '±1-3cm',
  });

  factory KorraMeasurementResult.fromJson(Map<String, dynamic> json) {
    return KorraMeasurementResult(
      success: json['success'] ?? false,
      measurements: (json['measurements'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
      error: json['error'],
      processingTime: json['processing_time_seconds']?.toDouble(),
      measurementId: json['measurement_id'] ?? json['image_id'],
      gender: json['gender'],
      heightCm:
          json['user_height_cm']?.toDouble() ?? json['height']?.toDouble(),
      accuracyMode: json['accuracy_mode'] ?? 'dual',
      accuracy: json['accuracy'] ?? '±1-3cm',
    );
  }

  factory KorraMeasurementResult.error(String error) {
    return KorraMeasurementResult(success: false, error: error);
  }
}

/// Measurement summary (for list views)
class KorraMeasurementSummary {
  final String id;
  final String? gender;
  final double? heightCm;
  final int? measurementCount;
  final String? accuracyMode;
  final DateTime? createdAt;

  KorraMeasurementSummary({
    required this.id,
    this.gender,
    this.heightCm,
    this.measurementCount,
    this.accuracyMode,
    this.createdAt,
  });

  factory KorraMeasurementSummary.fromJson(Map<String, dynamic> json) {
    return KorraMeasurementSummary(
      id: json['measurement_id'] ?? json['id'] ?? '',
      gender: json['gender'],
      heightCm:
          json['user_height_cm']?.toDouble() ?? json['height']?.toDouble(),
      measurementCount: json['measurement_count'],
      accuracyMode: json['accuracy_mode'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }
}

/// Task status for async operations
class KorraTaskStatus {
  final String taskId;
  final String status;
  final String? result;
  final String? error;

  KorraTaskStatus({
    required this.taskId,
    required this.status,
    this.result,
    this.error,
  });

  factory KorraTaskStatus.fromJson(Map<String, dynamic> json) {
    return KorraTaskStatus(
      taskId: json['task_id'] ?? '',
      status: json['status'] ?? 'unknown',
      result: json['result'],
      error: json['error'],
    );
  }

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isProcessing => status == 'processing' || status == 'pending';
}

/// Garment drape result
class KorraDrapeResult {
  final bool success;
  final String? drapeUrl;
  final String? error;

  KorraDrapeResult({required this.success, this.drapeUrl, this.error});

  factory KorraDrapeResult.fromJson(Map<String, dynamic> json) {
    return KorraDrapeResult(
      success: json['success'] ?? false,
      drapeUrl: json['drape_url'] ?? json['result_url'],
      error: json['error'],
    );
  }

  factory KorraDrapeResult.error(String error) {
    return KorraDrapeResult(success: false, error: error);
  }
}

/// Body shape result
class KorraBodyShapeResult {
  final bool success;
  final String? bodyShape;
  final Map<String, dynamic>? details;
  final String? error;

  KorraBodyShapeResult({
    required this.success,
    this.bodyShape,
    this.details,
    this.error,
  });

  factory KorraBodyShapeResult.fromJson(Map<String, dynamic> json) {
    return KorraBodyShapeResult(
      success: json['success'] ?? false,
      bodyShape: json['body_shape'] ?? json['shape'],
      details: json['details'],
      error: json['error'],
    );
  }

  factory KorraBodyShapeResult.error(String error) {
    return KorraBodyShapeResult(success: false, error: error);
  }
}

/// Try-on session
class KorraTryOnSession {
  final String sessionId;
  final String status;
  final String? resultUrl;

  KorraTryOnSession({
    required this.sessionId,
    required this.status,
    this.resultUrl,
  });

  factory KorraTryOnSession.fromJson(Map<String, dynamic> json) {
    return KorraTryOnSession(
      sessionId: json['session_id'] ?? json['id'] ?? '',
      status: json['status'] ?? 'pending',
      resultUrl: json['result_url'],
    );
  }
}

/// Try-on capture
class KorraTryOnCapture {
  final String captureId;
  final String? imageUrl;
  final DateTime? createdAt;

  KorraTryOnCapture({required this.captureId, this.imageUrl, this.createdAt});

  factory KorraTryOnCapture.fromJson(Map<String, dynamic> json) {
    return KorraTryOnCapture(
      captureId: json['capture_id'] ?? json['id'] ?? '',
      imageUrl: json['image_url'] ?? json['url'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }
}

/// Garment model
class KorraGarmentModel {
  final String type;
  final String? modelUrl;
  final String? name;

  KorraGarmentModel({required this.type, this.modelUrl, this.name});

  factory KorraGarmentModel.fromJson(Map<String, dynamic> json) {
    return KorraGarmentModel(
      type: json['type'] ?? json['name'] ?? '',
      modelUrl: json['model_url'] ?? json['url'],
      name: json['name'] ?? json['display_name'],
    );
  }
}

/// Client info from Korra
class KorraClientInfo {
  final String name;
  final int? measurementCount;
  final DateTime? lastScanAt;

  KorraClientInfo({required this.name, this.measurementCount, this.lastScanAt});

  factory KorraClientInfo.fromJson(Map<String, dynamic> json) {
    return KorraClientInfo(
      name: json['name'] ?? json['client_name'] ?? '',
      measurementCount: json['measurement_count'],
      lastScanAt: json['last_scan_at'] != null
          ? DateTime.tryParse(json['last_scan_at'])
          : null,
    );
  }
}

/// Subscription status
class KorraSubscriptionStatus {
  final String plan;
  final String status;
  final DateTime? expiresAt;
  final int? scansUsed;
  final int? scansLimit;

  KorraSubscriptionStatus({
    required this.plan,
    required this.status,
    this.expiresAt,
    this.scansUsed,
    this.scansLimit,
  });

  factory KorraSubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return KorraSubscriptionStatus(
      plan: json['plan'] ?? json['plan_id'] ?? 'free',
      status: json['status'] ?? 'active',
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'])
          : null,
      scansUsed: json['scans_used'],
      scansLimit: json['scans_limit'],
    );
  }
}

/// Subscription plan
class KorraSubscriptionPlan {
  final String id;
  final String name;
  final double price;
  final String currency;
  final List<String> features;

  KorraSubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
    required this.features,
  });

  factory KorraSubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return KorraSubscriptionPlan(
      id: json['id'] ?? json['plan_id'] ?? '',
      name: json['name'] ?? json['plan_name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'NGN',
      features: List<String>.from(json['features'] ?? []),
    );
  }
}

/// Invoice
class KorraInvoice {
  final String id;
  final String? description;
  final double amount;
  final String currency;
  final String status;
  final DateTime? createdAt;

  KorraInvoice({
    required this.id,
    this.description,
    required this.amount,
    required this.currency,
    required this.status,
    this.createdAt,
  });

  factory KorraInvoice.fromJson(Map<String, dynamic> json) {
    return KorraInvoice(
      id: json['id'] ?? json['invoice_id'] ?? '',
      description: json['description'],
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'NGN',
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }
}

/// Korra notification
class KorraNotification {
  final String id;
  final String? title;
  final String? body;
  final String? type;
  final bool read;
  final DateTime? createdAt;

  KorraNotification({
    required this.id,
    this.title,
    this.body,
    this.type,
    this.read = false,
    this.createdAt,
  });

  factory KorraNotification.fromJson(Map<String, dynamic> json) {
    return KorraNotification(
      id: json['id'] ?? json['notification_id'] ?? '',
      title: json['title'],
      body: json['body'] ?? json['message'],
      type: json['type'],
      read: json['read'] ?? json['is_read'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }
}
