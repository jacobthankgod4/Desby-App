import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/payment_service.dart';
import '../../data/repositories/payment_service_impl.dart';

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentServiceImpl();
});
