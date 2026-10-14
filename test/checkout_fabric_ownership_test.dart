import 'package:desby_app/features/checkout/domain/entities/checkout_draft.dart';
import 'package:desby_app/features/payments/domain/platform_money_config.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression cover for the Step 3 fabric bug.
///
/// Picking a material after answering "do you already have your fabric?" used
/// to wipe the answer, because the chip handlers rebuilt a brand new
/// [CheckoutFabric] (which carries ownership) instead of copying the existing
/// one. The only way to *deselect* a chip was that same rebuild, because
/// `copyWith` could not express "set this back to null".
void main() {
  group('CheckoutFabric.copyWith', () {
    test('preserves ownership when changing the fabric name', () {
      final fabric = const CheckoutFabric(
        ownership: FabricOwnership.clientSupplied,
      );

      final updated = fabric.copyWith(name: 'Cotton');

      expect(updated.ownership, FabricOwnership.clientSupplied);
      expect(updated.name, 'Cotton');
    });

    test('preserves ownership when selecting a catalogue fabric id', () {
      final fabric = const CheckoutFabric(
        ownership: FabricOwnership.tailorSourced,
      );

      final updated = fabric.copyWith(fabricId: 'abc', name: 'Poplin');

      expect(updated.ownership, FabricOwnership.tailorSourced);
      expect(updated.fabricId, 'abc');
    });

    test('preserves ownership when changing colour', () {
      final fabric = const CheckoutFabric(
        ownership: FabricOwnership.clientSupplied,
        name: 'Cotton',
      );

      expect(fabric.copyWith(colour: 'Wine').ownership,
          FabricOwnership.clientSupplied);
    });

    test('clearName removes the name but keeps ownership', () {
      final fabric = const CheckoutFabric(
        name: 'Cotton',
        ownership: FabricOwnership.tailorSourced,
      );

      final cleared = fabric.copyWith(clearName: true);

      expect(cleared.name, isNull);
      expect(cleared.ownership, FabricOwnership.tailorSourced);
    });

    test('clearFabricId also drops the mirrored name from a catalogue pick', () {
      final fabric = const CheckoutFabric(
        fabricId: 'abc',
        name: 'Poplin',
        ownership: FabricOwnership.tailorSourced,
      );

      final cleared =
          fabric.copyWith(clearFabricId: true, clearName: true);

      expect(cleared.fabricId, isNull);
      expect(cleared.name, isNull);
      expect(cleared.ownership, FabricOwnership.tailorSourced);
    });

    test('clearColour removes only the colour', () {
      final fabric = const CheckoutFabric(
        name: 'Cotton',
        colour: 'Wine',
        ownership: FabricOwnership.clientSupplied,
      );

      final cleared = fabric.copyWith(clearColour: true);

      expect(cleared.colour, isNull);
      expect(cleared.name, 'Cotton');
      expect(cleared.ownership, FabricOwnership.clientSupplied);
    });

    test('an explicit value still wins over the existing one', () {
      final fabric = const CheckoutFabric(name: 'Cotton');

      expect(fabric.copyWith(name: 'Linen').name, 'Linen');
    });

    test('ownership still drives whether material is quoted', () {
      final sourced =
          const CheckoutFabric(ownership: FabricOwnership.tailorSourced);
      final supplied =
          const CheckoutFabric(ownership: FabricOwnership.clientSupplied);

      expect(sourced.materialApplies, isTrue);
      expect(supplied.materialApplies, isFalse);
    });
  });

  group('ownership survives an arbitrary sequence of chip taps', () {
    test('answer ownership last, as a user naturally does', () {
      // Pick cotton first, then declare who supplies the cloth.
      var fabric = const CheckoutFabric();
      fabric = fabric.copyWith(name: 'Cotton');
      fabric = fabric.copyWith(ownership: FabricOwnership.tailorSourced);

      expect(fabric.name, 'Cotton');
      expect(fabric.ownership, FabricOwnership.tailorSourced);
    });

    test('answer ownership first, then pick cotton', () {
      // The order that used to lose the answer.
      var fabric = const CheckoutFabric();
      fabric = fabric.copyWith(ownership: FabricOwnership.tailorSourced);
      fabric = fabric.copyWith(name: 'Cotton');
      fabric = fabric.copyWith(fabricId: 'fab-1', name: 'Cotton Poplin');
      fabric = fabric.copyWith(colour: 'Wine');

      expect(fabric.ownership, FabricOwnership.tailorSourced);
      expect(fabric.name, 'Cotton Poplin');
      expect(fabric.fabricId, 'fab-1');
      expect(fabric.colour, 'Wine');
    });

    test('toggling a material off and on again keeps ownership', () {
      var fabric = const CheckoutFabric(
        ownership: FabricOwnership.clientSupplied,
        name: 'Cotton',
      );

      fabric = fabric.copyWith(clearName: true);
      expect(fabric.ownership, FabricOwnership.clientSupplied);
      expect(fabric.name, isNull);

      fabric = fabric.copyWith(name: 'Linen');
      expect(fabric.ownership, FabricOwnership.clientSupplied);
      expect(fabric.name, 'Linen');
    });

    test('free text replaces a catalogue pick rather than sitting beside it', () {
      var fabric = const CheckoutFabric(fabricId: 'fab-1', name: 'Poplin');

      fabric = fabric.copyWith(name: 'Cotton', clearFabricId: true);

      expect(fabric.fabricId, isNull);
      expect(fabric.name, 'Cotton');
    });
  });
}
