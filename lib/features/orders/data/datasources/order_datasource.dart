import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/order_model.dart';
import '../../domain/entities/order.dart';

abstract class OrderRemoteDatasource {
  Future<List<OrderModel>> getOrders({OrderStatus? status, String? clientId});
  Future<OrderModel> getOrderById(String id);
  Future<OrderModel> createOrder(OrderModel order);
  Future<OrderModel> updateOrderStatus(String id, OrderStatus status);
  Future<void> deleteOrder(String id);
}

class OrderRemoteDatasourceImpl implements OrderRemoteDatasource {
  final Dio dio;
  OrderRemoteDatasourceImpl(this.dio);

  @override
  Future<List<OrderModel>> getOrders({OrderStatus? status, String? clientId}) async {
    try {
      final response = await dio.get(
        ApiEndpoints.ordersList,
        queryParameters: {
          'status': status?.name,
          'clientId': clientId,
        },
      );
      return (response.data as List)
          .map((json) => OrderModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        message: 'Failed to fetch orders',
        code: e.response?.statusCode.toString(),
        originalException: e,
      );
    }
  }

  @override
  Future<OrderModel> getOrderById(String id) async {
    try {
      final response = await dio.get(ApiEndpoints.orderDetail(id));
      return OrderModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(
        message: 'Failed to fetch order details',
        code: e.response?.statusCode.toString(),
        originalException: e,
      );
    }
  }

  @override
  Future<OrderModel> createOrder(OrderModel order) async {
    try {
      final response = await dio.post(
        ApiEndpoints.ordersCreate,
        data: order.toJson(),
      );
      return OrderModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(
        message: 'Failed to create order',
        code: e.response?.statusCode.toString(),
        originalException: e,
      );
    }
  }

  @override
  Future<OrderModel> updateOrderStatus(String id, OrderStatus status) async {
    try {
      final response = await dio.patch(
        ApiEndpoints.orderStatusUpdate(id),
        data: {'status': status.name},
      );
      return OrderModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(
        message: 'Failed to update order status',
        code: e.response?.statusCode.toString(),
        originalException: e,
      );
    }
  }

  @override
  Future<void> deleteOrder(String id) async {
    try {
      await dio.delete(ApiEndpoints.orderDelete(id));
    } on DioException catch (e) {
      throw ServerException(
        message: 'Failed to delete order',
        code: e.response?.statusCode.toString(),
        originalException: e,
      );
    }
  }
}
