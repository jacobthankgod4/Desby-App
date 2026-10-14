import 'package:flutter/material.dart';

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
}) async => false;
