import '../entities/payment.dart';

/// Paystack-specific transaction model extending the base Payment entity
class PaystackTransaction extends Payment {
  /// Paystack access code for the transaction
  final String? accessCode;

  /// Authorization URL for completing payment
  final String? authorizationUrl;

  /// Paystack authorization object
  final PaystackAuthorization? authorization;

  /// Reference code from Paystack
  final String? paystackReference;

  /// Additional Paystack metadata
  final Map<String, dynamic>? metadata;

  /// Whether the payment was verified with Paystack
  final bool isVerified;

  /// Error message if transaction failed
  final String? errorMessage;

  const PaystackTransaction({
    required String id,
    required String orderId,
    required double amount,
    String currency = 'NGN',
    required PaymentStatus status,
    required PaymentMethod method,
    required DateTime timestamp,
    String? transactionReference,
    this.accessCode,
    this.authorizationUrl,
    this.authorization,
    this.paystackReference,
    this.metadata,
    this.isVerified = false,
    this.errorMessage,
  }) : super(
    id: id,
    orderId: orderId,
    amount: amount,
    currency: currency,
    status: status,
    method: method,
    timestamp: timestamp,
    transactionReference: transactionReference,
  );

  /// Create a PaystackTransaction from Payment
  factory PaystackTransaction.fromPayment(Payment payment) {
    return PaystackTransaction(
      id: payment.id,
      orderId: payment.orderId,
      amount: payment.amount,
      currency: payment.currency,
      status: payment.status,
      method: payment.method,
      timestamp: payment.timestamp,
      transactionReference: payment.transactionReference,
    );
  }

  /// Create a copy with modifications
  PaystackTransaction copyWith({
    String? id,
    String? orderId,
    double? amount,
    String? currency,
    PaymentStatus? status,
    PaymentMethod? method,
    DateTime? timestamp,
    String? transactionReference,
    String? accessCode,
    String? authorizationUrl,
    PaystackAuthorization? authorization,
    String? paystackReference,
    Map<String, dynamic>? metadata,
    bool? isVerified,
    String? errorMessage,
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
      accessCode: accessCode ?? this.accessCode,
      authorizationUrl: authorizationUrl ?? this.authorizationUrl,
      authorization: authorization ?? this.authorization,
      paystackReference: paystackReference ?? this.paystackReference,
      metadata: metadata ?? this.metadata,
      isVerified: isVerified ?? this.isVerified,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'amount': amount,
      'currency': currency,
      'status': status.toString(),
      'method': method.toString(),
      'timestamp': timestamp.toIso8601String(),
      'transactionReference': transactionReference,
      'accessCode': accessCode,
      'paystackReference': paystackReference,
      'metadata': metadata,
      'isVerified': isVerified,
      'errorMessage': errorMessage,
    };
  }

  /// Create from JSON
  factory PaystackTransaction.fromJson(Map<String, dynamic> json) {
    return PaystackTransaction(
      id: json['id'] as String,
      orderId: json['orderId'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'NGN',
      status: PaymentStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
      method: PaymentMethod.values.firstWhere(
        (e) => e.toString() == json['method'],
        orElse: () => PaymentMethod.card,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      transactionReference: json['transactionReference'] as String?,
      accessCode: json['accessCode'] as String?,
      paystackReference: json['paystackReference'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      isVerified: json['isVerified'] as bool? ?? false,
      errorMessage: json['errorMessage'] as String?,
    );
  }
}

/// Paystack Authorization Object
class PaystackAuthorization {
  final String? authorizationUrl;
  final String? accessCode;
  final String? reference;

  PaystackAuthorization({
    this.authorizationUrl,
    this.accessCode,
    this.reference,
  });

  factory PaystackAuthorization.fromJson(Map<String, dynamic> json) {
    return PaystackAuthorization(
      authorizationUrl: json['authorization_url'] as String?,
      accessCode: json['access_code'] as String?,
      reference: json['reference'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'authorization_url': authorizationUrl,
    'access_code': accessCode,
    'reference': reference,
  };
}
