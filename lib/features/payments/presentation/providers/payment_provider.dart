import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/payment_service.dart';
import '../../data/repositories/payment_service_impl.dart';
import '../../domain/entities/payment.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentServiceImpl();
});

final paymentHistoryProvider = FutureProvider<List<Payment>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  
  final service = ref.watch(paymentServiceProvider);
  return await service.getPaymentHistory(user.id);
});
