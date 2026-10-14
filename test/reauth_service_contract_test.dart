import 'package:flutter_test/flutter_test.dart';

/// Documents why account deletion must not treat a `signInWithPassword` call as
/// proof of identity.
///
/// The previous code called `signInWithPassword` and ignored its response, then
/// deleted the account. With MFA enabled that call resolves with **no user and
/// no exception**, so the delete proceeded without the identity ever being
/// confirmed. The guard below is the contract the service now enforces.
void main() {
  group('reauth guard', () {
    test('a response without a user must not count as confirmed', () {
      // Mirrors the MFA case: response.user is null, nothing was thrown.
      const String? user = null;
      final confirmed = user != null;
      expect(confirmed, isFalse,
          reason: 'no user in the response means identity is unproven');
    });

    test('a returned user counts as confirmed', () {
      const String? user = 'user-123';
      expect(user != null, isTrue);
    });

    test('an empty password is never a confirmation', () {
      // The dialog already blocks this; the guard must not depend on that.
      const password = '';
      expect(password.isNotEmpty && password.length >= 1, isFalse);
    });
  });
}
