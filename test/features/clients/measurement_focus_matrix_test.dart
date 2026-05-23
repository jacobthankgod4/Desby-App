import 'package:flutter_test/flutter_test.dart';
import 'package:desby_app/features/clients/presentation/utils/measurement_focus_profiles.dart';

void main() {
  group('MeasurementFocusProfiles matrix', () {
    const knownLabels = <String>[
      'Shoulder',
      'Neck Round',
      'Bust Round',
      'High Bust',
      'Under Bust',
      'Bust Point',
      'Shoulder to Bust Point',
      'Shoulder to Under Bust',
      'Shoulder to Waist',
      'Front Waist Length',
      'Back Waist Length',
      'Across Chest',
      'Across Back',
      'Armhole Round',
      'Sleeve Length',
      'Bicep Round',
      'Elbow Round',
      'Wrist Round',
      'Waist Round',
      'Half Length',
      'Waist to Hip',
      'Upper Hip',
      'Hip Round',
      'Thigh Round',
      'Knee Round',
      'Calf Round',
      'Ankle Round',
      'Waist to Knee',
      'Waist to Calf',
      'Waist to Floor',
      'Full Dress Length',
      'Skirt Length',
      'Wrapper Length',
      'Corset Front Length',
      'Corset Side Length',
      'Corset Back Length',
      'Under Bust to Waist',
      'Waist to Lower Corset Edge',
      'Cup Size',
      'Stomach Round',
      'Full Top Length',
      'Shirt Length',
      'Chest Round',
      'Trouser Waist',
      'Trouser Length',
      'Inseam',
      'Crotch Depth',
      'Rise',
      'Seat Round',
      'Senator Length',
      'Kaftan Length',
      'Agbada Length',
      'Agbada Sleeve Length',
      'Jacket Length',
      'Lapel Width',
      'Jacket Sleeve Length',
      'Trouser Opening Width',
      'Vest Length',
    ];

    test('known labels resolve with valid profile ranges and score in [0,1]', () {
      for (final label in knownLabels) {
        final resolution = MeasurementFocusProfiles.resolve(label);
        final profile = resolution.profile;
        final score = MeasurementFocusProfiles.score(resolution);

        expect(resolution.canonicalKey.trim().isNotEmpty, isTrue, reason: 'canonical key empty for $label');
        expect(profile.bucket.trim().isNotEmpty, isTrue, reason: 'bucket empty for $label');

        expect(profile.orbit.radius, greaterThan(0), reason: 'radius must be > 0 for $label');
        expect(profile.orbit.phi, allOf(greaterThanOrEqualTo(0), lessThanOrEqualTo(180)),
            reason: 'phi out of range for $label');
        expect(profile.orbit.theta, allOf(greaterThanOrEqualTo(-360), lessThanOrEqualTo(360)),
            reason: 'theta out of range for $label');

        expect(score, allOf(greaterThanOrEqualTo(0), lessThanOrEqualTo(1)),
            reason: 'score out of [0,1] for $label');
      }
    });

    test('unknown label resolves safely and score remains bounded', () {
      const unknown = 'Custom Unknown Measurement XYZ';
      final resolution = MeasurementFocusProfiles.resolve(unknown);
      final profile = resolution.profile;
      final score = MeasurementFocusProfiles.score(resolution);

      expect(resolution.usedFallback, isTrue);
      expect(profile.orbit.radius, greaterThan(0));
      expect(score, allOf(greaterThanOrEqualTo(0), lessThanOrEqualTo(1)));
    });

    test('normalization variants map deterministically', () {
      final a = MeasurementFocusProfiles.resolve('neck round');
      final b = MeasurementFocusProfiles.resolve('Neck-Round');
      final c = MeasurementFocusProfiles.resolve('NECK   ROUND');

      expect(a.canonicalKey, equals(b.canonicalKey));
      expect(b.canonicalKey, equals(c.canonicalKey));
    });
  });
}
