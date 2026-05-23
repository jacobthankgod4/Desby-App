import '../model/camera_profile.dart';
import 'measurement_normalizer.dart';

/// Resolves a measurement key into a specific camera profile.
/// Part of Step 5: Canonical Dictionary Contract - Fuzzy & Family Fallback.
class MeasurementFocusResolver {
  final Map<String, CameraProfile> _profiles;
  final CameraProfile fallbackProfile;

  MeasurementFocusResolver({
    required Map<String, CameraProfile> profiles,
    required this.fallbackProfile,
  }) : _profiles = profiles;

  /// Resolve using the full normalization pipeline
  /// Implements Section 5.3 resolver chain:
  /// exact → alias → fuzzy → family → default
  ResolveResult resolve(String label) {
    // Use the complete normalize pipeline from MeasurementNormalizer
    final normalizeResult = MeasurementNormalizer.normalize(label);
    final key = normalizeResult.key;
    
    if (_profiles.containsKey(key)) {
      return ResolveResult(
        profile: _profiles[key]!,
        resolvedKey: key,
        confidence: normalizeResult.confidence,
        resolutionMethod: normalizeResult.resolutionMethod,
        usedFallback: false,
      );
    }
    
    // No profile found for resolved key - return fallback with context
    return ResolveResult(
      profile: fallbackProfile,
      resolvedKey: key,
      confidence: normalizeResult.confidence,
      resolutionMethod: normalizeResult.resolutionMethod,
      usedFallback: true,
    );
  }

  /// Legacy resolve method for backward compatibility
  CameraProfile resolveStrict(String key) {
    if (_profiles.containsKey(key)) {
      return _profiles[key]!;
    }
    return fallbackProfile;
  }
}

/// Result of resolution
class ResolveResult {
  final CameraProfile profile;
  final String resolvedKey;
  final double confidence;
  final ResolutionMethod resolutionMethod;
  final bool usedFallback;

  const ResolveResult({
    required this.profile,
    required this.resolvedKey,
    required this.confidence,
    required this.resolutionMethod,
    required this.usedFallback,
  });
}
