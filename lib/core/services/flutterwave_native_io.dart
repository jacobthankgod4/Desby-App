import 'package:flutter/material.dart';
import 'package:flutterwave_standard/flutterwave.dart';

Future<bool> checkoutNative({
  required BuildContext context,
  required String publicKey,
  required String txRef,
  required double amount,
  required String email,
  required String fullName,
  String? phone,
  required String redirectUrl,
  required bool isTestMode,
  required String logoUrl,
  required void Function(String txRef) onSuccess,
  required VoidCallback onCancel,
}) async {
  if (publicKey.trim().isEmpty) return false;

  try {
    final response = await Flutterwave(
      publicKey: publicKey,
      txRef: txRef,
      amount: amount.toStringAsFixed(2),
      customer: Customer(email: email, name: fullName, phoneNumber: phone),
      paymentOptions: 'card,mobilemoney,banktransfer',
      customization: Customization(
        title: 'Desby',
        description: 'Order payment',
        logo: logoUrl,
      ),
      redirectUrl: redirectUrl,
      isTestMode: isTestMode,
      currency: 'NGN',
    ).charge(context);

    final responseTxRef = response.txRef;
    if (response.success == true &&
        responseTxRef != null &&
        responseTxRef.isNotEmpty) {
      onSuccess(responseTxRef);
    } else {
      onCancel();
    }
    return true;
  } catch (_) {
    return false;
  }
}
