import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/logistics_repository.dart';
import '../../data/repositories/fez_logistics_repository_impl.dart';
import '../../data/repositories/terminal_shipping_repository_impl.dart';

/// Logistics provider — swapped to Terminal Shipping.
///
/// Terminal is a multi-carrier aggregator (42 carriers including GIG, DHL,
/// Fez and Sendstack) reached with one integration, replacing the Fez
/// single-courier dependency whose credentials were never issued.
/// Swap [TerminalShippingRepositoryImpl] for [FezLogisticsRepositoryImpl] here
/// to roll back; nothing else references Fez.
final logisticsRepositoryProvider = Provider<LogisticsRepository>((ref) {
  return TerminalShippingRepositoryImpl();
});

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

final logisticsProvider =
    StateNotifierProvider<LogisticsNotifier, LogisticsState>((ref) {
      return LogisticsNotifier(ref.watch(logisticsRepositoryProvider));
    });

final trackDeliveryProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, orderNo) async {
      final repo = ref.watch(logisticsRepositoryProvider);
      final result = await repo.trackDelivery(orderNo);
      return result.fold((failure) => throw Exception(failure.message), (data) {
        final rawOrder = data['order'];
        final order = rawOrder is Map
            ? Map<String, dynamic>.from(rawOrder)
            : <String, dynamic>{};
        final rawNestedData = data['data'];
        final nestedData = rawNestedData is Map
            ? Map<String, dynamic>.from(rawNestedData)
            : <String, dynamic>{};
        final status =
            data['status'] ??
            data['orderStatus'] ??
            order['orderStatus'] ??
            nestedData['orderStatus'] ??
            nestedData['status'];
        final history =
            data['history'] ?? nestedData['history'] ?? nestedData['timeline'];

        return <String, dynamic>{
          ...data,
          'status': status,
          'orderStatus': status,
          'order': <String, dynamic>{
            ...order,
            'orderNo': order['orderNo'] ?? data['orderNo'] ?? orderNo,
            'orderStatus': status,
          },
          'history': history ?? const <dynamic>[],
        };
      });
    });

class LogisticsNotifier extends StateNotifier<LogisticsState> {
  final LogisticsRepository _repository;

  LogisticsNotifier(this._repository) : super(const LogisticsState.initial());

  Future<void> trackOrder(String shipmentId) async {
    state = const LogisticsState.loading();
    try {
      final result = await _repository.trackDelivery(shipmentId);
      result.fold(
        (failure) => state = LogisticsState.error(failure.message),
        (data) => state = LogisticsState.loaded(data),
      );
    } catch (error) {
      state = LogisticsState.error(error.toString());
    }
  }
}
