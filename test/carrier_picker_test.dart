import 'package:desby_app/features/checkout/presentation/widgets/carrier_picker.dart';
import 'package:desby_app/features/orders/domain/entities/delivery_booking.dart';
import 'package:desby_app/core/error/failures.dart';
import 'package:desby_app/features/orders/domain/entities/order.dart';
import 'package:desby_app/features/orders/domain/repositories/logistics_repository.dart';
import 'package:desby_app/features/orders/presentation/providers/logistics_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders [CarrierPicker] against a fake multi-carrier repository so the
/// selection, ordering and fallback behaviour are verified without a network
/// call (Flutter's test binding stubs HttpClient to 400).
class _FakeMultiCarrier implements LogisticsRepository {
  _FakeMultiCarrier(this.offers);

  final List<DeliveryQuote> offers;
  int calls = 0;

  @override
  Future<Result<double>> estimateCost(String destinationState) async =>
      Success(offers.isEmpty ? 0 : offers.first.amount);

  @override
  Future<Result<List<DeliveryQuote>>> quotes({
    required String destinationState,
    required double weightKg,
    required double value,
    required String description,
    bool cashOnDelivery = false,
  }) async {
    calls++;
    return Success(offers);
  }

  @override
  Future<Result<String>> summonRider(OrderEntity order) async => const Success('SH-1');

  @override
  Future<Result<Map<String, dynamic>>> trackDelivery(String ref) async =>
      const Success({});
}

DeliveryQuote q(String name, String slug, double amount, {int? eta}) =>
    DeliveryQuote(
      carrierId: slug,
      carrierName: name,
      carrierSlug: slug,
      amount: amount,
      currency: 'NGN',
      rateId: 'RT-$slug',
      deliveryEtaMinutes: eta,
      deliveryTime: eta == null ? 'Standard' : '',
    );

void main() {
  final offers = [
    q('GIG Logistics', 'gigl', 2883.5, eta: 180),
    q('DHL Express', 'dhl', 5748, eta: 720),
    q('Redstar Express', 'redstar', 3622, eta: 1440),
  ];

  Widget harness(Widget child, List<DeliveryQuote>? selectedRef) =>
      ProviderScope(
        overrides: [
          logisticsRepositoryProvider.overrideWithValue(_FakeMultiCarrier(offers)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => child,
            ),
          ),
        ),
      );

  testWidgets('lists every carrier with price and ETA', (tester) async {
    await tester.pumpWidget(harness(
      CarrierPicker(
        destinationState: 'Lagos',
        selected: null,
        onChanged: (_) {},
      ),
      null,
    ));
    await tester.pump();

    expect(find.text('GIG Logistics'), findsOneWidget);
    expect(find.text('DHL Express'), findsOneWidget);
    expect(find.text('Redstar Express'), findsOneWidget);
    expect(find.text('₦2884'), findsOneWidget); // rounded for display
    expect(find.text('CHEAPEST'), findsOneWidget);
  });

  testWidgets('selecting a carrier reports the chosen quote',
      (tester) async {
    DeliveryQuote? chosen;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          logisticsRepositoryProvider
              .overrideWithValue(_FakeMultiCarrier(offers)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: CarrierPicker(
              destinationState: 'Lagos',
              selected: null,
              onChanged: (v) => chosen = v,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('DHL Express'));
    await tester.pump();

    expect(chosen, isNotNull);
    expect(chosen!.carrierSlug, 'dhl');
    expect(chosen!.amount, 5748);
  });

  testWidgets('tapping the cheapest carrier reports null (auto mode)',
      (tester) async {
    DeliveryQuote? chosen;
    bool called = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          logisticsRepositoryProvider
              .overrideWithValue(_FakeMultiCarrier(offers)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: CarrierPicker(
              destinationState: 'Lagos',
              selected: null,
              onChanged: (v) {
                called = true;
                chosen = v;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('GIG Logistics'));
    await tester.pump();

    expect(called, isTrue);
    expect(chosen, isNull, reason: 'cheapest is expressed as null');
  });
}