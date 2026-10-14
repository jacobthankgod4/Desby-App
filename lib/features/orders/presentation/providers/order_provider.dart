import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/order_repository.dart';
import '../../domain/usecases/order_usecases.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

import '../../domain/entities/order.dart';

import '../../data/repositories/supabase_order_repository.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return SupabaseOrderRepository();
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

final ordersProvider = FutureProvider.family<List<OrderEntity>, OrderStatus?>((
  ref,
  status,
) async {
  final usecase = ref.watch(getOrdersUsecaseProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null) return [];

  // Role-based filtering. Anything that is not a tailor or a fabric seller is
  // treated as a client, because a user with an unexpected `userType` string
  // previously fell through every branch and saw the unfiltered list — or, once
  // the client filter was applied, none of their own orders.
  final role = user.userType;
  final isTailor = role == 'tailor';
  final isFabricSeller = role == 'fabric_seller';

  final result = await usecase(
    status: status,
    clientId: (!isTailor && !isFabricSeller) ? user.id : null,
    tailorId: isTailor ? user.id : null,
    fabricSellerId: isFabricSeller ? user.id : null,
  );

  return result.fold(
    (failure) => throw Exception(failure.toString()),
    (orders) => orders,
  );
});

final orderDetailProvider = FutureProvider.family<OrderEntity, String>((
  ref,
  id,
) async {
  final usecase = ref.watch(getOrderByIdUsecaseProvider);
  final result = await usecase(id);
  return result.fold(
    (failure) => throw Exception(failure.toString()),
    (order) => order,
  );
});
