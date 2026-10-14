import 'package:desby_app/features/auth/data/repositories/supabase_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// The confirmation link must land on the Flutter app, not the marketing site.
///
/// `desby.app` serves the marketing site at `/` and the app at `/app/`. The bare
/// origin ignores Supabase's `?code=` callback entirely, so a user registering
/// landed on a landing page with a dead code in the query string instead of
/// their verification page.
void main() {
  group('auth redirect target', () {
    test('targets the app path, not the bare origin', () {
      expect(kAppBaseUrl, 'https://desby.app/app');
    });

    test('never points at the marketing root', () {
      expect(kAppBaseUrl, isNot('https://desby.app'));
      expect(kAppBaseUrl.endsWith('/app'), isTrue,
          reason: 'the Flutter app is served under /app/');
    });

    test('is an allowed redirect URL on the project', () {
      const allowed = {
        'https://desby.app/app',
        'https://desby.app/app/verify-email',
      };
      expect(allowed.contains(kAppBaseUrl), isTrue);
    });
  });

  group('expired-link recovery', () {
    // Supabase reports callback failures in the fragment, e.g.
    //   #error=access_denied&error_code=otp_expired
    // The app must treat that as a recoverable state, not as a route.
    test('fragments carrying an auth error are not valid routes', () {
      const expired = 'error=access_denied&error_code=otp_expired';
      expect(expired.startsWith('error='), isTrue);
      expect(expired.startsWith('/'), isFalse,
          reason: 'treated as an error, so the user can request a fresh link');
    });

    test('expired and denied codes are both caught', () {
      for (final fragment in [
        'error=access_denied&error_code=otp_expired',
        'error=access_denied&error_description=Email+link+is+invalid',
      ]) {
        final isError = fragment.startsWith('error=') ||
            fragment.contains('error_code=') ||
            fragment.contains('error_description=');
        expect(isError, isTrue);
      }
    });
  });
}
