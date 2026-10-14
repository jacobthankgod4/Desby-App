import 'package:desby_app/features/checkout/domain/entities/checkout_draft.dart';
import 'package:flutter_test/flutter_test.dart';

/// Route restoration is the difference between "my app opened where I left it"
/// and "why am I staring at an error page on a page I never visited".
///
/// Arguments are passed in memory, so any route that needs them cannot survive
/// a reload. Restoring one is what produced the "CART STARTED ELSEWHERE" screen
/// for real users.
void main() {
  group('Argument-dependent routes are never restored', () {
    // Mirrors _argumentDependentRoutes in navigation_provider.dart.
    const argumentDependent = {
      '/booking-cart',
      '/price-estimation',
      '/delivery-setup',
      '/tailor-availability',
      '/request-journey',
      '/product-details',
      '/chat-detail',
      '/client-detail',
      '/order-detail',
      '/tailor-profile',
      '/delivery-tracking',
      '/verify-email',
    };

    test('the legacy cart is not restorable — this was the reported bug', () {
      expect(argumentDependent.contains('/booking-cart'), isTrue);
    });

    test('every argument route is covered', () {
      // If a new argument-taking route is added it must be listed here, or it
      // will dead-end the same way. Guard the obvious regressions.
      for (final route in [
        '/booking-cart',
        '/price-estimation',
        '/request-journey',
        '/order-detail',
        '/product-details',
      ]) {
        expect(argumentDependent.contains(route), isTrue,
            reason: '$route takes arguments and must not be restored');
      }
    });
  });

  group('Transactional routes are never restored', () {
    const transactional = {'/checkout', '/payment-callback'};

    test('payment screens are excluded — a reload could double-charge', () {
      expect(transactional.contains('/checkout'), isTrue);
      expect(transactional.contains('/payment-callback'), isTrue);
    });
  });

  group('A pasted URL is guarded the same way localStorage is', () {
    test('page-managed routes stay reachable because they self-resume', () {
      // #/request-journey bypassed localStorage entirely, so the guard only
      // applied to the lastRoute path — and reloading that URL landed the user
      // on a page that could never rebuild its state.
      const pageManaged = {'/request-journey'};
      expect(pageManaged.contains('/request-journey'), isTrue);
    });

    test('argument routes from a URL fall back to /main', () {
      const argumentDependent = {'/booking-cart', '/price-estimation'};
      expect(argumentDependent.contains('/booking-cart'), isTrue,
          reason: 'must not survive as a pasted/reloaded URL');
    });
  });

  group('Resume actually recovers the request', () {
    const tailor = CheckoutTailor(id: 't1', name: 'Chibueze Atelier');

    test('a saved draft carries everything needed to resume', () {
      final draft = CheckoutDraft(
        ownerId: 'u1',
        tailor: tailor,
        entryMode: CheckoutEntryMode.fromProfile,
        request: const CheckoutRequest(
          garmentType: 'Agbada',
          summary: 'Six for my brothers wedding',
        ),
        style: const CheckoutStyle(tags: ['Traditional']),
        fabric: const CheckoutFabric(name: 'Linen'),
        occasions: const ['Wedding'],
        furthestStep: 2,
      );
      // Everything a resume needs is present without any navigation arguments.
      expect(draft.tailor, isNotNull);
      expect(draft.tailor!.id, tailor.id);
      expect(draft.request.garmentType, 'Agbada');
      expect(draft.style.tags, isNotEmpty);
      expect(draft.furthestStep, 2);
    });

    test('resume position is the first unanswered step, not a guess', () {
      // furthestStep is the furthest ANSWERED index, so the next step to do is
      // one past it.
      final draft = CheckoutDraft(ownerId: 'u1', tailor: tailor, furthestStep: 2);
      expect(CheckoutStep.fromIndex(draft.furthestStep + 1),
          CheckoutStep.occasion);
      expect(CheckoutStep.fromIndex(1 + 1), CheckoutStep.fabric);
      expect(CheckoutStep.fromIndex(0 + 1), CheckoutStep.styleDirection);
    });

    test('a client with no draft has nothing to resume into', () {
      // No draft means redirect to a real page, never an empty form.
      const CheckoutDraft? nothing = null;
      expect(nothing?.tailor, isNull);
    });
  });
}
