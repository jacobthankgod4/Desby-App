import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards against the onboarding steps being clipped again.
///
/// Each onboarding page wrapped its `PageView` in `SizedBox(height: 400)`, which
/// clipped every form. Removing the pin was not enough on its own: a `PageView`
/// needs a *bounded* height, and with the pin gone it became unbounded inside
/// the scaffold's scroll view, so the page grew without limit and scrolled
/// forever.
///
/// The fix is to render only the current step. Swiping was already disabled with
/// `NeverScrollableScrollPhysics`, so `PageView` bought nothing — a direct child
/// sizes to its content and lets the scaffold scroll normally.
///
/// These are source-level assertions because the failure is a layout
/// constraint, not runtime state.
void main() {
  const pages = {
    'tailor':
        'lib/features/tailor/presentation/pages/tailor_onboarding_page.dart',
    'client':
        'lib/features/clients/presentation/pages/client_onboarding_page.dart',
    'fabric seller': 'lib/features/marketplace/presentation/pages/'
        'fabric_seller_onboarding_page.dart',
    'apprentice': 'lib/features/apprenticeship/presentation/pages/'
        'apprentice_onboarding_page.dart',
  };

  group('onboarding steps are not height-clipped', () {
    pages.forEach((label, path) {
      test('$label renders one content-sized step, not a clipped PageView', () {
        final src = File(path).readAsStringSync();

        // Strip line comments so explanatory prose is not mistaken for code.
        final code = src
            .split('\n')
            .where((l) => !l.trimLeft().startsWith('//'))
            .join('\n');

        expect(code.contains('height: 400'), isFalse,
            reason: '$label still pins its steps to a fixed height');

        // A PageView needs a bounded height; without one it either clips (when
        // pinned) or grows forever (when not). Rendering the current step
        // directly removes the constraint entirely.
        expect(code.contains('PageView'), isFalse,
            reason: '$label still uses a PageView, which needs a bounded height');
        expect(
          code.contains('_stepFor(_currentStep)') ||
              code.contains('_currentStepBuilder()'),
          isTrue,
          reason: '$label should render only the current step',
        );
        expect(code.contains('child: SizedBox('), isFalse,
            reason: '$label must not wrap its step content in a fixed SizedBox');
      });
    });

    test('the shared scaffold already scrolls, so steps may grow', () {
      final scaffold =
          File('lib/core/widgets/onboarding_scaffold.dart').readAsStringSync();
      expect(scaffold.contains('SingleChildScrollView'), isTrue);
    });
  });
}
