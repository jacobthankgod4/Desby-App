import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../models/order_model.dart';

class FirebaseOrderRepository implements OrderRepository {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;


  @override
  Future<Result<List<OrderEntity>>> getOrders({OrderStatus? status, String? clientId}) async {
    try {
      Query query = _firestore.collection('orders');
      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }
      if (clientId != null) {
        query = query.where('clientId', isEqualTo: clientId);
      }
      final snapshot = await query.get();
      return Success(snapshot.docs
          .map((doc) => OrderModel.fromJson(doc.data() as Map<String, dynamic>).toEntity())
          .toList());
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteOrder(String id) async {
    try {
      await _firestore.collection('orders').doc(id).delete();
      return const Success(null);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<OrderEntity>> getOrderById(String id) async {
    try {
      final doc = await _firestore.collection('orders').doc(id).get();
      if (!doc.exists) return const Failure(AuthFailure(message: 'Order not found'));
      return Success(OrderModel.fromJson(doc.data() as Map<String, dynamic>).toEntity());
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<OrderEntity>> createOrder(OrderEntity order) async {
    try {
      final model = OrderModel(
        id: order.id,
        clientId: order.clientId,
        clientName: order.clientName,
        items: order.items.map((i) => OrderItemModel.fromEntity(i)).toList(),
        status: order.status,
        totalAmount: order.totalAmount,
        dueDate: order.dueDate,
        createdAt: order.createdAt,
      );
      await _firestore.collection('orders').doc(model.id).set(model.toJson());
      return Success(order);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<OrderEntity>> updateOrderStatus(String id, OrderStatus status) async {
    try {
      await _firestore.collection('orders').doc(id).update({'status': status.name});
      return getOrderById(id);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }
}
