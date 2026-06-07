import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/order.dart';
import 'uber_logistics_provider.dart';
import 'logistics_provider.dart';
import '../widgets/dispatch_logistics_module.dart';

final smartDispatchProvider = StateNotifierProvider<SmartDispatchNotifier, AsyncValue<String>>((ref) {
  return SmartDispatchNotifier(ref);
});

class SmartDispatchNotifier extends StateNotifier<AsyncValue<String>> {
  final Ref _ref;

  SmartDispatchNotifier(this._ref) : super(const AsyncValue.data(''));

  Future<void> dispatchRider(OrderEntity order) async {
    state = const AsyncValue.loading();
    
    try {
      // 1. Determine Geography
      final address = order.deliveryAddress?.toLowerCase() ?? '';
      final isLagos = address.contains('lagos');
      
      if (isLagos) {
        // TRIGGER UBER DISPATCH (Mocking for now as we await scope activation)
        // In reality, this would call uberLogisticsRepository.createDelivery
        await Future.delayed(const Duration(seconds: 2));
        state = const AsyncValue.data('UBER_DISPATCH_INITIATED');
      } else {
        // TRIGGER FEZ DISPATCH
        final repo = _ref.read(logisticsRepositoryProvider);
        final result = await repo.summonRider(order);
        
        result.fold(
          (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
          (waybill) => state = AsyncValue.data('FEZ_WAYBILL: $waybill'),
        );
      }
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }
}
