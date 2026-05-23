import 'package:dio/dio.dart';
import '../logging/logger.dart';

class PaystackService {
  final Dio _dio;
  final String _secretKey = 'YOUR_PAYSTACK_SECRET_KEY'; // Placeholder

  PaystackService(this._dio);

  /// Initialize a transaction
  Future<String?> initializeTransaction({
    required String email,
    required double amount,
    required String reference,
  }) async {
    try {
      final response = await _dio.post(
        'https://api.paystack.co/transaction/initialize',
        data: {
          'email': email,
          'amount': (amount * 100).toInt(), // Paystack uses kobo/cents
          'reference': reference,
          'callback_url': 'https://desby.os/payment-callback',
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $_secretKey',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data['data']['authorization_url'];
      }
      return null;
    } catch (e) {
      logger.error('Paystack initialization failed', error: e);
      return null;
    }
  }

  /// Verify a transaction
  Future<bool> verifyTransaction(String reference) async {
    try {
      final response = await _dio.get(
        'https://api.paystack.co/transaction/verify/$reference',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_secretKey',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data['data']['status'] == 'success';
      }
      return false;
    } catch (e) {
      logger.error('Paystack verification failed', error: e);
      return false;
    }
  }
}
