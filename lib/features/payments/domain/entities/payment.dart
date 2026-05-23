import 'package:equatable/equatable.dart';

enum PaymentStatus {
  pending,
  completed,
  failed,
  refunded
}

enum PaymentMethod {
  card,
  bankTransfer,
  mobileMoney,
  cash
}

class Payment extends Equatable {
  final String id;
  final String orderId;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final PaymentMethod method;
  final DateTime timestamp;
  final String? transactionReference;

  const Payment({
    required this.id,
    required this.orderId,
    required this.amount,
    this.currency = 'USD',
    required this.status,
    required this.method,
    required this.timestamp,
    this.transactionReference,
  });

  @override
  List<Object?> get props => [id, orderId, amount, currency, status, method, timestamp, transactionReference];
}
