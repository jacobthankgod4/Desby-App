import '../../../../core/error/failures.dart';
import '../entities/order.dart';
import '../repositories/order_repository.dart';

class GetOrdersUsecase {
  final OrderRepository repository;
  GetOrdersUsecase(this.repository);
  Future<Result<List<OrderEntity>>> call({OrderStatus? status, String? clientId, String? tailorId}) =>
      repository.getOrders(status: status, clientId: clientId, tailorId: tailorId);
}

class GetOrderByIdUsecase {
  final OrderRepository repository;
  GetOrderByIdUsecase(this.repository);
  Future<Result<OrderEntity>> call(String id) => repository.getOrderById(id);
}

class CreateOrderUsecase {
  final OrderRepository repository;
  CreateOrderUsecase(this.repository);
  Future<Result<OrderEntity>> call(OrderEntity order) => repository.createOrder(order);
}

class UpdateOrderStatusUsecase {
  final OrderRepository repository;
  UpdateOrderStatusUsecase(this.repository);
  Future<Result<OrderEntity>> call(String id, OrderStatus status) =>
      repository.updateOrderStatus(id, status);
}
