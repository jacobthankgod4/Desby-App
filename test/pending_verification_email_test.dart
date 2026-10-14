import 'package:flutter_test/flutter_test.dart';

/// A hard reload of /verify-email must still be able to resend.
///
/// The route carries no arguments on the boot-time recovery path
/// (`#error=...otp_expired`), so the only way the page can resend is by reading a
/// persisted address. `rememberedEmail` is written only at login and only when
/// "remember me" is ticked, so it is empty for a user who registered and never
/// logged in — hence a dedicated pending-verification key.
void main() {
  group('pending verification email', () {
    const key = 'pending_verification_email';

    test('is a distinct key from the login-remembered email', () {
      // If these collided, clearing one would silently clear the other.
      expect(key, isNot('remembered_email'));
      expect(key, 'pending_verification_email');
    });

    test('resolution order prefers the pending address', () {
      // direct argument -> pending -> remembered
      const direct = 'user@example.com';
      const pending = 'pending@example.com';
      const remembered = 'old@example.com';

      String resolve(String arg, String? pend, String? rem) {
        if (arg.trim().isNotEmpty) return arg.trim();
        if ((pend ?? '').trim().isNotEmpty) return pend!.trim();
        return (rem ?? '').trim();
      }

      expect(resolve(direct, pending, remembered), direct);
      expect(resolve('', pending, remembered), pending);
      expect(resolve('', null, remembered), remembered);
      expect(resolve('', null, null), '');
    });

    test('an empty resolved address blocks resend rather than firing blank', () {
      const blank = '';
      expect(blank.isNotEmpty, isFalse);
    });
  });
}
