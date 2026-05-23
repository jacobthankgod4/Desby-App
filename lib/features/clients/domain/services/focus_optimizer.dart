import '../model/focus_models.dart';
import 'focus_quality_scorer.dart';

/// Implements Section 8: Calibration Protocol (Bounding Box / Pose Context)
///
/// This service handles:
/// - Using model global bounds and segment/landmark cluster bounds
/// - Computing region-size-aware zoom
/// - Applying family multipliers
/// - Per-model calibration multipliers
/// - Score validation and iterative search
class FocusOptimizer {
  FocusOptimizer._();

  /// Family multipliers per Section 8.2
  static const double familyMultiplierNeck = 0.75;
  static const double familyMultiplierChest = 1.00;
  static const double familyMultiplierHip = 0.95;
  static const double familyMultiplierFull = 1.25;

  /// Per-model scale multipliers
  static const double maleScaleK = 1.0;
  static const double femaleScaleK = 0.95;

  /// Radius bounds
  static const double minRadius = 1.2;
  static const double maxRadius = 2.2;

  /// Min/max phi values
  static const double minPhi = -30.0;
  static const double maxPhi = 60.0;

  /// Theta offsets for views
  static const double thetaBack = 180.0;
  static const double thetaLeft = -90.0;
  static const double thetaRight = 90.0;

  /// Compute optimized camera parameters
  static FocusProfile optimize({
    required String measurementKey,
    required String gender,
    required String platform,
    required String measurementFamily,
    FocusProfile? baseProfile,
  }) {
    // Start from base profile if provided
    final focusTarget = baseProfile?.target ?? const FocusTarget(0, 0, 0);
    final focusOrbit = baseProfile?.orbit ?? const FocusOrbit(0, 0, 1.75);

    // Compute region bounding radius (Step 8.2.2)
    final regionRadius = _computeRegionRadius(measurementKey, measurementFamily);

    // Apply family multiplier (Step 8.2.3)
    final familyMult = _getFamilyMultiplier(measurementFamily);
    var adjustedRadius = regionRadius * familyMult;

    // Apply gender/model scale adjustment (Step 8.2.4)
    final genderScale = gender == 'male' ? maleScaleK : femaleScaleK;
    adjustedRadius *= genderScale;

    // Clamp to bounds
    adjustedRadius = adjustedRadius.clamp(minRadius, maxRadius);

    // Apply view offsets based on measurement type
    final adjustedOrbit = _applyViewOffsets(focusOrbit, measurementKey);

    // Return optimized profile
    return FocusProfile(
      target: focusTarget,
      orbit: FocusOrbit(
        adjustedOrbit.theta,
        adjustedOrbit.phi,
        adjustedRadius,
      ),
      bucket: baseProfile?.bucket ?? measurementFamily,
    );
  }

  /// Compute base region radius from measurement type
  static double _computeRegionRadius(String measurementKey, String family) {
    // Base radius varies by body region size
    if (measurementKey.contains('neck')) return 1.35;
    if (measurementKey.contains('shoulder')) return 1.65;
    if (measurementKey.contains('bicep') ||
        measurementKey.contains('elbow') ||
        measurementKey.contains('wrist')) {
      return 1.65;
    }
    if (measurementKey.contains('chest') || measurementKey.contains('bust')) return 1.55;
    if (measurementKey.contains('waist')) return 1.45;
    if (measurementKey.contains('hip')) return 1.50;
    if (measurementKey.contains('thigh')) return 1.55;
    if (measurementKey.contains('knee')) return 1.55;
    if (measurementKey.contains('calf')) return 1.40;
    if (measurementKey.contains('ankle')) return 1.28;
    if (measurementKey.contains('full') || measurementKey.contains('floor')) return 2.0;

    // Family-based defaults
    switch (family) {
      case 'upper_body':
        return 1.6;
      case 'torso':
        return 1.5;
      case 'hip_legs':
        return 1.55;
      case 'garment_specific':
        return 1.8;
      case 'corset_female':
        return 1.45;
      default:
        return 1.75;
    }
  }

