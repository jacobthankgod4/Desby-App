import 'package:supabase_flutter/supabase_flutter.dart' as sb;
// SupabaseClient is used unqualified below, so keep the direct import too.
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_ids.dart';
import '../../domain/repositories/order_repository.dart';
import '../models/order_model.dart';

class SupabaseOrderRepository implements OrderRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<Result<List<OrderEntity>>> getOrders({
    OrderStatus? status,
    String? clientId,
    String? tailorId,
    String? fabricSellerId,
  }) async {
    try {
      var query = _supabase.from('orders').select();
      if (status != null) {
        query = query.eq('status', status.name);
      }
      if (clientId != null) {
        // Match on requesting_user_id as well as client_id. "My requests" is
        // attributed by requesting_user_id, and the guided journey writes rows
        // with client_id null — filtering on client_id alone hid them, so a
        // freshly submitted request showed an empty Orders list. client_id is
        // still matched for rows that only have it.
        query = query.or(
          'requesting_user_id.eq.$clientId,client_id.eq.$clientId',
        );
      }
      if (tailorId != null) {
        query = query.eq('tailor_id', tailorId);
      }
      if (fabricSellerId != null) {
        query = query.eq('fabric_seller_id', fabricSellerId);
      }
      final response = await query;
      return Success(
        (response as List)
            .map((data) => OrderModel.fromJson(data).toEntity())
            .toList(),
      );
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
      final response = await _supabase
          .from('orders')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null)
        return const Failure(AuthFailure(message: 'Order not found'));
      return Success(OrderModel.fromJson(response).toEntity());
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<OrderEntity>> createOrder(OrderEntity order) async {
    // The uuid PK and the human reference are generated here rather than at the
    // call site: six call sites previously invented `ORD_…`/`MKT_…`/`PUR_…`
    // strings, none of which the uuid column accepts.
    final id = (order.id.isEmpty || _looksNonUuid(order.id))
        ? OrderIds.newUuid()!
        : order.id;
    final reference = order.reference ?? OrderIds.newReference();

    final payload = OrderModel.fromEntity(
      order.copyWith(id: id, reference: reference),
    ).toJson();
    // Drop nulls so we never send an explicit null for a column with a
    // database default (payment_status defaults to 'unpaid', paid_at is
    // set by the payment step). An explicit null would clear the default.
    payload.removeWhere((_, v) => v == null);

    // Transient network failures (e.g. net::ERR_CONNECTION_CLOSED) can strike
    // before or after the insert commits. id and reference are fixed before
    // the first attempt, so retries are idempotent: a 23505 on either key —
    // or a row found by id — means an earlier attempt already committed and
    // we return that row instead of inserting again.
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
        final committed = await _findCommittedOrder(id, reference);
        if (committed != null) return Success(committed);
      }
      try {
        // insert + returning, not upsert: a retry must never silently
        // overwrite an existing order, and a successful UI transition must
        // correspond to a row we actually read back.
        final response = await _supabase
            .from('orders')
            .insert(payload)
            .select()
            .single();

        return Success(OrderModel.fromJson(response).toEntity());
      } on sb.PostgrestException catch (e) {
        // Unique violation — either this exact row committed on an earlier
        // attempt (return it) or the conflict is elsewhere. PostgREST also
        // reports some conflicts as a bare 409 with no Postgres code in the
        // body (seen live: POST /rest/v1/orders?select=* → 409 Conflict):
        // same treatment. When the read-back finds nothing, keep retrying —
        // the lookup itself can hit the same flaky network that broke the
        // insert, and the next loop iteration re-checks before writing.
        if (e.code == '23505' || e.code == '409') {
          final committed = await _findCommittedOrder(id, reference);
          if (committed != null) return Success(committed);
          lastError = e;
          continue;
        }
        // Not transient (RLS, constraint, bad payload) — surface the real
        // Postgres reason rather than retrying a doomed write.
        return Failure(
          AuthFailure(
            message: 'Order could not be saved (${e.code}): ${e.message}',
          ),
        );
      } catch (e) {
        // Network/socket-level failure — retry.
        lastError = e;
      }
    }
    return Failure(
      AuthFailure(
        message:
            'Order could not be saved after 3 attempts: $lastError',
      ),
    );
  }

  /// Reads back a row that an earlier attempt may have committed.
  /// Returns null when neither key matches (or the lookup itself fails).
  Future<OrderEntity?> _findCommittedOrder(String id, String reference) async {
    try {
      final byId = await _supabase
          .from('orders')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (byId != null) return OrderModel.fromJson(byId).toEntity();
      final byRef = await _supabase
          .from('orders')
          .select()
          .eq('reference', reference)
          .maybeSingle();
      if (byRef != null) return OrderModel.fromJson(byRef).toEntity();
    } catch (_) {
      // Lookup failed (likely the same flaky network) — let the caller retry.
    }
    return null;
  }

  /// Postgres uuid columns reject prefixed ids; detect before we hit the wire.
  static bool _looksNonUuid(String value) =>
      !RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
        r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      ).hasMatch(value);

  @override
  Future<Result<OrderEntity>> updateOrderStatus(
    String id,
    OrderStatus status,
  ) async {
    try {
      final response = await _supabase
          .from('orders')
          .update({'status': status.name})
          .eq('id', id)
          .select('id');
      // An update that matched no row is not a success.
      if ((response as List).isEmpty) {
        return const Failure(AuthFailure(message: 'Order not found'));
      }
      return getOrderById(id);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }
}
