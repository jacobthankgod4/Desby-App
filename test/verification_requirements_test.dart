import 'package:desby_app/features/verification/data/verification_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Address proof is mandatory for a tailor to finish onboarding, alongside the
/// identity document.
///
/// This previously gated on identity alone, so a tailor could complete
/// onboarding having uploaded only an ID. `isCompleteForOnboarding` is the
/// single place that decision is made; these tests pin it.
void main() {
  group('submitted vs verified', () {
    test('pending counts as submitted for both documents', () {
      const status = VerificationStatus(
        identity: VerificationState.pending,
        address: VerificationState.pending,
      );

      expect(status.isIdentitySubmitted, isTrue);
      expect(status.isAddressSubmitted, isTrue);
      expect(status.isCompleteForOnboarding, isTrue);
      // But neither is actually approved yet.
      expect(status.isIdentityVerified, isFalse);
      expect(status.isAddressVerified, isFalse);
    });

    test('rejected does not count as submitted', () {
      const status = VerificationStatus(
        identity: VerificationState.rejected,
        address: VerificationState.rejected,
      );

      expect(status.isIdentitySubmitted, isFalse);
      expect(status.isAddressSubmitted, isFalse);
      expect(status.isCompleteForOnboarding, isFalse);
    });

    test('expired does not count as submitted', () {
      const status = VerificationStatus(
        identity: VerificationState.expired,
        address: VerificationState.expired,
      );

      expect(status.isCompleteForOnboarding, isFalse);
    });
  });

  group('isCompleteForOnboarding', () {
    test('identity alone is not enough', () {
      // The exact gap this change closes.
      const status = VerificationStatus(identity: VerificationState.pending);

      expect(status.isIdentitySubmitted, isTrue);
      expect(status.isAddressSubmitted, isFalse);
      expect(status.isCompleteForOnboarding, isFalse);
    });

    test('address alone is not enough', () {
      const status = VerificationStatus(address: VerificationState.pending);

      expect(status.isCompleteForOnboarding, isFalse);
    });

    test('one verified and one pending is enough to finish', () {
      const status = VerificationStatus(
        identity: VerificationState.verified,
        address: VerificationState.pending,
      );

      expect(status.isCompleteForOnboarding, isTrue);
    });

    test('nothing submitted is not enough', () {
      const status = VerificationStatus();

      expect(status.isCompleteForOnboarding, isFalse);
    });
  });

  group('outstandingRequirements', () {
    test('names both documents when neither is on file', () {
      const status = VerificationStatus();

      expect(status.outstandingRequirements,
          ['an identity document', 'proof of address']);
    });

    test('names only address once identity is done', () {
      const status = VerificationStatus(identity: VerificationState.pending);

      expect(status.outstandingRequirements, ['proof of address']);
    });

    test('names only identity when address is done first', () {
      const status = VerificationStatus(address: VerificationState.pending);

      expect(status.outstandingRequirements, ['an identity document']);
    });

    test('is empty once both are on file', () {
      const status = VerificationStatus(
        identity: VerificationState.verified,
        address: VerificationState.verified,
      );

      expect(status.outstandingRequirements, isEmpty);
    });
  });

  group('fromRpc', () {
    test('maps an identity-only row to incomplete', () {
      final status = VerificationStatus.fromRpc([
        {
          'identity_status': 'pending',
          'address_status': null,
        }
      ]);

      expect(status.isIdentitySubmitted, isTrue);
      expect(status.isCompleteForOnboarding, isFalse);
    });

    test('maps a full row to complete', () {
      final status = VerificationStatus.fromRpc([
        {
          'identity_status': 'pending',
          'address_status': 'verified',
        }
      ]);

      expect(status.isCompleteForOnboarding, isTrue);
    });

    test('an unknown status string counts as not submitted', () {
      final status = VerificationStatus.fromRpc([
        {
          'identity_status': 'something-else',
          'address_status': 'pending',
        }
      ]);

      expect(status.isIdentitySubmitted, isFalse);
      expect(status.isCompleteForOnboarding, isFalse);
    });
  });
}
