import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import 'package:desby_app/config/environment.dart';

import 'flutterwave_native_stub.dart'
    if (dart.library.io) 'flutterwave_native_io.dart'
    as native;
import 'flutterwave_web_bridge_stub.dart'
    if (dart.library.js_interop) 'flutterwave_web_bridge.dart'
    as web;

class FlutterwaveService {
  static final FlutterwaveService _instance = FlutterwaveService._internal();
  factory FlutterwaveService() => _instance;
  FlutterwaveService._internal();

  String get _supabaseUrl => '${Environment.current.supabaseUrl}/functions/v1';
  String get _supabaseKey => Environment.current.supabaseAnonKey;

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
    final String publicKey = Environment.current.flutterwavePublicKey;

    if (!kIsWeb) {
      final nativeHandled = await native.checkoutNative(
        context: context,
        publicKey: publicKey,
        txRef: txRef,
        amount: amount,
        email: email,
        fullName: fullName,
        phone: phone,
        redirectUrl: Environment.current.paymentRedirectUrl,
        isTestMode: !Environment.current.isProduction,
        logoUrl: Environment.current.appLogoUrl,
        onSuccess: onSuccess,
        onCancel: onCancel,
      );
      if (!nativeHandled) {
        if (!context.mounted) {
          onCancel();
          return;
        }
        await _showTransferFallback(
          context: context,
          amount: amount,
          orderId: orderId,
          txRef: txRef,
          onSuccess: onSuccess,
          onCancel: onCancel,
        );
      }
      return;
    }

    final initData = await _initPayment(
      email: email,
      fullName: fullName,
      amount: amount,
      orderId: orderId,
      txRef: txRef,
    );
    if (initData == null) {
      onCancel();
      return;
    }

    final String serverTxRef = initData['tx_ref'] ?? txRef;
    final String serverPublicKey =
        initData['public_key'] ?? Environment.current.flutterwavePublicKey;

    await _checkoutInline(
      publicKey: serverPublicKey,
      txRef: serverTxRef,
      amount: amount,
      email: email,
      fullName: fullName,
      onSuccess: onSuccess,
      onCancel: onCancel,
    );
  }

  Future<void> _showTransferFallback({
    required BuildContext context,
    required double amount,
    required String orderId,
    required String txRef,
    required Function(String) onSuccess,
    required VoidCallback onCancel,
  }) async {
    if (!context.mounted) {
      onCancel();
      return;
    }

    final shouldCheck = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final textTheme = Theme.of(dialogContext).textTheme;
        return AlertDialog(
          title: const Text('PAY BY BANK TRANSFER'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Send ₦${amount.toStringAsFixed(0)} via transfer to '
                  'complete your order',
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'Order: $orderId',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Reference: $txRef', style: textTheme.bodySmall),
                const SizedBox(height: 12),
                Text(
                  'Complete the transfer, then check the payment status. '
                  'The order is confirmed only after verification succeeds.',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('CHECK PAYMENT STATUS'),
            ),
          ],
        );
      },
    );

    if (shouldCheck != true) {
      onCancel();
      return;
    }

    final verified = await verifyTransaction(txRef);
    if (verified) {
      onSuccess(txRef);
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Payment not found yet. Complete the transfer and try again.',
          ),
        ),
      );
    }
  }

  Future<void> _checkoutInline({
    required String publicKey,
    required String txRef,
    required double amount,
    required String email,
    required String fullName,
    required Function(String) onSuccess,
    required VoidCallback onCancel,
  }) async {
    try {
      final config = jsonEncode({
        'public_key': publicKey,
        'tx_ref': txRef,
        'amount': amount,
        'currency': 'NGN',
        'customer': {'email': email, 'name': fullName},
        'customizations': {
          'title': 'Desby',
          'description': 'Subscription Payment',
          'logo': 'https://desby.app/logo.png',
        },
      });

      final opened = await web.FlutterwaveWebBridge.openCheckout(config);
      if (!opened) {
        debugPrint('❌ [FLUTTERWAVE] v3.js SDK did not load');
        onCancel();
        return;
      }

      for (var i = 0; i < 600; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 200));

        if (web.FlutterwaveWebBridge.isDone) {
          final resultStr = web.FlutterwaveWebBridge.result;
          if (resultStr.isNotEmpty) {
            try {
              final resp = jsonDecode(resultStr) as Map;
              if (resp['status'] == 'successful') {
                debugPrint('✅ [FLUTTERWAVE] Payment successful: $txRef');
                onSuccess(txRef);
                return;
              }
            } catch (_) {}
          }
          onCancel();
          return;
        }

        if (web.FlutterwaveWebBridge.isClosed) {
          debugPrint('ℹ️ [FLUTTERWAVE] Modal closed by user');
          onCancel();
          return;
        }
      }

      onCancel();
    } catch (e) {
      debugPrint('❌ [FLUTTERWAVE] Inline error: $e');
      onCancel();
    }
  }

  // ── Payment init & verify ──

  Future<Map<String, dynamic>?> _initPayment({
    required String email,
    required String fullName,
    required double amount,
    required String orderId,
    required String txRef,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_supabaseUrl/flutterwave-pay'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_supabaseKey',
        },
        body: jsonEncode({
          'amount': amount,
          'email': email,
          'name': fullName,
          'tx_ref': txRef,
          'order_id': orderId,
        }),
      );

      final data = jsonDecode(response.body);
      if (data['status'] == 'success') return data;
      debugPrint('❌ [FLUTTERWAVE] Init failed: ${data['message']}');
      return null;
    } catch (e) {
      debugPrint('❌ [FLUTTERWAVE] Init error: $e');
      return null;
    }
  }

  /// Verifies [txRef] with the server. The server is the authority: it checks
  /// Flutterwave using the secret key and settles the order. A `true` here
  /// means the order is genuinely paid, not that the browser said so.
  Future<bool> verifyTransaction(String txRef, {String? orderId}) async {
    try {
      final query = <String, String>{'tx_ref': txRef};
      if (orderId != null && orderId.isNotEmpty) query['order_id'] = orderId;
      final uri = Uri.parse('$_supabaseUrl/flutterwave-verify')
          .replace(queryParameters: query);
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_supabaseKey',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['verified'] == true) return true;
      }
    } catch (e) {
      debugPrint('⚠️ [FLUTTERWAVE] Verify failed: $e');
    }

    return false;
  }
}
