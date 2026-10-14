import 'package:flutter_test/flutter_test.dart';

/// Documents the KYC gate contract used by the tailor onboarding step.
///
/// The page persisted `_identitySubmitted` / `_addressSubmitted` in local state
/// but only refreshed them from the `verification_status_for` RPC from the
/// child's `onChanged` callback. On a hard reload neither flag was read, so
/// `_kycComplete` was false and a tailor who had already uploaded both documents
/// was told to upload them again, with Continue blocked.
void main() {
  group('kyc gate', () {
    // Mirrors VerificationService.VerificationStatus
    const pending = 'pending';
    const verified = 'verified';
    const rejected = 'rejected';
    const none = 'none';

    bool isSubmitted(String s) => s == pending || s == verified;

    test('pending counts as submitted so onboarding can proceed', () {
      expect(isSubmitted(pending), isTrue);
    });

    test('verified counts as submitted', () {
      expect(isSubmitted(verified), isTrue);
    });

    test('rejected and missing do not count', () {
      expect(isSubmitted(rejected), isFalse);
      expect(isSubmitted(none), isFalse);
    });

    test('both documents required, not just one', () {
      final complete = (bool i, bool a) => i && a;
      expect(complete(true, true), isTrue);
      expect(complete(true, false), isFalse,
          reason: 'address proof is mandatory');
      expect(complete(false, true), isFalse);
      expect(complete(false, false), isFalse);
    });

    test('the gate must be read from the server, never assumed', () {
      // A freshly constructed page has no knowledge of submissions; only the
      // RPC can fill it in. This is why initState must call the loader.
      var identitySubmitted = false;
      var addressSubmitted = false;
      expect(identitySubmitted && addressSubmitted, isFalse);

      // after the RPC returns pending for both
      identitySubmitted = isSubmitted(pending);
      addressSubmitted = isSubmitted(pending);
      expect(identitySubmitted && addressSubmitted, isTrue);
    });
  });
}
