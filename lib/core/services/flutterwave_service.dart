import 'package:flutter/material.dart';
import 'package:flutterwave_standard/flutterwave.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';

class FlutterwaveService {
  static final FlutterwaveService _instance = FlutterwaveService._internal();
  factory FlutterwaveService() => _instance;
  FlutterwaveService._internal();

  String get _publicKey => dotenv.get('FLUTTERWAVE_PUBLIC_KEY', fallback: '');

  Future<void> checkout({
    required BuildContext context,
    required String email,
    required String fullName,
    required double amount,
    required String orderId,
    String? subAccountCode,
    required Function(String) onSuccess,
    required VoidCallback onCancel,
  }) async {
    try {
      final String txRef = 'DESBY_${const Uuid().v4().substring(0, 8)}';
      
      final Customer customer = Customer(
        name: fullName,
        email: email,
        phoneNumber: "0000000000",
      );

      final Flutterwave flutterwave = Flutterwave(
        publicKey: _publicKey,
        currency: "NGN",
        redirectUrl: dotenv.get('PAYMENT_REDIRECT_URL', fallback: 'https://desby.app/payment-callback'),
        txRef: txRef,
        amount: amount.toStringAsFixed(0),
        customer: customer,
        paymentOptions: "card, account, ussd",
        customization: Customization(
          title: "Desby OS",
          description: "Payment for Order #$orderId",
          logo: dotenv.get('APP_LOGO_URL', fallback: 'https://aemumiyzowraoachzxtu.supabase.co/storage/v1/object/public/assets/logo.png'),
        ),
        isTestMode: _publicKey.contains('TEST'),
      );

      // In version 1.1.0, charge() takes context as a positional argument
      final ChargeResponse response = await flutterwave.charge(context);

      if (response.status == "success" || response.success == true) {
        onSuccess(response.transactionId ?? txRef);
      } else {
        onCancel();
      }
    } catch (e) {
      debugPrint('❌ [FLUTTERWAVE] Error: $e');
      rethrow;
    }
  }
}
