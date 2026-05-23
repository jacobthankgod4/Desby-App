import '../../domain/model/focus_models.dart';
import '../../domain/model/measurement_key.dart';
import '../../domain/services/measurement_normalizer.dart';

class MeasurementFocusProfiles {
  static const FocusProfile fallback = FocusProfile(
    target: FocusTarget(0, -0.4, 0),
    orbit: FocusOrbit(0, 75, 1.8),
    bucket: 'fallback',
  );

  static const Map<String, FocusProfile> profiles = {
    // Upper structure
    MeasurementKey.neckRound: FocusProfile(
      target: FocusTarget(0, 0.45, 0),
      orbit: FocusOrbit(0, 70, 1.35),
      bucket: 'neck',
    ),
    MeasurementKey.shoulder: FocusProfile(
      target: FocusTarget(0, 0.42, 0),
      orbit: FocusOrbit(0, 72, 1.45),
      bucket: 'upper_back',
    ),
    MeasurementKey.acrossBack: FocusProfile(
      target: FocusTarget(0, 0.35, -0.02),
      orbit: FocusOrbit(180, 75, 1.55),
      bucket: 'upper_back',
    ),
    MeasurementKey.acrossChest: FocusProfile(
      target: FocusTarget(0, 0.32, 0.03),
      orbit: FocusOrbit(0, 82, 1.7),
      bucket: 'upper_front',
    ),
    MeasurementKey.chestRound: FocusProfile(
      target: FocusTarget(0, 0.30, 0.02),
      orbit: FocusOrbit(0, 84, 1.75),
      bucket: 'upper_front',
    ),
    MeasurementKey.bustRound: FocusProfile(
      target: FocusTarget(0, 0.28, 0.03),
      orbit: FocusOrbit(0, 84, 1.75),
      bucket: 'upper_front',
    ),
    MeasurementKey.highBust: FocusProfile(
      target: FocusTarget(0, 0.34, 0.02),
      orbit: FocusOrbit(0, 82, 1.72),
      bucket: 'upper_front',
    ),
    MeasurementKey.underBust: FocusProfile(
      target: FocusTarget(0, 0.22, 0.02),
      orbit: FocusOrbit(0, 86, 1.72),
      bucket: 'upper_front',
    ),
    MeasurementKey.bustPoint: FocusProfile(
      target: FocusTarget(0.03, 0.24, 0.03),
      orbit: FocusOrbit(10, 86, 1.62),
      bucket: 'upper_front',
    ),
    MeasurementKey.shoulderToBustPoint: FocusProfile(
      target: FocusTarget(0.02, 0.30, 0.02),
      orbit: FocusOrbit(8, 80, 1.70),
      bucket: 'upper_front',
    ),
    MeasurementKey.shoulderToUnderBust: FocusProfile(
      target: FocusTarget(0.02, 0.26, 0.02),
      orbit: FocusOrbit(8, 84, 1.72),
      bucket: 'upper_front',
    ),
    MeasurementKey.shoulderToWaist: FocusProfile(
      target: FocusTarget(0.01, 0.20, 0.01),
      orbit: FocusOrbit(6, 88, 1.75),
      bucket: 'waist',
    ),
    MeasurementKey.frontWaistLength: FocusProfile(
      target: FocusTarget(0, 0.17, 0.02),
      orbit: FocusOrbit(0, 88, 1.75),
      bucket: 'waist',
    ),
    MeasurementKey.backWaistLength: FocusProfile(
      target: FocusTarget(0, 0.17, -0.02),
      orbit: FocusOrbit(180, 88, 1.75),
      bucket: 'waist',
    ),
    MeasurementKey.armholeRound: FocusProfile(
      target: FocusTarget(0.08, 0.30, 0.0),
      orbit: FocusOrbit(25, 84, 1.58),
      bucket: 'upper_front',
    ),
    MeasurementKey.sleeveLength: FocusProfile(
      target: FocusTarget(0.20, 0.20, 0.0),
      orbit: FocusOrbit(45, 86, 1.85),
      bucket: 'arm',
    ),
    MeasurementKey.bicepRound: FocusProfile(
      target: FocusTarget(0.16, 0.24, 0.0),
      orbit: FocusOrbit(40, 86, 1.72),
      bucket: 'arm',
    ),
    MeasurementKey.elbowRound: FocusProfile(
      target: FocusTarget(0.22, 0.12, 0.0),
      orbit: FocusOrbit(45, 88, 1.65),
      bucket: 'arm',
    ),
    MeasurementKey.wristRound: FocusProfile(
      target: FocusTarget(0.24, 0.02, 0.0),
      orbit: FocusOrbit(50, 90, 1.55),
      bucket: 'arm',

    ),

    // Core body
    MeasurementKey.waistRound: FocusProfile(
      target: FocusTarget(0, 0.10, 0.01),
      orbit: FocusOrbit(0, 90, 1.75),
      bucket: 'waist',
    ),
    MeasurementKey.stomachRound: FocusProfile(
      target: FocusTarget(0, 0.08, 0.01),
      orbit: FocusOrbit(0, 92, 1.78),
      bucket: 'waist',
    ),
    MeasurementKey.halfLength: FocusProfile(
      target: FocusTarget(0, 0.12, 0),
      orbit: FocusOrbit(0, 88, 1.80),
      bucket: 'waist',
    ),
    MeasurementKey.waistToHip: FocusProfile(
      target: FocusTarget(0, 0.00, 0),
      orbit: FocusOrbit(0, 90, 1.80),
      bucket: 'hip',
    ),
    MeasurementKey.upperHip: FocusProfile(
      target: FocusTarget(0, -0.05, 0),
      orbit: FocusOrbit(0, 92, 1.82),
      bucket: 'hip',
    ),
    MeasurementKey.hipRound: FocusProfile(
      target: FocusTarget(0, -0.08, 0),
      orbit: FocusOrbit(0, 92, 1.80),
      bucket: 'hip',
    ),
    MeasurementKey.seatRound: FocusProfile(
      target: FocusTarget(0, -0.09, -0.02),
      orbit: FocusOrbit(180, 92, 1.80),
      bucket: 'hip',
    ),

    // Lower body
    MeasurementKey.thighRound: FocusProfile(
      target: FocusTarget(0, -0.26, 0),
      orbit: FocusOrbit(0, 92, 1.62),
      bucket: 'upper_leg',
    ),
    MeasurementKey.kneeRound: FocusProfile(
      target: FocusTarget(0, -0.33, 0),
      orbit: FocusOrbit(0, 92, 1.55),
      bucket: 'knee',
    ),
    MeasurementKey.calfRound: FocusProfile(
      target: FocusTarget(0, -0.38, 0),
      orbit: FocusOrbit(0, 92, 1.45),
      bucket: 'lower_leg',
    ),
    MeasurementKey.ankleRound: FocusProfile(
      target: FocusTarget(0, -0.45, 0),
      orbit: FocusOrbit(0, 92, 1.28),
      bucket: 'ankle',
    ),
    MeasurementKey.waistToKnee: FocusProfile(
      target: FocusTarget(0, -0.24, 0),
      orbit: FocusOrbit(0, 90, 1.65),
      bucket: 'upper_leg',
    ),
    MeasurementKey.waistToCalf: FocusProfile(
      target: FocusTarget(0, -0.34, 0),
      orbit: FocusOrbit(0, 90, 1.55),
      bucket: 'lower_leg',
    ),
    MeasurementKey.waistToFloor: FocusProfile(
      target: FocusTarget(0, -0.46, 0),
      orbit: FocusOrbit(0, 90, 1.25),
      bucket: 'ankle',
    ),
    MeasurementKey.trouserOpeningWidth: FocusProfile(
      target: FocusTarget(0, -0.47, 0),
      orbit: FocusOrbit(0, 92, 1.20),
      bucket: 'ankle',
    ),
    MeasurementKey.trouserWaist: FocusProfile(
      target: FocusTarget(0, 0.03, 0),
      orbit: FocusOrbit(0, 90, 1.80),
      bucket: 'waist',
    ),
    MeasurementKey.trouserLength: FocusProfile(
      target: FocusTarget(0, -0.35, 0),
      orbit: FocusOrbit(0, 88, 1.55),
      bucket: 'lower_leg',
    ),
    MeasurementKey.inseam: FocusProfile(
      target: FocusTarget(0.02, -0.24, 0.02),
      orbit: FocusOrbit(10, 90, 1.60),
      bucket: 'upper_leg',
    ),
    MeasurementKey.crotchDepth: FocusProfile(
      target: FocusTarget(0.01, -0.12, 0.03),
      orbit: FocusOrbit(12, 92, 1.72),
      bucket: 'hip',
    ),
    MeasurementKey.rise: FocusProfile(
      target: FocusTarget(0.00, -0.06, 0.02),
      orbit: FocusOrbit(8, 92, 1.75),
      bucket: 'hip',
    ),

    // Length and outfit-driven
    MeasurementKey.fullDressLength: FocusProfile(
      target: FocusTarget(0, -0.20, 0),
      orbit: FocusOrbit(0, 84, 1.95),
      bucket: 'full_body',
    ),
    MeasurementKey.skirtLength: FocusProfile(
      target: FocusTarget(0, -0.20, 0),
      orbit: FocusOrbit(0, 88, 1.75),
      bucket: 'lower_body',
    ),
    MeasurementKey.wrapperLength: FocusProfile(
      target: FocusTarget(0, -0.20, 0),
      orbit: FocusOrbit(0, 88, 1.75),
      bucket: 'lower_body',
    ),
    MeasurementKey.fullTopLength: FocusProfile(
      target: FocusTarget(0, 0.02, 0),
      orbit: FocusOrbit(0, 88, 1.78),
      bucket: 'torso',
    ),
    MeasurementKey.shirtLength: FocusProfile(
      target: FocusTarget(0, 0.02, 0),
      orbit: FocusOrbit(0, 88, 1.78),
      bucket: 'torso',
    ),
    MeasurementKey.senatorLength: FocusProfile(
      target: FocusTarget(0, -0.12, 0),
      orbit: FocusOrbit(0, 86, 1.88),
      bucket: 'full_body',
    ),
    MeasurementKey.kaftanLength: FocusProfile(
      target: FocusTarget(0, -0.16, 0),
      orbit: FocusOrbit(0, 85, 1.92),
      bucket: 'full_body',
    ),
    MeasurementKey.agbadaLength: FocusProfile(
      target: FocusTarget(0, -0.18, 0),
      orbit: FocusOrbit(0, 84, 2.0),
      bucket: 'full_body',
    ),
    MeasurementKey.agbadaSleeveLength: FocusProfile(
      target: FocusTarget(0.24, 0.18, 0),
      orbit: FocusOrbit(45, 84, 2.0),
      bucket: 'arm',
    ),
    MeasurementKey.jacketLength: FocusProfile(
      target: FocusTarget(0, 0.04, 0),
      orbit: FocusOrbit(0, 88, 1.8),
      bucket: 'torso',
    ),
    MeasurementKey.lapelWidth: FocusProfile(
      target: FocusTarget(0.06, 0.28, 0.04),
      orbit: FocusOrbit(16, 84, 1.62),
      bucket: 'upper_front',
    ),
    MeasurementKey.jacketSleeveLength: FocusProfile(
      target: FocusTarget(0.22, 0.18, 0),
      orbit: FocusOrbit(45, 86, 1.88),
      bucket: 'arm',
    ),
    MeasurementKey.vestLength: FocusProfile(
      target: FocusTarget(0, 0.12, 0.02),
      orbit: FocusOrbit(0, 88, 1.74),
      bucket: 'torso',
    ),

    // Corset-specific
    MeasurementKey.corsetFrontLength: FocusProfile(
      target: FocusTarget(0.00, 0.14, 0.03),
      orbit: FocusOrbit(0, 88, 1.70),
      bucket: 'waist',
    ),
    MeasurementKey.corsetSideLength: FocusProfile(
      target: FocusTarget(0.10, 0.12, 0.00),
      orbit: FocusOrbit(32, 88, 1.68),
      bucket: 'waist',
    ),
    MeasurementKey.corsetBackLength: FocusProfile(
      target: FocusTarget(0.00, 0.14, -0.03),
      orbit: FocusOrbit(180, 88, 1.70),
      bucket: 'waist',
    ),
    MeasurementKey.underBustToWaist: FocusProfile(
      target: FocusTarget(0.00, 0.18, 0.02),
      orbit: FocusOrbit(0, 88, 1.70),
      bucket: 'waist',
    ),
    MeasurementKey.waistToLowerCorsetEdge: FocusProfile(
      target: FocusTarget(0.00, 0.06, 0.02),
      orbit: FocusOrbit(0, 90, 1.72),
      bucket: 'waist',
    ),
    MeasurementKey.cupSize: FocusProfile(
      target: FocusTarget(0.04, 0.24, 0.03),
      orbit: FocusOrbit(10, 84, 1.62),
      bucket: 'upper_front',
    ),
  };

