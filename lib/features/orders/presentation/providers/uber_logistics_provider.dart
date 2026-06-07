import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import '../../domain/repositories/uber_auth_repository.dart';
import '../../data/repositories/uber_auth_repository_impl.dart';
import '../../domain/repositories/uber_logistics_repository.dart';
import '../../data/repositories/uber_logistics_repository_impl.dart';
import '../widgets/dispatch_logistics_module.dart';

final uberAuthRepositoryProvider = Provider<UberAuthRepository>((ref) {
  return UberAuthRepositoryImpl(
    dio: Dio(),
    clientId: 'YOUR_UBER_CLIENT_ID', // TODO: Inject from environment
    clientSecret: 'YOUR_UBER_CLIENT_SECRET',
  );
});

final uberLogisticsRepositoryProvider = Provider<UberLogisticsRepository>((ref) {
  return UberLogisticsRepositoryImpl(
    authRepository: ref.watch(uberAuthRepositoryProvider),
    customerId: 'YOUR_UBER_ORG_ID', // TODO: Inject from environment
    firestore: FirebaseFirestore.instance,
  );
});

class UberLogisticsState {
  final bool isLoading;
  final String? error;
  final UberDeliveryStatus? currentStatus;

  UberLogisticsState({
    this.isLoading = false,
    this.error,
    this.currentStatus,
  });

  UberLogisticsState copyWith({
    bool? isLoading,
    String? error,
    UberDeliveryStatus? currentStatus,
  }) {
    return UberLogisticsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentStatus: currentStatus ?? this.currentStatus,
    );
  }
}

class UberLogisticsNotifier extends StateNotifier<UberLogisticsState> {
  final UberLogisticsRepository _repository;

  UberLogisticsNotifier(this._repository) : super(UberLogisticsState());

  Future<void> fetchStatus(String deliveryId) async {
    state = state.copyWith(isLoading: true);
    final result = await _repository.getStatus(deliveryId);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
      (status) => state = state.copyWith(isLoading: false, currentStatus: status),
    );
  }
}

final uberLogisticsProvider = StateNotifierProvider<UberLogisticsNotifier, UberLogisticsState>((ref) {
  return UberLogisticsNotifier(ref.watch(uberLogisticsRepositoryProvider));
});
