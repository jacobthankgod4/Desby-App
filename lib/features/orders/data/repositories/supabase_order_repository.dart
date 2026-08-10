import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../models/order_model.dart';

class SupabaseOrderRepository implements OrderRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<Result<List<OrderEntity>>> getOrders({OrderStatus? status, String? clientId, String? tailorId}) async {
    try {
      var query = _supabase.from('orders').select();
      if (status != null) {
        query = query.eq('status', status.name);
      }
      if (clientId != null) {
        query = query.eq('client_id', clientId);
      }
      if (tailorId != null) {
        query = query.eq('tailor_id', tailorId);
      }
      final response = await query;
      return Success((response as List)
          .map((data) => OrderModel.fromJson(data).toEntity())
          .toList());
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteOrder(String id) async {
    try {
      await _supabase.from('orders').delete().eq('id', id);
      return const Success(null);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<OrderEntity>> getOrderById(String id) async {
    try {
      final response = await _supabase.from('orders').select().eq('id', id).maybeSingle();
      if (response == null) return const Failure(AuthFailure(message: 'Order not found'));
      return Success(OrderModel.fromJson(response).toEntity());
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<OrderEntity>> createOrder(OrderEntity order) async {
    try {
      final model = OrderModel.fromEntity(order);
      await _supabase.from('orders').upsert(model.toJson(), onConflict: 'id');
      return Success(order);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<OrderEntity>> updateOrderStatus(String id, OrderStatus status) async {
    try {
      await _supabase.from('orders').update({'status': status.name}).eq('id', id);
      return getOrderById(id);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }
}
