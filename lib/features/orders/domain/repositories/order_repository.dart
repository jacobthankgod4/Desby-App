import '../../../../core/error/failures.dart';
import '../entities/order.dart';

abstract class OrderRepository {
  Future<Result<List<OrderEntity>>> getOrders({OrderStatus? status, String? clientId});
  Future<Result<OrderEntity>> getOrderById(String id);
  Future<Result<OrderEntity>> createOrder(OrderEntity order);
  Future<Result<OrderEntity>> updateOrderStatus(String id, OrderStatus status);
  Future<Result<void>> deleteOrder(String id);
}
