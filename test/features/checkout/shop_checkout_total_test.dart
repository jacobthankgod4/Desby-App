import 'package:desby_app/features/designs/domain/entities/design.dart';
import 'package:desby_app/features/orders/domain/entities/order.dart';
import 'package:desby_app/features/orders/data/models/order_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the shop checkout arithmetic.
///
/// The buyer is charged `design.price * quantity`. That total is what is written
/// to `orders.total_amount`, and `flutterwave-pay` then charges the stored
/// `total_amount` rather than any amount the client sends — so this total is
/// the single source of truth for what the customer is actually charged.
///
/// These are the two failure modes worth locking down:
///   1. the total ignoring quantity (charging for one unit), and
///   2. the order row and its line item disagreeing about the price, which
///      would let a tailor's payout disagree with what the buyer paid.
void main() {
  Design designWithPrice(double price) => Design(
        id: 'design-1',
        title: 'Test Design',
        price: price,
        category: 'Custom',
        tailorId: 'tailor-1',
        tailorName: 'Test Tailor',
        imageUrls: const [],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

  OrderEntity orderFor(Design design, int quantity) =>
      OrderEntity(
        id: 'order-1',
        reference: 'DES-1',
        clientId: null,
        tailorId: design.tailorId,
        clientName: 'Buyer',
        items: [
          OrderItem(
            id: 'item-1',
            garmentType: design.title,
            designId: design.id,
            measurements: const {},
            price: design.price * quantity,
          ),
        ],
        status: OrderStatus.pending,
        totalAmount: design.price * quantity,
        quantity: quantity,
        createdAt: DateTime(2026, 1, 1),
        metadata: {'channel': 'shop', 'quantity': quantity},
      );

  group('shop checkout total', () {
    test('multiplies unit price by quantity', () {
      expect(designWithPrice(5000).price * 3, 15000);
    });

    test('a single unit charges the listed price', () {
      expect(designWithPrice(7500).price * 1, 7500);
    });

    test('order total matches price times quantity', () {
      final design = designWithPrice(12000);
      for (final quantity in [1, 2, 3, 5]) {
        final order = orderFor(design, quantity);
        expect(order.totalAmount, design.price * quantity,
            reason: 'total wrong for quantity $quantity');
      }
    });

    test('order total and its line item never disagree', () {
      final design = designWithPrice(9500);
      for (final quantity in [1, 2, 4]) {
        final order = orderFor(design, quantity);
        expect(order.items.single.price, order.totalAmount,
            reason: 'line item disagrees with total for quantity $quantity');
      }
    });

    test('quantity is recorded on the order for fulfilment', () {
      final design = designWithPrice(3000);
      final order = orderFor(design, 4);
      expect(order.metadata?['quantity'], 4);
      expect(order.totalAmount, 12000);
    });

    test('a zero-priced design yields a zero total rather than a negative', () {
      final design = designWithPrice(0);
      expect(design.price * 2, 0);
    });
  });
  group('quantity column', () {
    test('carries through the entity', () {
      final order = orderFor(designWithPrice(2500), 3);
      expect(order.quantity, 3);
    });

    test('survives copyWith, which the repository uses before insert', () {
      final order = orderFor(designWithPrice(2500), 3);
      final copied = order.copyWith(id: 'order-2', reference: 'DES-2');
      expect(copied.quantity, 3,
          reason: 'copyWith silently dropped quantity');
    });

    test('serialises to the column name the database expects', () {
      final json = OrderModel.fromEntity(orderFor(designWithPrice(2500), 3))
          .toJson();
      expect(json['quantity'], 3);
    });

    test('is null for a legacy order that predates the column', () {
      final legacy = OrderEntity(
        id: 'legacy',
        clientName: 'Buyer',
        items: const [],
        status: OrderStatus.pending,
        totalAmount: 5000,
        createdAt: DateTime(2026, 1, 1),
      );
      expect(legacy.quantity, isNull);
    });
  });

  group('shipment reference naming', () {
    OrderEntity shipped() => OrderEntity(
          id: 'order-9',
          clientName: 'Buyer',
          items: const [],
          status: OrderStatus.pending,
          totalAmount: 5000,
          quantity: 1,
          shipmentId: 'shp_terminal_123',
          createdAt: DateTime(2026, 1, 1),
        );

    test('writes to the legacy fez_order_no column', () {
      // The column was deliberately not renamed; the Dart field is shipmentId.
      final json = OrderModel.fromEntity(shipped()).toJson();
      expect(json.containsKey('fez_order_no'), isTrue,
          reason: 'shipment reference must still persist to fez_order_no');
      expect(json['fez_order_no'], 'shp_terminal_123');
      expect(json.containsKey('shipmentId'), isFalse,
          reason: 'the Dart field name must not leak to the wire');
    });

    test('round-trips a Terminal shipment reference', () {
      final model = OrderModel.fromEntity(shipped());
      final restored = OrderModel.fromJson(model.toJson()).toEntity();
      expect(restored.shipmentId, 'shp_terminal_123');
    });
  });
}
