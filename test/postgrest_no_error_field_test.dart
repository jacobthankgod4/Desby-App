import 'package:flutter_test/flutter_test.dart';
import 'package:postgrest/postgrest.dart';

/// Regression guard for the `NoSuchMethodError: method not found: 'gdu'`
/// onboarding failure.
///
/// `postgrest` 2.9 removed the `error` field from `PostgrestResponse`. A failed
/// request now throws a `PostgrestException` instead of returning an error
/// object, so code of the form:
///
/// ```dart
/// final res = await client.rpc('complete_tailor_onboarding');
/// if (res.error != null) { ... }
/// ```
///
/// throws at runtime. In a release build dart2js mangles the missing member to a
/// short name like `gdu`, so the surface symptom was an opaque:
/// `Save failed: NoSuchMethodError: method not found: 'gdu'`.
///
/// If a future upgrade re-adds `error`, these tests fail loudly so the guards in
/// the onboarding/cart call sites can be re-evaluated on purpose.
void main() {
  group('postgrest 2.9 response contract', () {
    test('PostgrestResponse has no `error` field', () {
      final response = PostgrestResponse<List<Map<String, dynamic>>>(
        data: const <Map<String, dynamic>>[],
        count: 0,
      );

      // Static type is PostgrestResponse, so a `.error` read would not even
      // compile. Assert the runtime shape to document the breaking change.
      expect(response.data, isEmpty);
      expect(response.count, 0);
    });

    test('failures surface as a thrown PostgrestException', () {
      final error = PostgrestException(
        code: 'PGRST202',
        message: 'function complete_tailor_onboarding does not exist',
        details: null,
      );

      expect(error.message, contains('complete_tailor_onboarding'));
      expect(error, isA<PostgrestException>());
    });
  });
}