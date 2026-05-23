import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/providers/app_providers.dart';
import 'paystack_service.dart';

final paystackServiceProvider = Provider<PaystackService>((ref) {
  final dio = ref.watch(dioProvider);
  return PaystackService(dio);
});
