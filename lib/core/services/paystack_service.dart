import 'package:flutter/material.dart';
import 'package:flutter_paystack_plus/flutter_paystack_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PaystackService {
  static final PaystackService _instance = PaystackService._internal();
  factory PaystackService() => _instance;
  PaystackService._internal();

  String get _publicKey => dotenv.get('PAYSTACK_PUBLIC_KEY', fallback: 'pk_test_xxxxxxxxxxxxxxxxxxxxxxxx');

  Future<void> checkout({
    required BuildContext context,
    required String email,
    required double amount,
    required String reference,
    String? subAccountCode, // NEW: For Split Payments
    required Function(String) onSuccess,
    required VoidCallback onCancel,
  }) async {
    try {
      final int amountInKobo = (amount * 100).toInt();

      await FlutterPaystackPlus.openPaystackPopup(
        publicKey: _publicKey,
        context: context,
        secretKey: '', 
        customerEmail: email,
        amount: amountInKobo.toString(),
        reference: reference,
        // EXPERT SPLIT: Passing subaccount code to Paystack engine
        metadata: {
          'subaccount': subAccountCode, 
          'bearer': 'subaccount', // Ensures the subaccount takes the ₦500 flat fee
        },
        onClosed: onCancel,
        onSuccess: () => onSuccess(reference),
      );
    } catch (e) {
      debugPrint('❌ [PAYSTACK] Error: $e');
      rethrow;
    }
  }
}
