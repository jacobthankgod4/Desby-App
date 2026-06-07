/// Base exception for payment operations
abstract class PaymentException implements Exception {
  final String message;
  final dynamic originalError;

  PaymentException({
    required this.message,
    this.originalError,
  });

  @override
  String toString() => 'PaymentException: $message';
}

/// Exception thrown when payment initialization fails
class PaymentInitializationException extends PaymentException {
  PaymentInitializationException({
    required String message,
    dynamic originalError,
  }) : super(
    message: message,
    originalError: originalError,
  );

  @override
  String toString() => 'PaymentInitializationException: $message';
}

/// Exception thrown when payment processing fails
class PaymentProcessingException extends PaymentException {
  final String? reference;

  PaymentProcessingException({
    required String message,
    this.reference,
    dynamic originalError,
  }) : super(
    message: message,
    originalError: originalError,
  );

  @override
  String toString() => 'PaymentProcessingException: $message (Ref: $reference)';
}

/// Exception thrown when payment verification fails
class PaymentVerificationException extends PaymentException {
  final String? reference;

  PaymentVerificationException({
    required String message,
    this.reference,
    dynamic originalError,
  }) : super(
    message: message,
    originalError: originalError,
  );

  @override
  String toString() => 'PaymentVerificationException: $message (Ref: $reference)';
}

/// Exception thrown when payment amount is invalid
class InvalidPaymentAmountException extends PaymentException {
  final double? amount;

  InvalidPaymentAmountException({
    required String message,
    this.amount,
    dynamic originalError,
  }) : super(
    message: message,
    originalError: originalError,
  );

  @override
  String toString() => 'InvalidPaymentAmountException: $message (Amount: $amount)';
}

/// Exception thrown when currency is not supported
class UnsupportedCurrencyException extends PaymentException {
  final String? currency;

  UnsupportedCurrencyException({
    required String message,
    this.currency,
    dynamic originalError,
  }) : super(
    message: message,
    originalError: originalError,
  );

  @override
  String toString() => 'UnsupportedCurrencyException: $message (Currency: $currency)';
}

/// Exception thrown when Paystack is not configured
class PaystackNotConfiguredException extends PaymentException {
  PaystackNotConfiguredException({
    required String message,
    dynamic originalError,
  }) : super(
    message: message,
    originalError: originalError,
  );

  @override
  String toString() => 'PaystackNotConfiguredException: $message';
}

/// Exception thrown when network error occurs
class PaymentNetworkException extends PaymentException {
  PaymentNetworkException({
    required String message,
    dynamic originalError,
  }) : super(
    message: message,
    originalError: originalError,
  );

  @override
  String toString() => 'PaymentNetworkException: $message';
}

/// Exception thrown when payment is cancelled by user
class PaymentCancelledException extends PaymentException {
  PaymentCancelledException({
    required String message,
    dynamic originalError,
  }) : super(
    message: message,
    originalError: originalError,
  );

  @override
  String toString() => 'PaymentCancelledException: $message';
}

/// Exception thrown for Paystack-specific API errors
class PaystackApiException extends PaymentException {
  final int? statusCode;
  final Map<String, dynamic>? responseBody;

  PaystackApiException({
    required String message,
    this.statusCode,
    this.responseBody,
    dynamic originalError,
  }) : super(
    message: message,
    originalError: originalError,
  );

  @override
  String toString() =>
      'PaystackApiException: $message (Status: $statusCode)';
}
