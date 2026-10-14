import 'package:desby_app/features/orders/domain/entities/order.dart';
import 'package:desby_app/features/orders/domain/entities/order_ids.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression cover for the bug that made every order in the app fail.
///
/// Verified against production 2026-10-05:
///   orders.id is `uuid`          -> 'ORD_1757000000000' rejected (22P02)
///   orders.client_id -> clients  -> user.id rejected (23503)
/// `orders` held 0 rows because of it.
void main() {
  group('OrderIds', () {
    test('newUuid is a real uuid — the orders PK is a uuid column', () {
      final uuid = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
        r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      );
      for (var i = 0; i < 50; i++) {
        expect(uuid.hasMatch(OrderIds.newUuid()!), isTrue,
            reason: 'OrderIds.newUuid must satisfy the uuid PK');
      }
    });

    test('uuid values are distinct', () {
      final ids = List.generate(500, (_) => OrderIds.newUuid());
      expect(ids.toSet().length, 500);
    });

    test('references are prefixed, unique and non-empty', () {
      final refs = List.generate(2000, (_) => OrderIds.newReference());
      expect(refs.toSet().length, 2000, reason: 'reference has a UNIQUE index');
      expect(refs.every((r) => r.startsWith('ORD_')), isTrue);
      expect(OrderIds.marketplaceReference().startsWith('MKT_'), isTrue);
      expect(OrderIds.purchaseReference().startsWith('PUR_'), isTrue);
    });

    test('reference carries no uuid-unsafe surprises and stays short', () {
      final ref = OrderIds.newReference();
      expect(ref.length, lessThan(40));
      expect(ref, matches(RegExp(r'^ORD_\d+[0-9A-F]{12}$')));
    });

    test('a same-millisecond burst cannot collide', () {
      // orders.reference is UNIQUE, so a duplicate fails the insert with 23505.
      // A 4-char suffix reproduced this at 500 orders; the width must hold.
      final at = DateTime.utc(2026, 10, 5, 12);
      final refs = List.generate(2000, (_) => OrderIds.newReference(at: at));
      expect(refs.toSet().length, 2000,
          reason: 'same-millisecond references must still be unique');
    });

    test('references sort chronologically', () {
      final early = OrderIds.newReference(
        at: DateTime.utc(2026, 1, 1),
      );
      final late = OrderIds.newReference(
        at: DateTime.utc(2026, 6, 1),
      );
      expect(early.compareTo(late), lessThan(0));
    });
  });

  group('OrderEntity identity fields', () {
    OrderEntity build({
      String id = '11111111-2222-3333-4444-555555555555',
      String? reference = 'ORD_1757000000000ABCD',
      String? requestingUserId = 'user-1',
      String? clientId,
      String? tailorId = 'tailor-1',
      DateTime? dueDate,
    }) {
      return OrderEntity(
        id: id,
        reference: reference,
        requestingUserId: requestingUserId,
        clientId: clientId,
        tailorId: tailorId,
        clientName: 'Kelechi',
        items: const [
          OrderItem(id: 'item_1', garmentType: 'Suit', price: 45000),
        ],
        status: OrderStatus.pending,
        totalAmount: 45000,
        dispatchFee: 4900,
        dueDate: dueDate,
        createdAt: DateTime.utc(2026, 10, 5),
      );
    }

    test('requestingUserId and clientId are independent', () {
      // The whole point of the migration: a browsing client has a users row but
      // no clients row, so the two must not be the same field.
      final order = build(clientId: null);
      expect(order.requestingUserId, 'user-1');
      expect(order.clientId, isNull);
    });

    test('clientId can be set later without losing the requester', () {
      final order = build().copyWith(clientId: 'client-9');
      expect(order.clientId, 'client-9');
      expect(order.requestingUserId, 'user-1');
    });

    test('copyWith can clear the nullable fields', () {
      final order = build(clientId: 'c', dueDate: DateTime.utc(2026, 11, 1));
      final cleared = order.copyWith(clearClientId: true, clearDueDate: true);
      expect(cleared.clientId, isNull);
      expect(cleared.dueDate, isNull);
    });

    test('dueDate is nullable — the tailor confirms the timeline', () {
      expect(build().dueDate, isNull);
      expect(build(dueDate: DateTime.utc(2026, 11, 1)).dueDate, isNotNull);
    });

    test('displayReference falls back to the id for legacy rows', () {
      expect(build(reference: 'ORD_1').displayReference, 'ORD_1');
      expect(build(reference: null).displayReference,
          '11111111-2222-3333-4444-555555555555');
      expect(build(reference: '').displayReference,
          '11111111-2222-3333-4444-555555555555');
    });

    test('equatable props include the new identity fields', () {
      expect(build(), isNot(equals(build(reference: 'ORD_DIFFERENT'))));
      expect(build(), isNot(equals(build(requestingUserId: 'other'))));
    });

    test('a tailor-less marketplace order is representable', () {
      final order = build(tailorId: null);
      expect(order.tailorId, isNull);
      expect(order.requestingUserId, isNotNull);
    });
  });

  group('OrderStatus', () {
    test('every status value is one the DB CHECK accepts', () {
      // orders_status_known is enforced by Postgres; a new enum member that the
      // constraint rejects would strand orders at the write.
      const allowed = {
        'pending',
        'paid',
        'bookingAccepted',
        'booking_accepted',
        'materialsInTransit',
        'materials_in_transit',
        'inProgress',
        'in_progress',
        'ready',
        'confirmed',
        'delivered',
        'completed',
        'cancelled',
      };
      for (final status in OrderStatus.values) {
        expect(allowed, contains(status.name),
            reason: '${status.name} is not accepted by orders_status_known');
      }
    });

    test('every status has a human label', () {
      for (final status in OrderStatus.values) {
        expect(status.displayName, isNotEmpty);
      }
    });
  });
}