import 'package:desby_app/features/checkout/domain/entities/checkout_draft.dart';
import 'package:desby_app/features/payments/domain/platform_money_config.dart';
import 'package:flutter_test/flutter_test.dart';

/// Money arithmetic is the one place a silent mistake costs real money, so it
/// is verified rather than eyeballed. Two properties matter most:
///
///  * conservation -- commission + fee + tailor + courier always equals gross,
///    at every amount including awkward ones (rounding must not lose kobo);
///  * the basis -- commission applies to the tailor's service only, not to
///    material or delivery.
void main() {
  group('platform money model', () {
    test('subaccount split value is 1 - commission - payment fee', () {
      // 1 - 0.015 - 0.014 = 0.971. If this ever reads 0.985 the platform is
      // silently paying the transaction fee that is meant to come from the
      // tailor's share.
      expect(PlatformMoneyConfig.subaccountSplitValue, closeTo(0.971, 1e-9));
    });

    test('split value is NOT cent-rounded', () {
      // Regression: this is a rate, not money. Rounding it to 2dp turns 97.1%
      // into 97%, handing the platform 0.1% it was never meant to have and
      // shortchanging the tailor by that much on every order.
      expect(PlatformMoneyConfig.subaccountSplitValue, greaterThan(0.9705));
      expect(PlatformMoneyConfig.subaccountSplitValue, lessThan(0.9715));
    });

    test('service-only order splits to 97.1% for the tailor', () {
      final s = PlatformMoneyConfig.split(const OrderBreakdown(stitching: 100000));

      expect(s.gross, 100000);
      expect(s.commission, 1500); // 1.5%
      expect(s.paymentFee, 1400); // 1.4%
      expect(s.tailorPayout, 97100); // 97.1%
    });

    test('material earns no commission but still bears the fee', () {
      final s = PlatformMoneyConfig.split(
        const OrderBreakdown(stitching: 15000, material: 20000),
      );

      expect(s.gross, 35000);
      // 1.5% of the 15,000 service -- NOT of the 35,000 gross.
      expect(s.commission, 225);
      // The transaction fee is on the whole transaction, tailor's share.
      expect(s.paymentFee, 490);
      expect(s.tailorPayout, 34285);
    });

    test('delivery is paid to the courier and never reaches the tailor', () {
      final s = PlatformMoneyConfig.split(
        const OrderBreakdown(stitching: 15000, delivery: 4900),
      );

      expect(s.gross, 19900);
      expect(s.commission, 225);
      expect(s.paymentFee, closeTo(278.60, 0.005));
      expect(s.delivery, 4900);
      expect(s.tailorPayout, closeTo(14496.40, 0.005));
      expect(s.tailorPayout + s.delivery + s.commission + s.paymentFee,
          closeTo(s.gross, 0.005));
    });

    test('money is conserved across awkward amounts', () {
      // Rounding to 2dp three times can silently drop or invent kobo. Every
      // amount must balance to the cent.
      const amounts = <double>[
        0, 1, 7, 99, 333, 999.99, 1234.56, 5000, 35000, 50000, 77777, 123456.78,
      ];

      for (final amount in amounts) {
        final s = PlatformMoneyConfig.splitGross(amount);
        final accounted = s.commission + s.paymentFee + s.tailorPayout;
        expect(accounted, closeTo(amount, 0.005),
            reason: 'money not conserved at $amount');
      }
    });

    test('money is conserved when every component is present', () {
      final breakdowns = <OrderBreakdown>[
        OrderBreakdown(stitching: 15000, material: 20000),
        OrderBreakdown(stitching: 3500, material: 12500, express: 2000),
        OrderBreakdown(stitching: 2000, delivery: 1000, alteration: 500),
        OrderBreakdown(
            stitching: 1000, alteration: 250, custom: 750, material: 5000,
            express: 300, delivery: 1200),
      ];

      for (final b in breakdowns) {
        final s = PlatformMoneyConfig.split(b);
        final accounted =
            s.commission + s.paymentFee + s.tailorPayout + s.delivery;
        expect(accounted, closeTo(b.gross, 0.005),
            reason: 'not conserved for $b');
      }
    });

    test('an empty order cannot produce a negative payout', () {
      final s = PlatformMoneyConfig.split(const OrderBreakdown());
      expect(s.gross, 0);
      expect(s.tailorPayout, 0);
      expect(s.commission, 0);
      expect(s.paymentFee, 0);
    });

    test('service subtotal excludes material and delivery', () {
      const b = OrderBreakdown(
        stitching: 1000,
        alteration: 200,
        custom: 300,
        express: 100,
        material: 5000,
        delivery: 900,
      );
      expect(b.serviceSubtotal, 1600);
      expect(b.gross, 7500);
    });

    test('staged split is 40/60 and conserves', () {
      final s = PlatformMoneyConfig.stageSplit(100000);
      expect(s.deposit, 40000);
      expect(s.balance, 60000);
      expect(s.deposit + s.balance, 100000);
    });

    test('a tailor with only a stitching price is never quoted material', () {
      // The Rita Andrews case: stitching 15,000, material 20,000. A client who
      // already owns their cloth must be quoted the stitching price alone.
      final withOwnCloth = PlatformMoneyConfig.split(
        const OrderBreakdown(stitching: 15000),
      );
      expect(withOwnCloth.gross, 15000);

      final needsSourcing = PlatformMoneyConfig.split(
        const OrderBreakdown(stitching: 15000, material: 20000),
      );
      expect(needsSourcing.gross, 35000);
    });
  });

  group('fabric ownership', () {
    test('tri-state maps to a nullable column value', () {
      expect(FabricOwnership.undecided.asBool, isNull);
      expect(FabricOwnership.clientSupplied.asBool, isTrue);
      expect(FabricOwnership.tailorSourced.asBool, isFalse);
    });

    test('round-trips through the nullable column value', () {
      for (final ownership in FabricOwnership.values) {
        expect(FabricOwnership.fromBool(ownership.asBool), ownership);
      }
    });

    test('material applies only when the tailor is sourcing', () {
      expect(
        const CheckoutFabric(ownership: FabricOwnership.clientSupplied)
            .materialApplies,
        isFalse,
      );
      expect(
        const CheckoutFabric(ownership: FabricOwnership.tailorSourced)
            .materialApplies,
        isTrue,
      );
      expect(
        const CheckoutFabric(ownership: FabricOwnership.undecided)
            .materialApplies,
        isFalse,
      );
    });
  });
}
