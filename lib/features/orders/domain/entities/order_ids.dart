import 'package:uuid/uuid.dart';

/// Builds order identifiers.
///
/// The production `orders.id` column is `uuid`, so the old
/// `'ORD_${millisecondsSinceEpoch}'` string was rejected by Postgres
/// (`22P02 invalid input syntax for type uuid`) and every order insert in the
/// app failed. The readable handle now lives in `orders.reference`.
class OrderIds {
  OrderIds._();

  static const _uuid = Uuid();

  /// Primary key. Left to the database default (`gen_random_uuid()`) when null.
  static String? newUuid() => _uuid.v4();

  /// Human-readable, sortable, unique — what the UI shows and support reads.
  ///
  /// Millisecond timestamp keeps it chronological. The suffix must be wide
  /// enough that two orders in the same millisecond cannot collide: at 4 hex
  /// chars a 500-order burst reproduced a duplicate, and orders.reference has a
  /// UNIQUE index, so a collision fails the write with 23505. 12 chars is
  /// ~2.8e14 of space.
  static String newReference({DateTime? at}) => _withPrefix('ORD', at);

  static String _withPrefix(String prefix, DateTime? at) {
    final ts = (at ?? DateTime.now()).millisecondsSinceEpoch;
    final suffix =
        _uuid.v4().replaceAll('-', '').substring(0, 12).toUpperCase();
    return '${prefix}_$ts$suffix';
  }

  /// Fabric-marketplace orders, so support can tell pipelines apart at a glance.
  static String marketplaceReference({DateTime? at}) =>
      _withPrefix('MKT', at);

  /// Shop product purchases.
  static String purchaseReference({DateTime? at}) => _withPrefix('PUR', at);
}