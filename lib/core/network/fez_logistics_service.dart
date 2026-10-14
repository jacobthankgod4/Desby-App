import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../config/environment.dart';

class FezLogisticsService {
  final Dio _dio;
  String get _baseUrl => Environment.current.fezLogisticsBaseUrl;

  String? _authToken;

  FezLogisticsService(this._dio);

  /// Fez rejects every call except `/user/authenticate` without a bearer token,
  /// so credentials are resolved lazily and cached until they stop working.
  bool _authenticating = false;

  /// Returns true when a usable token is held, obtaining one if needed.
  ///
  /// Returns false when credentials are not configured or were rejected — the
  /// caller surfaces that rather than silently pretending there is no estimate.
  Future<bool> ensureAuthenticated() async {
    if (_authToken != null && _authToken!.isNotEmpty) return true;
    // Guard against the two concurrent callers both starting a login.
    if (_authenticating) return false;

    // Fez requires BOTH a `secret-key` header (which we have) AND a bearer
    // token obtained from /user/authenticate via a per-account user id +
    // password (which we do not — Fez issues those only after KYC review).
    // With only the secret key, Fez answers 401 "Invalid session".
    if (!Environment.current.fezLogisticsProvisioned) {
      debugPrint(
        '[FEZ] Account credentials not provisioned — Fez issues a login via '
        'user_id + password; the secret key cannot authenticate. Courier '
        'pricing and dispatch are unavailable until Fez provides them.',
      );
      return false;
    }
    final userId = Environment.current.fezLogisticsUserId;
    final password = Environment.current.fezLogisticsPassword;

    _authenticating = true;
    try {
      return await authenticate(userId, password);
    } finally {
      _authenticating = false;
    }
  }

  Future<bool> authenticate(String userId, String password) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/user/authenticate',
        data: {'user_id': userId, 'password': password},
        options: Options(headers: _headers),
      );

      if (response.data['status'] == 'Success') {
        _authToken = response.data['authDetails']?['authToken'] as String?;
        if (_authToken == null || _authToken!.isEmpty) {
          debugPrint('[FEZ] Auth succeeded but no authToken returned');
          return false;
        }
        return true;
      }
      debugPrint('[FEZ] Auth rejected: ${response.data['description']}');
      return false;
    } on DioException catch (e) {
      debugPrint('[FEZ] Auth HTTP error ${e.response?.statusCode}: ${e.response?.data}');
      return false;
    } catch (e) {
      debugPrint('Fez Auth Error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getDeliveryCost({
    required String state,
    String? pickUpState,
    double? weight,
  }) async {
    if (!await ensureAuthenticated()) return null;
    try {
      final response = await _dio.post(
        '$_baseUrl/order/cost',
        data: {'state': state, 'pickUpState': pickUpState, 'weight': weight},
        options: Options(headers: _headers),
      );

      if (response.data['status'] == 'Success') {
        return response.data;
      }
      debugPrint('[FEZ] Cost rejected: ${response.data['description']}');
      return null;
    } on DioException catch (e) {
      debugPrint(
        '[FEZ] Cost HTTP ${e.response?.statusCode}: ${e.response?.data}',
      );
      return null;
    } catch (e) {
      debugPrint('Fez Cost Fetch Error: $e');
      return null;
    }
  }

  Future<String?> createOrder(Map<String, dynamic> orderData) async {
    if (!await ensureAuthenticated()) return null;
    try {
      final response = await _dio.post(
        '$_baseUrl/orders/import',
        data: [orderData],
        options: Options(headers: _headers),
      );

      if (response.data['status'] == 'Success') {
        final orderNos =
            (response.data['orderNos'] as Map<String, dynamic>?) ?? {};
        return orderNos.values.first.toString();
      }
      return null;
    } catch (e) {
      debugPrint('Fez Order Creation Error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> trackOrder(String orderNumber) async {
    if (!await ensureAuthenticated()) return null;
    try {
      final response = await _dio.get(
        '$_baseUrl/order/track/$orderNumber',
        options: Options(headers: _headers),
      );

      if (response.data['status'] == 'Success') {
        return response.data;
      }
      return null;
    } catch (e) {
      debugPrint('Fez Tracking Error: $e');
      return null;
    }
  }

  Map<String, String> get _headers => {
    'secret-key': Environment.current.fezLogisticsSecretKey,
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };
}
