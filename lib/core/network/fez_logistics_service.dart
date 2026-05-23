import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class FezLogisticsService {
  final Dio _dio;
  static const String _baseUrl = 'https://apisandbox.fezdelivery.co/v1';
  static const String _secretKey = 'kl6NxZuveIz_2sZGkKq2TvhXjCwwR2HmqsX4GtHNIlkZPx23ZvaGg94GTNuBMO9C';
  
  String? _authToken;

  FezLogisticsService(this._dio);

  Future<bool> authenticate(String userId, String password) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/user/authenticate',
        data: {
          'user_id': userId,
          'password': password,
        },
      );

      if (response.data['status'] == 'Success') {
        _authToken = response.data['authDetails']['authToken'];
        return true;
      }
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
    try {
      final response = await _dio.post(
        '$_baseUrl/order/cost',
        data: {
          'state': state,
          'pickUpState': pickUpState,
          'weight': weight,
        },
        options: Options(headers: _headers),
      );

      if (response.data['status'] == 'Success') {
        return response.data;
      }
      return null;
    } catch (e) {
      debugPrint('Fez Cost Fetch Error: $e');
      return null;
    }
  }

  Future<String?> createOrder(Map<String, dynamic> orderData) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/orders/import',
        data: [orderData],
        options: Options(headers: _headers),
      );

      if (response.data['status'] == 'Success') {
        final orderNos = response.data['orderNos'] as Map<String, dynamic>;
        return orderNos.values.first.toString();
      }
      return null;
    } catch (e) {
      debugPrint('Fez Order Creation Error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> trackOrder(String orderNumber) async {
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
    'secret-key': _secretKey,
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };
}
