import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/payment.dart';
import '../../data/models/paystack_transaction.dart';

part 'payment_state.freezed.dart';

/// State for payment operations
@freezed
class PaymentState with _$PaymentState {
  const factory PaymentState.initial() = _Initial;

  /// Loading state while processing payment
  const factory PaymentState.loading(String message) = _Loading;

  /// Success state with completed payment
  const factory PaymentState.success(PaystackTransaction transaction) = _Success;

  /// Error state with exception
  const factory PaymentState.error(String message, dynamic error) = _Error;

  /// Payment cancelled by user
  const factory PaymentState.cancelled(String message) = _Cancelled;

  /// Payment initiated (checkout page opened)
  const factory PaymentState.initiated(String reference) = _Initiated;

  /// Waiting for payment verification
  const factory PaymentState.verifying(String reference) = _Verifying;
}

/// Extension methods on PaymentState
extension PaymentStateExtension on PaymentState {
  bool get isLoading => this is _Loading;

  bool get isSuccess => this is _Success;

  bool get isError => this is _Error;

  bool get isCancelled => this is _Cancelled;

  bool get isInitiated => this is _Initiated;

  bool get isVerifying => this is _Verifying;

  String? get message {
    return when(
      initial: () => null,
      loading: (msg) => msg,
      success: (_) => 'Payment successful',
      error: (msg, _) => msg,
      cancelled: (msg) => msg,
      initiated: (ref) => 'Initiating payment',
      verifying: (ref) => 'Verifying payment',
    );
  }

  dynamic get error {
    return maybeWhen(
      error: (_, err) => err,
      orElse: () => null,
    );
  }

  PaystackTransaction? get transaction {
    return maybeWhen(
      success: (txn) => txn,
      orElse: () => null,
    );
  }
}
