import 'package:desby_app/features/checkout/presentation/widgets/request_journey_tour.dart';
import 'package:flutter_test/flutter_test.dart';

/// Onboarding has an asymmetry, and it is the whole point of these tests:
///
///   * Showing the tour unnecessarily → mildly irritating, and self-healing.
///     The client finishes it and never sees it again.
///   * Not showing it when it was needed → silently broken. Nobody reports a
///     feature that quietly stopped existing, so it rots.
///
/// Every ambiguous state must therefore resolve towards "show once".
void main() {
  bool resolve({required bool localSeen, bool? serverSeen}) =>
      RequestJourneyTour.resolveShouldShow(
        localSeen: localSeen,
        serverSeen: serverSeen,
      );

  group('definitely needed', () {
    test('never seen anywhere -> show', () {
      expect(resolve(localSeen: false, serverSeen: false), isTrue);
    });

    test('no session at all -> still show', () {
      // A signed-out or not-yet-restored session is the common case on a cold
      // load. It must not swallow the tour.
      expect(resolve(localSeen: false, serverSeen: null), isTrue);
    });
  });

  group('definitely not needed', () {
    test('seen locally -> do not show, whatever the server says', () {
      expect(resolve(localSeen: true, serverSeen: false), isFalse);
      expect(resolve(localSeen: true, serverSeen: true), isFalse);
      expect(resolve(localSeen: true, serverSeen: null), isFalse);
    });

    test('dismissed on another device -> do not show', () {
      expect(resolve(localSeen: false, serverSeen: true), isFalse);
    });
  });

  group('the regression this replaces', () {
    test('a failed preferences read no longer suppresses the tour', () {
      // The previous implementation caught every error and returned false,
      // meaning one flaky request permanently denied the tour — and the same
      // user would see it on Wi-Fi but not on mobile data.
      expect(resolve(localSeen: false, serverSeen: null), isTrue,
          reason: 'unknown must fail OPEN for showing');
    });

    test('a missing user id no longer suppresses the tour', () {
      expect(resolve(localSeen: false, serverSeen: null), isTrue);
    });
  });

  test('the policy is total — every combination has a defined answer', () {
    for (final localSeen in [true, false]) {
      for (final serverSeen in [true, false, null]) {
        // Must not throw and must return a bool for all six combinations.
        expect(resolve(localSeen: localSeen, serverSeen: serverSeen),
            isA<bool>());
      }
    }
  });
}
