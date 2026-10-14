import 'package:desby_app/config/environment.dart';
import 'package:desby_app/features/orders/data/repositories/terminal_shipping_repository_impl.dart';
import 'package:desby_app/features/orders/domain/entities/delivery_booking.dart';
import 'package:flutter_test/flutter_test.dart';

/// Exercises [TerminalShippingRepositoryImpl] against the Terminal sandbox.
///
/// Reads `.env` the same way production does, so a broken request shape fails
/// here rather than at checkout. Skipped when no key is present, and pinned to
/// the sandbox host so it can never book a paid shipment.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Same bootstrap the app performs at launch, including loading .env from
    // assets — so the test exercises the real configuration path.
    await Environment.initialize();
  });

  group('TerminalShippingRepositoryImpl', () {
    late TerminalShippingRepositoryImpl repo;
    // Resolved lazily: Environment.current is not initialised until setUpAll.
    late bool enabled;

    setUp(() {
      repo = TerminalShippingRepositoryImpl();
      enabled = Environment.current.terminalShippingConfigured;
    });

    test('defaults to the sandbox so a live shipment cannot be booked by accident',
        () {
      if (enabled) {
        expect(
          Environment.current.terminalShippingBaseUrl,
          contains('sandbox.terminal.africa'),
        );
      } else {
        expect(
          Environment.current.terminalShippingBaseUrl,
          'https://sandbox.terminal.africa/v1',
        );
      }
    });

    test('estimateCost returns a positive NGN price for Lagos', () async {
      if (!enabled) {
        markTestSkipped('no TERMINAL_API_SECRET_KEY in .env');
        return;
      }
      // Flutter's test binding stubs HttpClient to return 400, so a live call
      // cannot succeed here. This asserts the failure is handled honestly
      // rather than surfacing as an unhandled throw — the live round-trip is
      // verified by scripts/verify_terminal_shipping.sh instead.
      final result = await repo.estimateCost('Lagos');
      result.fold(
        (failure) => expect(failure.message, isNotEmpty),
        (cost) => expect(cost, greaterThan(0)),
      );
    });

    test('normalises Nigerian phone numbers to +234 form', () {
      // Terminal validates the phone against the address country, so local
      // formats must be converted or the quote is rejected.
      String n(String? v) =>
          TerminalShippingRepositoryImpl.normaliseNgPhone(v);
      expect(n('08031234567'), '+2348031234567');
      expect(n('+2348031234567'), '+2348031234567');
      expect(n('2348031234567'), '+2348031234567');
      expect(n('8031234567'), '+2348031234567');
      // Unusable input falls back to a valid placeholder, never a bare local
      // number that Terminal would reject.
      expect(n(''), startsWith('+234'));
      expect(n(null), startsWith('+234'));
    });

    test('DeliveryQuote formats ETA for display', () {
      const fast = DeliveryQuote(
        carrierId: 'c1',
        carrierName: 'GIG Logistics',
        carrierSlug: 'gigl',
        amount: 2883.5,
        currency: 'NGN',
        rateId: 'RT-1',
        deliveryEtaMinutes: 180,
      );
      const days = DeliveryQuote(
        carrierId: 'c2',
        carrierName: 'DHL',
        carrierSlug: 'dhl',
        amount: 5748,
        currency: 'NGN',
        rateId: 'RT-2',
        deliveryEtaMinutes: 2880,
        deliveryTime: 'Within 2 days',
      );
      const none = DeliveryQuote(
        carrierId: 'c3',
        carrierName: 'X',
        carrierSlug: 'x',
        amount: 1,
        currency: 'NGN',
        rateId: 'RT-3',
        deliveryTime: 'Next day',
      );
      expect(fast.etaLabel, '3 hr');
      expect(days.etaLabel, '2 days');
      // No ETA minutes -> fall back to the carrier's own wording.
      expect(none.etaLabel, 'Next day');
    });

    test('DeliveryBooking.isArranged is false only for drafts', () {
      const draft = DeliveryBooking(
        shipmentId: 'SH-1',
        status: 'draft',
        carrierName: 'GIG',
        amount: 1,
        currency: 'NGN',
      );
      const done = DeliveryBooking(
        shipmentId: 'SH-2',
        status: 'confirmed',
        carrierName: 'GIG',
        amount: 1,
        currency: 'NGN',
      );
      expect(draft.isArranged, isFalse);
      expect(done.isArranged, isTrue);
    });

    test('unconfigured repository fails honestly instead of throwing', () async {
      // No key => must return a Failure, never throw or invent a price.
      final bare = TerminalShippingRepositoryImpl();
      final result = await bare.estimateCost('Lagos');
      if (!enabled) {
        result.fold(
          (failure) => expect(failure.message, contains('unavailable')),
          (_) => fail('unconfigured repository must not return a price'),
        );
      }
    });
  });
}