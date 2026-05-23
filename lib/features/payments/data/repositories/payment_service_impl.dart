import '../../domain/entities/payment.dart';
import '../../domain/services/payment_service.dart';

class PaymentServiceImpl implements PaymentService {
  @override
  Future<String> createPaymentIntent(double amount, String currency) async {
    return 'pi_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<Payment> processPayment(String intentId, PaymentMethod method) async {
    return Payment(
      id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
      orderId: 'ORD-7729',
      amount: 150.0,
      status: PaymentStatus.completed,
      method: method,
      timestamp: DateTime.now(),
      transactionReference: 'REF-${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  @override
  Future<List<Payment>> getPaymentHistory(String userId) async {
    return [
      Payment(
        id: 'pay_1',
        orderId: 'ORD-001',
        amount: 250.0,
        status: PaymentStatus.completed,
        method: PaymentMethod.card,
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Payment(
        id: 'pay_2',
        orderId: 'ORD-002',
        amount: 120.0,
        status: PaymentStatus.completed,
        method: PaymentMethod.mobileMoney,
        timestamp: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
  }
}
