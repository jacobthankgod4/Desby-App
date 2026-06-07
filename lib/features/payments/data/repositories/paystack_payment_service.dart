import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../../../config/paystack_config.dart';
import '../../domain/entities/payment.dart';
import '../../domain/exceptions/payment_exceptions.dart';
import '../../domain/services/payment_service.dart';
import '../models/paystack_transaction.dart';

/// Paystack Payment Service Implementation
/// 
/// This is a stub implementation. In production, integrate with 
/// flutter_paystack_plus or direct Paystack API.
class PaystackPaymentService implements PaymentService {
  /// Regex to validate Nigerian phone numbers
  static const String _phoneRegex = r'^(\+234|0)[0-9]{10}$';
  
  bool _initialized = false;

  PaystackPaymentService() {
    _initializePaystack();
  }

  /// Initialize Paystack SDK
  void _initializePaystack() {
    if (!PaystackConfig.isConfigured()) {
      debugPrint('[Paystack Service] Warning: Paystack not configured');
    }
    _initialized = true;
  }

  @override
  Future<String> createPaymentIntent(double amount, String currency) async {
    try {
      // Validate amount
      if (amount <= 0) {
        throw InvalidPaymentAmountException(
          message: 'Payment amount must be greater than 0',
          amount: amount,
        );
      }

      // Validate currency
      const supportedCurrencies = ['NGN', 'GHS', 'ZAR', 'KES', 'USD'];
      if (!supportedCurrencies.contains(currency)) {
        throw UnsupportedCurrencyException(
          message: 'Currency $currency is not supported by Paystack',
          currency: currency,
        );
      }

      // Generate a reference code
      final reference = _generateReference();

      debugPrint(
          '[Paystack Service] Created payment intent: Reference=$reference, Amount=$amount$currency');

      return reference;
    } on PaymentException {
      rethrow;
    } catch (e) {
      throw PaymentInitializationException(
        message: 'Failed to create payment intent: $e',
        originalError: e,
      );
    }
  }

  @override
  Future<Payment> processPayment(String intentId, PaymentMethod method) async {
    try {
      if (!PaystackConfig.isConfigured()) {
        throw PaystackNotConfiguredException(
          message: 'Paystack is not properly configured',
        );
      }

      // Return a pending payment (stub)
      final transaction = PaystackTransaction(
        id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
        orderId: 'ORD_$intentId',
        amount: 0.0,
        currency: 'NGN',
        status: PaymentStatus.pending,
        method: method,
        timestamp: DateTime.now(),
        transactionReference: intentId,
        paystackReference: intentId,
      );

      debugPrint('[Paystack Service] Processing payment: Reference=$intentId');

      return transaction;
    } on PaymentException {
      rethrow;
    } catch (e) {
      throw PaymentProcessingException(
        message: 'Failed to process payment: $e',
        reference: intentId,
        originalError: e,
      );
    }
  }

  /// Initialize Paystack checkout
  /// 
  /// Returns a [PaystackTransaction] with the result.
  /// In production, this would open the Paystack checkout UI.
  Future<PaystackTransaction> initiateCheckout({
    required double amount,
    required String email,
    required String orderId,
    String? phone,
    String? firstName,
    String? lastName,
    Map<String, String>? metadata,
  }) async {
    try {
      // Validate inputs
      if (amount <= 0) {
        throw InvalidPaymentAmountException(
          message: 'Amount must be greater than 0',
          amount: amount,
        );
      }

      if (!_isValidEmail(email)) {
        throw PaymentInitializationException(
          message: 'Invalid email address',
        );
      }

      if (phone != null && !_isValidPhoneNumber(phone)) {
        throw PaymentInitializationException(
          message: 'Invalid phone number format',
        );
      }

      // Generate reference
      final reference = _generateReference();

      debugPrint(
          '[Paystack Service] Initiating checkout: Reference=$reference, Amount=${amount}NGN, Email=$email');

      // Stub: Return success (in production, open Paystack checkout)
      return _createSuccessTransaction(
        reference: reference,
        amount: amount,
        orderId: orderId,
        email: email,
      );
    } on PaymentException {
      rethrow;
    } catch (e) {
      throw PaymentProcessingException(
        message: 'Checkout failed: $e',
        reference: null,
        originalError: e,
      );
    }
  }

  /// Get payment history (mock implementation)
  @override
  Future<List<Payment>> getPaymentHistory(String userId) async {
    try {
      // Mock data - in production, fetch from backend
      return [
        PaystackTransaction(
          id: 'pay_1',
          orderId: 'ORD-001',
          amount: 25000.0,
          currency: 'NGN',
          status: PaymentStatus.completed,
          method: PaymentMethod.card,
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          paystackReference: 'ref_123456',
          isVerified: true,
        ),
        PaystackTransaction(
          id: 'pay_2',
          orderId: 'ORD-002',
          amount: 15000.0,
          currency: 'NGN',
          status: PaymentStatus.completed,
          method: PaymentMethod.mobileMoney,
          timestamp: DateTime.now().subtract(const Duration(days: 5)),
          paystackReference: 'ref_789012',
          isVerified: true,
        ),
      ];
    } catch (e) {
      throw PaymentProcessingException(
        message: 'Failed to fetch payment history: $e',
        originalError: e,
      );
    }
  }

  /// Verify payment with Paystack
  Future<PaystackTransaction> verifyPayment(String reference) async {
    try {
      if (reference.isEmpty) {
        throw PaymentVerificationException(
          message: 'Payment reference cannot be empty',
        );
      }

      debugPrint('[Paystack Service] Verifying payment: Reference=$reference');

      // Stub: Return verified transaction
      return PaystackTransaction(
        id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
        orderId: 'ORD_$reference',
        amount: 0.0,
        currency: 'NGN',
        status: PaymentStatus.completed,
        method: PaymentMethod.card,
        timestamp: DateTime.now(),
        paystackReference: reference,
        isVerified: true,
        transactionReference: reference,
      );
    } on PaymentException {
      rethrow;
    } catch (e) {
      throw PaymentVerificationException(
        message: 'Payment verification failed: $e',
        reference: reference,
        originalError: e,
      );
    }
  }

  // ============ Helper Methods ============

  /// Generate a unique reference code
  String _generateReference() {
    return 'ref_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return emailRegex.hasMatch(email);
  }

  /// Validate Nigerian phone number
  bool _isValidPhoneNumber(String phone) {
    final phoneRegex = RegExp(_phoneRegex);
    return phoneRegex.hasMatch(phone);
  }

  /// Create a successful transaction
  PaystackTransaction _createSuccessTransaction({
    required String reference,
    required double amount,
    required String orderId,
    required String email,
  }) {
    return PaystackTransaction(
      id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
      orderId: orderId,
      amount: amount,
      currency: 'NGN',
      status: PaymentStatus.completed,
      method: PaymentMethod.card,
      timestamp: DateTime.now(),
      transactionReference: reference,
      paystackReference: reference,
      isVerified: true,
      metadata: {'email': email},
    );
  }

  /// Create a failed transaction
  PaystackTransaction _createFailedTransaction({
    required String reference,
    required double amount,
    required String orderId,
    required String errorMessage,
  }) {
    return PaystackTransaction(
      id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
      orderId: orderId,
      amount: amount,
      currency: 'NGN',
      status: PaymentStatus.failed,
      method: PaymentMethod.card,
      timestamp: DateTime.now(),
      transactionReference: reference,
      paystackReference: reference,
      isVerified: false,
      errorMessage: errorMessage,
    );
  }
}
