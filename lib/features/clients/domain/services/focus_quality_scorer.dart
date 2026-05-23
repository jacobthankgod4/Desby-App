import '../model/focus_models.dart';
import 'measurement_normalizer.dart';

/// Implements Section 6: Deterministic Quality Scoring Spec.
///
/// Formula: Q = w1*C + w2*V + w3*O + w4*S
///
/// Where:
/// - C = center alignment score (distance of target from viewport center)
/// - V = estimated visible region ratio (projected region coverage)
/// - O = occlusion penalty inverted (1 - occlusion risk)
/// - S = stability score (camera transition smoothness/jerk)
///
/// Weights: w1=0.35, w2=0.30, w3=0.25, w4=0.10
///
/// Thresholds:
/// - Q >= 0.82: excellent
/// - 0.70 <= Q < 0.82: acceptable
/// - Q < 0.70: trigger fallback + optional hint
class FocusQualityScorer {
  FocusQualityScorer._();

  /// Quality thresholds per Section 6
  static const double thresholdExcellent = 0.82;
  static const double thresholdAcceptable = 0.70;

  /// Weights per Section 6 spec
  static const double w1 = 0.35; // center alignment
  static const double w2 = 0.30; // visible region
  static const double w3 = 0.25; // occlusion
  static const double w4 = 0.10; // stability

  /// Compute quality score for a focus resolution
  static QualityScore score({
    required String measurementKey,
    required FocusProfile profile,
    required NormalizeResult normalizeResult,
    String gender = 'female',
    String? previousProfileId,
    int? transitionDurationMs,
  }) {
    // Component scores (each 0.0 to 1.0)
    final c = _computeCenterScore(profile, measurementKey);
    final v = _computeVisibilityScore(profile, measurementKey, gender);
    final o = _computeOcclusionScore(profile, measurementKey);
    final s = _computeStabilityScore(
      currentProfileId: profile.bucket,
      previousProfileId: previousProfileId,
      transitionDurationMs: transitionDurationMs,
    );

    // Apply formula
    final q = (w1 * c) + (w2 * v) + (w3 * o) + (w4 * s);

    // Determine rating
    final rating = q >= thresholdExcellent
        ? QualityRating.excellent
        : q >= thresholdAcceptable
            ? QualityRating.acceptable
            : QualityRating.poor;

    return QualityScore(
      q: q,
      c: c,
      v: v,
      o: o,
      s: s,
      rating: rating,
      measurementKey: measurementKey,
      profileId: profile.bucket,
      gender: gender,
      shouldFallback: rating == QualityRating.poor,
      fallbackReason: rating == QualityRating.poor ? _getFallbackReason(q, c, v, o, s) : null,
    );
  }

  /// Compute center alignment score (C)
  /// Based on how centered the target is in the viewport
  static double _computeCenterScore(FocusProfile profile, String measurementKey) {
    // Ideal targets are near center (0, 0, 0 in camera space)
    // Score decreases as target moves away from ideal center
    final targetY = profile.target.y;
    final targetZ = profile.target.z;

    // Y should be around 0.0-0.3 for upper body, -0.1 to 0.1 for torso
    // Z should be around 0.0 for front-facing measurements
    final idealY = _getIdealY(measurementKey);
    final idealZ = 0.0;

    final yOffset = (targetY - idealY).abs();
    final zOffset = (targetZ - idealZ).abs();

    // Penalize large offsets
    final yScore = (1.0 - (yOffset * 2)).clamp(0.0, 1.0);
    final zScore = (1.0 - (zOffset * 4)).clamp(0.0, 1.0);

    return (yScore * 0.7) + (zScore * 0.3);
  }

  /// Get ideal Y coordinate for measurement type
  static double _getIdealY(String measurementKey) {
    if (measurementKey.contains('neck')) return 0.45;
    if (measurementKey.contains('shoulder')) return 0.42;
    if (measurementKey.contains('bust') || measurementKey.contains('chest')) return 0.28;
    if (measurementKey.contains('waist')) return 0.10;
    if (measurementKey.contains('hip')) return -0.08;
    if (measurementKey.contains('thigh')) return -0.26;
    if (measurementKey.contains('knee')) return -0.33;
    if (measurementKey.contains('calf')) return -0.38;
    if (measurementKey.contains('ankle')) return -0.45;
    return 0.0; // Default torso center
  }

