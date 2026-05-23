import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/fez_provider.dart';
import '../../data/repositories/fez_logistics_repository_impl.dart';
import '../../domain/repositories/logistics_repository.dart';

final logisticsRepositoryProvider = Provider<LogisticsRepository>((ref) {
  final fezService = ref.watch(fezLogisticsServiceProvider);
  final firestore = FirebaseFirestore.instance;
  return FezLogisticsRepositoryImpl(fezService, firestore);
});

final summonRiderProvider = FutureProvider.family<String, dynamic>((ref, order) async {
  final repo = ref.read(logisticsRepositoryProvider);
  final result = await repo.summonRider(order);
  return result.fold(
    (failure) => throw failure.message,
    (fezOrderNo) => fezOrderNo,
  );
});

final trackDeliveryProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, fezOrderNo) async {
  final repo = ref.read(logisticsRepositoryProvider);
  final result = await repo.trackDelivery(fezOrderNo);
  return result.fold(
    (failure) => throw failure.message,
    (data) => data,
  );
});

final deliveryCostProvider = FutureProvider.family<double, String>((ref, state) async {
  final repo = ref.read(logisticsRepositoryProvider);
  final result = await repo.estimateCost(state);
  return result.fold(
    (failure) => throw failure.message,
    (cost) => cost,
  );
});
