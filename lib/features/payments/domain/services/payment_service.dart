import '../entities/payment.dart';

abstract class PaymentService {
  Future<String> createPaymentIntent(double amount, String currency);
  Future<Payment> processPayment(String intentId, PaymentMethod method);
  Future<List<Payment>> getPaymentHistory(String userId);
}
