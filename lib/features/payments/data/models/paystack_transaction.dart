import 'package:equatable/equatable.dart';
import '../../domain/entities/payment.dart';

/// Paystack-specific transaction model
/// Extends the base Payment with Paystack-specific fields
class PaystackTransaction extends Payment {
  final String? paystackReference;
  final bool isVerified;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  const PaystackTransaction({
    required super.id,
    required super.orderId,
    required super.amount,
    super.currency = 'NGN',
    required super.status,
    required super.method,
    required super.timestamp,
    super.transactionReference,
    this.paystackReference,
    this.isVerified = false,
    this.errorMessage,
    this.metadata,
  });

  /// Create from Paystack API response
  factory PaystackTransaction.fromPaystackResponse({
    required String id,
    required String orderId,
    required double amount,
    required String currency,
    required PaymentStatus status,
    required PaymentMethod method,
    required DateTime timestamp,
    required String transactionReference,
    required String paystackReference,
    bool isVerified = false,
    Map<String, dynamic>? metadata,
  }) {
    return PaystackTransaction(
      id: id,
      orderId: orderId,
      amount: amount,
      currency: currency,
      status: status,
      method: method,
      timestamp: timestamp,
      transactionReference: transactionReference,
      paystackReference: paystackReference,
      isVerified: isVerified,
      metadata: metadata,
    );
  }

  /// Create a success transaction
  factory PaystackTransaction.success({
    required String id,
    required String orderId,
    required double amount,
    required String transactionReference,
    required String paystackReference,
    PaymentMethod method = PaymentMethod.card,
    Map<String, dynamic>? metadata,
  }) {
    return PaystackTransaction(
      id: id,
      orderId: orderId,
      amount: amount,
      status: PaymentStatus.completed,
      method: method,
      timestamp: DateTime.now(),
      transactionReference: transactionReference,
      paystackReference: paystackReference,
      isVerified: true,
      metadata: metadata,
    );
  }

  /// Create a failed transaction
  factory PaystackTransaction.failed({
    required String id,
    required String orderId,
    required double amount,
    required String transactionReference,
    required String paystackReference,
    required String errorMessage,
  }) {
    return PaystackTransaction(
      id: id,
      orderId: orderId,
      amount: amount,
      status: PaymentStatus.failed,
      method: PaymentMethod.card,
      timestamp: DateTime.now(),
      transactionReference: transactionReference,
      paystackReference: paystackReference,
      isVerified: false,
      errorMessage: errorMessage,
    );
  }

  /// Copy with new values
  PaystackTransaction copyWith({
    String? id,
    String? orderId,
    double? amount,
    String? currency,
    PaymentStatus? status,
    PaymentMethod? method,
    DateTime? timestamp,
    String? transactionReference,
    String? paystackReference,
    bool? isVerified,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) {
    return PaystackTransaction(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      method: method ?? this.method,
      timestamp: timestamp ?? this.timestamp,
      transactionReference: transactionReference ?? this.transactionReference,
      paystackReference: paystackReference ?? this.paystackReference,
      isVerified: isVerified ?? this.isVerified,
      errorMessage: errorMessage ?? this.errorMessage,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        ...super.props,
        paystackReference,
        isVerified,
        errorMessage,
        metadata,
      ];
}
