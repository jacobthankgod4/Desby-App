/// Base exception for payment operations
abstract class PaymentException implements Exception {
  final String message;
  final dynamic originalError;

  PaymentException({required this.message, this.originalError});

  @override
  String toString() => 'PaymentException: $message';
}

/// Exception thrown when payment initialization fails
class PaymentInitializationException extends PaymentException {
  PaymentInitializationException({required super.message, super.originalError});

  @override
  String toString() => 'PaymentInitializationException: $message';
}

/// Exception thrown when payment processing fails
class PaymentProcessingException extends PaymentException {
  final String? reference;

  PaymentProcessingException({
    required super.message,
    this.reference,
    super.originalError,
  });

  @override
  String toString() => 'PaymentProcessingException: $message (Ref: $reference)';
}

/// Exception thrown when payment verification fails
class PaymentVerificationException extends PaymentException {
  final String? reference;

  PaymentVerificationException({
    required super.message,
    this.reference,
    super.originalError,
  });

  @override
  String toString() =>
      'PaymentVerificationException: $message (Ref: $reference)';
}

/// Exception thrown when payment amount is invalid
class InvalidPaymentAmountException extends PaymentException {
  final double? amount;

  InvalidPaymentAmountException({
    required super.message,
    this.amount,
    super.originalError,
  });

  @override
  String toString() =>
      'InvalidPaymentAmountException: $message (Amount: $amount)';
}

/// Exception thrown when currency is not supported
class UnsupportedCurrencyException extends PaymentException {
  final String? currency;

  UnsupportedCurrencyException({
    required super.message,
    this.currency,
    super.originalError,
  });

  @override
  String toString() =>
      'UnsupportedCurrencyException: $message (Currency: $currency)';
}

/// Exception thrown when Paystack is not configured
class PaystackNotConfiguredException extends PaymentException {
  PaystackNotConfiguredException({required super.message, super.originalError});

  @override
  String toString() => 'PaystackNotConfiguredException: $message';
}

/// Exception thrown when network error occurs
class PaymentNetworkException extends PaymentException {
  PaymentNetworkException({required super.message, super.originalError});

  @override
  String toString() => 'PaymentNetworkException: $message';
}

/// Exception thrown when payment is cancelled by user
class PaymentCancelledException extends PaymentException {
  PaymentCancelledException({required super.message, super.originalError});

  @override
  String toString() => 'PaymentCancelledException: $message';
}

/// Exception thrown for Paystack-specific API errors
class PaystackApiException extends PaymentException {
  final int? statusCode;
  final Map<String, dynamic>? responseBody;

  PaystackApiException({
    required super.message,
    this.statusCode,
    this.responseBody,
    super.originalError,
  });

  @override
  String toString() => 'PaystackApiException: $message (Status: $statusCode)';
}
