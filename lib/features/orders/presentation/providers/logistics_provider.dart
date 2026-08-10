import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/logistics_repository.dart';
import '../../data/repositories/fez_logistics_repository_impl.dart';

final logisticsRepositoryProvider = Provider<LogisticsRepository>((ref) {
  return FezLogisticsRepositoryImpl();
});

// Mock state for now since the original file was missing
class LogisticsState {
  final bool isLoading;
  final String? error;
  final dynamic data;

  const LogisticsState({this.isLoading = false, this.error, this.data});
  
  const LogisticsState.initial() : this();
  const LogisticsState.loading() : this(isLoading: true);
  const LogisticsState.loaded(dynamic data) : this(data: data);
  const LogisticsState.error(String error) : this(error: error);
}

final logisticsProvider = StateNotifierProvider<LogisticsNotifier, LogisticsState>((ref) {
  return LogisticsNotifier();
});

final trackDeliveryProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, orderNo) async {
  final repo = ref.watch(logisticsRepositoryProvider);
  final result = await repo.trackDelivery(orderNo);
  return result.fold(
    (failure) => {
      'order': {'orderNo': orderNo, 'orderStatus': 'ERROR'},
      'history': []
    },
    (data) => {
      'order': {'orderNo': orderNo, 'orderStatus': data['status']},
      'history': [
        {'orderStatus': data['status'], 'statusDescription': 'Package status updated.', 'statusCreationDate': DateTime.now().toString()}
      ]
    },
  );
});

class LogisticsNotifier extends StateNotifier<LogisticsState> {
  LogisticsNotifier() : super(const LogisticsState.initial());

  Future<void> trackOrder(String fezOrderNo) async {
    state = const LogisticsState.loading();
    // Simulation
    await Future.delayed(const Duration(seconds: 1));
    state = const LogisticsState.error('Tracking not yet implemented');
  }
}