  static FocusProfile _calibrated(FocusProfile base) {
    const bucketZoomMultiplier = <String, double>{
      // tighter zoom for fine-detail regions
      'neck': 0.78,
      'ankle': 0.76,
      'knee': 0.82,
      'arm': 0.80,
      'upper_front': 0.84,
      'upper_back': 0.84,
      // medium zoom for core body
      'waist': 0.86,
      'hip': 0.88,
      'upper_leg': 0.88,
      'lower_leg': 0.86,
      'torso': 0.90,
      // broad framing buckets
      'lower_body': 0.92,
      'full_body': 0.94,
      'fallback': 0.90,
    };

    final multiplier = bucketZoomMultiplier[base.bucket] ?? 0.88;
    final calibratedRadius = (base.orbit.radius * multiplier).clamp(1.05, 1.75);

    return FocusProfile(
      target: base.target,
      orbit: FocusOrbit(base.orbit.theta, base.orbit.phi, calibratedRadius),
      bucket: base.bucket,
    );
  }

static FocusResolution resolve(String rawLabel) {
    // Use the new normalize API from Step 5
    final result = MeasurementNormalizer.normalize(rawLabel);
    final key = result.key;
    
    final profile = profiles[key];
    if (profile != null) {
      return FocusResolution(
        canonicalKey: key,
        profile: _calibrated(profile),
        usedFallback: result.resolutionMethod == ResolutionMethod.globalFallback ||
            result.resolutionMethod == ResolutionMethod.familyFallback,
        confidence: result.confidence,
      );
    }

    // Fallback if no profile found for resolved key
    return FocusResolution(
      canonicalKey: MeasurementKey.fallback,
      profile: _calibrated(fallback),
      usedFallback: true,
      confidence: 0.35,
    );
  }

  static double score(FocusResolution resolution) {
    const bucketQuality = <String, double>{
      'neck': 0.90,
      'upper_back': 0.85,
      'upper_front': 0.86,
      'waist': 0.83,
      'hip': 0.81,
      'upper_leg': 0.80,
      'knee': 0.78,
      'lower_leg': 0.76,
      'ankle': 0.80,
      'arm': 0.79,
      'torso': 0.82,
      'lower_body': 0.80,
      'full_body': 0.77,
      'fallback': 0.65,
    };

    final base = bucketQuality[resolution.profile.bucket] ?? 0.70;
    final confidenceBoost = (resolution.confidence - 0.5) * 0.2;
    final value = base + confidenceBoost;

    if (value < 0) return 0;
    if (value > 1) return 1;
    return value;
  }
}
