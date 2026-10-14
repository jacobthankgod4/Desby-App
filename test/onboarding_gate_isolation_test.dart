import 'package:desby_app/core/storage/storage_keys.dart';
import 'package:flutter_test/flutter_test.dart';

/// The sign-in gate decides dashboard vs onboarding from these flags.
///
/// They used to be one global key per role, so a user who onboarded left
/// `tailor_onboarding_complete = true` behind and the next person to sign up on
/// the same browser inherited it and was sent straight to the dashboard without
/// ever seeing onboarding.
void main() {
  group('onboarding flag isolation', () {
    const userA = 'user-a';
    const userB = 'user-b';

    test('keys differ per user', () {
      expect(
        StorageKeys.tailorOnboardedFor(userA),
        isNot(StorageKeys.tailorOnboardedFor(userB)),
      );
    });

    test('every role is namespaced', () {
      for (final fn in [
        StorageKeys.tailorOnboardedFor,
        StorageKeys.apprenticeOnboardedFor,
        StorageKeys.clientOnboardedFor,
        StorageKeys.fabricSellerOnboardedFor,
      ]) {
        expect(fn(userA), isNot(fn(userB)), reason: 'role $fn leaks across users');
      }
    });

    test('the key embeds the user id', () {
      expect(StorageKeys.tailorOnboardedFor(userA), contains(userA));
    });

    test('roles stay distinct from each other for one user', () {
      expect(
        StorageKeys.tailorOnboardedFor(userA),
        isNot(StorageKeys.clientOnboardedFor(userA)),
      );
    });

    test('a new user never inherits an existing flag', () {
      // Simulates the map a localStorage-backed store would hold.
      final store = <String, bool>{};
      store[StorageKeys.tailorOnboardedFor(userA)] = true;

      // User B must read as not-onboarded, which routes them to onboarding.
      expect(store[StorageKeys.tailorOnboardedFor(userB)], isNull);
      expect(store[StorageKeys.tailorOnboardedFor(userB)] ?? false, isFalse);
    });
  });
}
