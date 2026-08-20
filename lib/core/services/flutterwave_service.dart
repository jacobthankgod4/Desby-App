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

  /// Initiates Flutterwave checkout.
  /// Web: redirects to hosted checkout (no CORS).
  /// Mobile: uses inline SDK.
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
        subAccountCode: subAccountCode,
        onSuccess: onSuccess,
        onCancel: onCancel,
      );
    }
  }

  /// Web checkout: Opens Flutterwave hosted checkout in a new tab.
  /// After payment, user is redirected to callback URL.
  Future<void> _webCheckout({
    required String email,
    required String fullName,
    required double amount,
    required String txRef,
    required String orderId,
    required Function(String) onSuccess,
    required VoidCallback onCancel,
  }) async {
    final params = {
      'public_key': _publicKey,
      'tx_ref': txRef,
      'amount': amount.toStringAsFixed(0),
      'currency': 'NGN',
      'redirect_url': _redirectUrl,
      'customer[email]': email,
      'customer[name]': fullName,
      'payment_options': 'card,banktransfer,ussd',
      'customizations[title]': 'Desby OS',
      'customizations[description]': 'Payment for Order #$orderId',
    };

    final queryString = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final checkoutUrl = Uri.parse('https://checkout.flutterwave.com/pay?$queryString');

    if (await canLaunchUrl(checkoutUrl)) {
      // Open in new tab — user completes payment there
      await launchUrl(checkoutUrl, mode: LaunchMode.externalApplication);

      // Notify caller that payment flow started
      // Actual verification happens via redirect callback or webhook
      onSuccess(txRef);
    } else {
      onCancel();
    }
  }

  /// Mobile checkout: Uses flutterwave_standard inline SDK.
  Future<void> _mobileCheckout({
    required BuildContext context,
    required String email,
    required String fullName,
    required double amount,
    required String txRef,
    required String orderId,
    String? phone,
    String? subAccountCode,
    required Function(String) onSuccess,
    required VoidCallback onCancel,
  }) async {
    try {
      // Mobile uses the standard SDK (imported at package level)
      // This is handled by the subscription page which imports flutterwave_standard
      // For now, fall back to web-style redirect on mobile too
      final params = {
        'public_key': _publicKey,
        'tx_ref': txRef,
        'amount': amount.toStringAsFixed(0),
        'currency': 'NGN',
        'redirect_url': _redirectUrl,
        'customer[email]': email,
        'customer[name]': fullName,
        'payment_options': 'card,banktransfer,ussd',
        'customizations[title]': 'Desby OS',
        'customizations[description]': 'Payment for Order #$orderId',
      };

      final queryString = params.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final checkoutUrl = Uri.parse('https://checkout.flutterwave.com/pay?$queryString');

      if (await canLaunchUrl(checkoutUrl)) {
        await launchUrl(checkoutUrl, mode: LaunchMode.inAppWebView);
        onSuccess(txRef);
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
      final uri = Uri.parse('https://api.flutterwave.com/v3/transactions/verify?tx_ref=$txRef');
      final response = await _httpGet(uri, headers: {
        'Authorization': 'Bearer $_secretKey',
        'Content-Type': 'application/json',
      });

      if (response != null && response['status'] == 'success') {
        final data = response['data'];
        return data['status'] == 'successful' && data['tx_ref'] == txRef;
      }
      return false;
    } catch (e) {
      debugPrint('❌ [FLUTTERWAVE] Verify error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> _httpGet(Uri uri, {Map<String, String>? headers}) async {
    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
