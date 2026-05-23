import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/order_repository.dart';
import '../../domain/usecases/order_usecases.dart';


import '../../domain/entities/order.dart';

import '../../data/repositories/firebase_order_repository.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return FirebaseOrderRepository();
});

final getOrdersUsecaseProvider = Provider((ref) {
  return GetOrdersUsecase(ref.watch(orderRepositoryProvider));
});

final getOrderByIdUsecaseProvider = Provider((ref) {
  return GetOrderByIdUsecase(ref.watch(orderRepositoryProvider));
});

final createOrderUsecaseProvider = Provider((ref) {
  return CreateOrderUsecase(ref.watch(orderRepositoryProvider));
});

final updateOrderStatusUsecaseProvider = Provider((ref) {
  return UpdateOrderStatusUsecase(ref.watch(orderRepositoryProvider));
});

final ordersProvider = FutureProvider.family<List<OrderEntity>, OrderStatus?>((ref, status) async {
  final usecase = ref.watch(getOrdersUsecaseProvider);
  final result = await usecase(status: status);
  return result.fold(
    (failure) => throw Exception(failure.toString()),
    (orders) => orders,
  );
});

final orderDetailProvider = FutureProvider.family<OrderEntity, String>((ref, id) async {
  final usecase = ref.watch(getOrderByIdUsecaseProvider);
  final result = await usecase(id);
  return result.fold(
    (failure) => throw Exception(failure.toString()),
    (order) => order,
  );
});