  /// Compute visibility score (V)
  /// Based on estimated region coverage
  static double _computeVisibilityScore(
      FocusProfile profile, String measurementKey, String gender) {
    // Smaller body parts need tighter zoom (higher score)
    // Larger body parts can have looser framing
    final radius = profile.orbit.radius;

    // Ideal radius varies by measurement type
    final idealRadius = _getIdealRadius(measurementKey);

    // Score based on how close to ideal radius
    final radiusDiff = (radius - idealRadius).abs();
    final radiusScore = (1.0 - (radiusDiff / 0.5)).clamp(0.0, 1.0);

    return radiusScore;
  }

  /// Get ideal camera radius for measurement type
  static double _getIdealRadius(String measurementKey) {
    if (measurementKey.contains('neck')) return 1.35;
    if (measurementKey.contains('bicep') ||
        measurementKey.contains('elbow') ||
        measurementKey.contains('wrist')) {
      return 1.65;
    }
    if (measurementKey.contains('knee')) return 1.55;
    if (measurementKey.contains('ankle')) return 1.28;
    if (measurementKey.contains('full') || measurementKey.contains('floor')) return 2.0;
    return 1.75; // Default
  }

  /// Compute occlusion score (O)
  /// Penalize measurements that might be occluded
  static double _computeOcclusionScore(FocusProfile profile, String measurementKey) {
    // Back-facing measurements have higher occlusion risk
    final theta = profile.orbit.theta;
    final isBackView = theta > 90 && theta < 270;

    if (isBackView) {
      // Potentially occluded - check if it's a "front-only" measurement
      final frontOnlyMeasurements = [
        'bust_round',
        'bust_point',
        'chest_round',
        'across_chest'
      ];
      if (frontOnlyMeasurements.contains(measurementKey)) {
        return 0.5; // Lower score for back view of front-focused measurement
      }
    }

    return 1.0; // No occlusion risk
  }

  /// Compute stability score (S)
  /// Based on camera transition smoothness
  static double _computeStabilityScore({
    required String currentProfileId,
    String? previousProfileId,
    int? transitionDurationMs,
  }) {
    // First focus is always stable
    if (previousProfileId == null) {
      return 1.0;
    }

    // Same profile = perfect stability
    if (currentProfileId == previousProfileId) {
      return 1.0;
    }

    // If transition is too fast or too slow, reduce stability
    if (transitionDurationMs != null) {
      // Ideal transition: 400-800ms
      if (transitionDurationMs < 200) {
        return 0.5; // Too fast - jerky
      }
      if (transitionDurationMs > 1200) {
        return 0.6; // Too slow - confusing
      }
      return 0.9; // Good range
    }

    // Default moderate score when duration unknown
    return 0.8;
  }

  /// Get reason for fallback
  static String _getFallbackReason(
      double q, double c, double v, double o, double s) {
    if (c < 0.5) return 'target_off_center';
    if (v < 0.5) return 'poor_visibility';
    if (o < 0.5) return 'occlusion_risk';
    if (s < 0.5) return 'unstable_transition';
    return 'low_quality';
  }

  /// Check if score is below acceptable threshold
  static bool shouldTriggerFallback(double q) {
    return q < thresholdAcceptable;
  }

  /// Get bucket quality baseline from measurement type
  static double getBucketBaseline(String bucket) {
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
    return bucketQuality[bucket] ?? 0.70;
  }
}

/// Result of quality scoring
class QualityScore {
  final double q;
  final double c;
  final double v;
  final double o;
  final double s;
  final QualityRating rating;
  final String measurementKey;
  final String profileId;
  final String gender;
  final bool shouldFallback;
  final String? fallbackReason;

  const QualityScore({
    required this.q,
    required this.c,
    required this.v,
    required this.o,
    required this.s,
    required this.rating,
    required this.measurementKey,
    required this.profileId,
    required this.gender,
    required this.shouldFallback,
    this.fallbackReason,
  });

  /// Get telemetry payload for logging
  Map<String, dynamic> toTelemetry() {
    return {
      'measurementKey': measurementKey,
      'gender': gender,
      'profileId': profileId,
      'Q': q,
      'C': c,
      'V': v,
      'O': o,
      'S': s,
      'fallbackUsed': shouldFallback,
      'rating': rating.name,
    };
  }
}

/// Quality rating
enum QualityRating {
  excellent, // Q >= 0.82
  acceptable, // 0.70 <= Q < 0.82
  poor, // Q < 0.70
}
