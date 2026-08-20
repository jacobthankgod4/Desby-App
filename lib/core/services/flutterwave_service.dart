import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

class FlutterwaveService {
  static final FlutterwaveService _instance = FlutterwaveService._internal();
  factory FlutterwaveService() => _instance;
  FlutterwaveService._internal();

  String get _publicKey => dotenv.get('FLUTTERWAVE_PUBLIC_KEY', fallback: '');
  String get _secretKey => dotenv.get('FLUTTERWAVE_SECRET_KEY', fallback: '');
  String get _redirectUrl => dotenv.get('PAYMENT_REDIRECT_URL', fallback: 'https://desby.app/payment-callback');

  Future<void> checkout({
    required BuildContext context,
    required String email,
    required String fullName,
    required double amount,
    required String orderId,
    String? phone,
    String? subAccountCode,
    required Function(String) onSuccess,
    required VoidCallback onCancel,
  }) async {
    final String txRef = 'DESBY_${const Uuid().v4().substring(0, 8)}';

    if (kIsWeb) {
      await _webCheckout(
        email: email,
        fullName: fullName,
        amount: amount,
        txRef: txRef,
        orderId: orderId,
        onSuccess: onSuccess,
        onCancel: onCancel,
      );
    } else {
      await _mobileCheckout(
        context: context,
        email: email,
        fullName: fullName,
        amount: amount,
        txRef: txRef,
        orderId: orderId,
        phone: phone,
        onSuccess: onSuccess,
        onCancel: onCancel,
      );
    }
  }

  /// Web: Initialize payment via Flutterwave API, then redirect to hosted checkout
  Future<void> _webCheckout({
    required String email,
    required String fullName,
    required double amount,
    required String txRef,
    required String orderId,
    required Function(String) onSuccess,
    required VoidCallback onCancel,
  }) async {
    try {
      // Step 1: Initialize payment via Flutterwave v3 API
      final response = await http.post(
        Uri.parse('https://api.flutterwave.com/v3/payments'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'tx_ref': txRef,
          'amount': amount.toStringAsFixed(0),
          'currency': 'NGN',
          'redirect_url': _redirectUrl,
          'customer': {
            'email': email,
            'name': fullName,
          },
          'payment_options': 'card,banktransfer,ussd',
          'customizations': {
            'title': 'Desby OS',
            'description': 'Payment for Order #$orderId',
          },
        }),
      );

      final data = jsonDecode(response.body);

      if (data['status'] == 'success' && data['data'] != null) {
        final checkoutUrl = data['data']['link'];
        if (checkoutUrl != null && checkoutUrl.toString().isNotEmpty) {
          // Step 2: Redirect to Flutterwave hosted checkout
          final uri = Uri.parse(checkoutUrl.toString());
          if (await canLaunchUrl(uri)) {
            // Open in same window — user completes payment, gets redirected back
            await launchUrl(uri, mode: LaunchMode.inAppWebView);
            onSuccess(txRef);
          } else {
            onCancel();
          }
        } else {
          debugPrint('❌ [FLUTTERWAVE] No checkout link in response');
          onCancel();
        }
      } else {
        debugPrint('❌ [FLUTTERWAVE] Init failed: ${data['message']}');
        onCancel();
      }
    } catch (e) {
      debugPrint('❌ [FLUTTERWAVE] Web checkout error: $e');
      onCancel();
    }
  }

  /// Mobile: Initialize payment and open in-app WebView
  Future<void> _mobileCheckout({
    required BuildContext context,
    required String email,
    required String fullName,
    required double amount,
    required String txRef,
    required String orderId,
    String? phone,
    required Function(String) onSuccess,
    required VoidCallback onCancel,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.flutterwave.com/v3/payments'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'tx_ref': txRef,
          'amount': amount.toStringAsFixed(0),
          'currency': 'NGN',
          'redirect_url': _redirectUrl,
          'customer': {
            'email': email,
            'name': fullName,
            if (phone != null) 'phone_number': phone,
          },
          'payment_options': 'card,banktransfer,ussd',
          'customizations': {
            'title': 'Desby OS',
            'description': 'Payment for Order #$orderId',
          },
        }),
      );

      final data = jsonDecode(response.body);

      if (data['status'] == 'success' && data['data'] != null) {
        final checkoutUrl = data['data']['link'];
        if (checkoutUrl != null) {
          final uri = Uri.parse(checkoutUrl.toString());
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.inAppWebView);
            onSuccess(txRef);
          } else {
            onCancel();
          }
        } else {
          onCancel();
        }
      } else {
        onCancel();
      }
    } catch (e) {
      debugPrint('❌ [FLUTTERWAVE] Mobile error: $e');
      onCancel();
    }
  }

  /// Verify a transaction with Flutterwave API
  Future<bool> verifyTransaction(String txRef) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.flutterwave.com/v3/transactions/verify?tx_ref=$txRef'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        final txData = data['data'];
        return txData['status'] == 'successful' && txData['tx_ref'] == txRef;
      }
      return false;
    } catch (e) {
      debugPrint('❌ [FLUTTERWAVE] Verify error: $e');
      return false;
    }
  }
}