  /// Get family multiplier
  static double _getFamilyMultiplier(String family) {
    const multipliers = <String, double>{
      'neck': familyMultiplierNeck,
      'upper_body': 0.82,
      'torso': familyMultiplierChest,
      'hip_legs': familyMultiplierHip,
      'lower_body': 0.88,
      'full_body': familyMultiplierFull,
      'garment_specific': 1.1,
      'corset_female': familyMultiplierChest,
      'arm': 0.85,
    };
    return multipliers[family] ?? 1.0;
  }

  /// Apply view offsets based on measurement
  static FocusOrbit _applyViewOffsets(FocusOrbit orbit, String measurementKey) {
    var theta = orbit.theta;
    final phi = orbit.phi;
    final radius = orbit.radius;

    // Back measurements get theta + 180
    final backMeasurements = [
      'back_waist_length',
      'back_waist',
      'across_back',
    ];
    if (backMeasurements.any((m) => measurementKey.contains(m))) {
      theta = (theta + thetaBack) % 360;
    }

    // Side measurements get theta +/- 90
    final sideMeasurements = [
      'side',
      'half_length',
    ];
    if (sideMeasurements.any((m) => measurementKey.contains(m))) {
      if (measurementKey.contains('left')) {
        theta = (theta + thetaLeft) % 360;
      } else if (measurementKey.contains('right')) {
        theta = (theta + thetaRight) % 360;
      }
    }

    return FocusOrbit(theta, phi, radius);
  }

  /// Validate score and iterate if below threshold (Step 8.2.5)
  static ({FocusProfile profile, bool wasIterated}) validateAndIterate({
    required FocusProfile profile,
    required QualityScore score,
    required String measurementKey,
    String gender = 'female',
    int maxIterations = 3,
  }) {
    if (!score.shouldFallback || maxIterations <= 0) {
      return (profile: profile, wasIterated: false);
    }

    var currentProfile = profile;
    var iterations = 0;
    var wasIterated = false;

    // Iterative small-step search
    while (iterations < maxIterations) {
      // Try adjusting radius slightly
      final tryRadius = currentProfile.orbit.radius * 1.05;
      final adjustedOrbit = FocusOrbit(
        currentProfile.orbit.theta,
        currentProfile.orbit.phi,
        tryRadius.clamp(minRadius, maxRadius),
      );
      final adjustedProfile = FocusProfile(
        target: currentProfile.target,
        orbit: adjustedOrbit,
        bucket: currentProfile.bucket,
      );

      // Re-score
      // Note: In production, would re-compute score here
      // For now, assume this is better and accept
      currentProfile = adjustedProfile;
      wasIterated = true;
      iterations++;

      // If significantly different, accept
      if (score.q > 0.75) break;
    }

    return (profile: currentProfile, wasIterated: wasIterated);
  }

  /// Get platform-specific adjustment
  static double getPlatformAdjustment(String platform) {
    const platformAdjustments = <String, double>{
      'web': 1.0,
      'android': 0.95,
      'ios': 0.92,
      'macos': 1.0,
    };
    return platformAdjustments[platform] ?? 1.0;
  }

  /// Apply platform-specific calibration
  static FocusProfile applyPlatformCalibration({
    required FocusProfile profile,
    required String platform,
  }) {
    final adjustment = getPlatformAdjustment(platform);
    final adjustedRadius = profile.orbit.radius * adjustment;

    return FocusProfile(
      target: profile.target,
      orbit: FocusOrbit(
        profile.orbit.theta,
        profile.orbit.phi,
        adjustedRadius.clamp(minRadius, maxRadius),
      ),
      bucket: profile.bucket,
    );
  }

  /// Persist tuned profile (Step 8.2.6)
  /// In production, would save to local storage or cloud
  static Future<void> persistTunedProfile({
    required String measurementKey,
    required String gender,
    required FocusProfile profile,
    int stableSessions = 3,
  }) async {
    // Stub: In production, implement persistence
    // Could use SharedPreferences or Firebase
    // Only persist if stable across N sessions
    print('Would persist: $measurementKey/$gender -> radius=${profile.orbit.radius} ($stableSessions sessions)');
  }
}
