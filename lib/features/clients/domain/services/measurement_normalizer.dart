import '../model/measurement_key.dart';
import '../model/measurement_aliases.dart';

/// Normalizes UI-facing labels into canonical snake_case keys.
/// Part of Step 5: Canonical Dictionary Contract - Fuzzy Matching & Alias Resolution.
///
/// Resolver order (per Section 5.3):
/// 1. exact canonical
/// 2. exact alias
/// 3. normalized alias
/// 4. fuzzy alias (confidence >= threshold)
/// 5. measurement family fallback
/// 6. global default
class MeasurementNormalizer {
  MeasurementNormalizer._();

  /// Confidence threshold for fuzzy matching (0.0 to 1.0)
  static const double fuzzyThreshold = 0.70;

/// Family fallback map when no exact match found
  static const Map<String, String> familyFallbacks = {
    'upper_body': MeasurementKey.neckRound, // Default to neck for upper body
    'torso': MeasurementKey.waistRound,
    'hip_legs': MeasurementKey.hipRound,
    'garment_specific': MeasurementKey.fullTopLength,
    'corset_female': MeasurementKey.bustRound,
  };

  /// Global fallback when no family match
  static const String globalFallback = MeasurementKey.fallback;

  static String? _lastResolutionMethod;

  /// Get the resolution method used in last call
  static String? get lastResolutionMethod => _lastResolutionMethod;

/// Main normalize function implementing Section 5.3 resolver chain
  static NormalizeResult normalize(String label) {
    final input = label.trim().toLowerCase();
    // Normalize: replace all non-alphanumeric with underscore
    final clean = input.replaceAll(RegExp(r'[\s\-]+'), '_');

    // Step 1: Check exact canonical key match
    if (_isCanonicalKey(clean)) {
      _lastResolutionMethod = 'exact_canonical';
      return NormalizeResult(
        key: clean,
        confidence: 1.0,
        resolutionMethod: ResolutionMethod.exactCanonical,
        family: MeasurementAliasRegistry.getFamilyForKey(clean),
      );
    }

    // Step 2: Check exact alias match
    final exactAlias = _findExactAlias(clean);
    if (exactAlias != null) {
      _lastResolutionMethod = 'exact_alias';
      return NormalizeResult(
        key: exactAlias.canonicalKey,
        confidence: 1.0,
        resolutionMethod: ResolutionMethod.exactAlias,
        family: exactAlias.family,
      );
    }

    // Step 3: Check normalized alias (just in case)
    final normalizedAlias = _findExactAlias(clean);
    if (normalizedAlias != null) {
      _lastResolutionMethod = 'normalized_alias';
      return NormalizeResult(
        key: normalizedAlias.canonicalKey,
        confidence: 0.95,
        resolutionMethod: ResolutionMethod.normalizedAlias,
        family: normalizedAlias.family,
      );
    }

    // Step 4: Fuzzy alias matching
    final fuzzyResult = _findFuzzyAlias(input);
    if (fuzzyResult != null && fuzzyResult.confidence >= fuzzyThreshold) {
      _lastResolutionMethod = 'fuzzy_alias';
      return NormalizeResult(
        key: fuzzyResult.alias.canonicalKey,
        confidence: fuzzyResult.confidence,
        resolutionMethod: ResolutionMethod.fuzzyAlias,
        family: fuzzyResult.alias.family,
      );
    }

    // Step 5: Measurement family fallback
    final family = _detectFamily(input);
    if (family != null && familyFallbacks.containsKey(family)) {
      _lastResolutionMethod = 'family_fallback';
      return NormalizeResult(
        key: familyFallbacks[family]!,
        confidence: 0.5,
        resolutionMethod: ResolutionMethod.familyFallback,
        family: family,
      );
    }

    // Step 6: Global fallback
    _lastResolutionMethod = 'global_fallback';
    return NormalizeResult(
      key: globalFallback,
      confidence: 0.3,
      resolutionMethod: ResolutionMethod.globalFallback,
      family: null,
    );
  }

  /// Check if string is a known canonical key
  static bool _isCanonicalKey(String key) {
    return MeasurementKey.shoulder == key ||
        MeasurementKey.neckRound == key ||
        MeasurementKey.bustRound == key ||
        MeasurementKey.chestRound == key ||
        MeasurementKey.highBust == key ||
        MeasurementKey.underBust == key ||
        MeasurementKey.waistRound == key ||
        MeasurementKey.hipRound == key ||
        MeasurementKey.thighRound == key ||
        MeasurementKey.ankleRound == key ||
        MeasurementKey.fallback == key;
  }

  /// Find exact alias match
  static MeasurementAlias? _findExactAlias(String label) {
    for (final entry in MeasurementAliasRegistry.aliases) {
      if (entry.alias == label) {
        return entry;
      }
    }
    return null;
  }

  /// Find fuzzy alias match using Levenshtein distance
  static ({MeasurementAlias alias, double confidence})? _findFuzzyAlias(
      String label) {
    MeasurementAlias? bestMatch;
    double bestConfidence = 0.0;

    for (final entry in MeasurementAliasRegistry.aliases) {
      final confidence = _computeSimilarity(label, entry.alias);
      if (confidence > bestConfidence && confidence >= fuzzyThreshold) {
        bestConfidence = confidence;
        bestMatch = entry;
      }
    }

    if (bestMatch != null) {
      return (alias: bestMatch, confidence: bestConfidence);
    }
    return null;
  }

  /// Compute similarity score between two strings (0.0 to 1.0)
  /// Uses token-set ratio for robustness
  static double _computeSimilarity(String a, String b) {
    // Token-set ratio: split into tokens and compute overlap
    final tokensA = a.split(RegExp(r'[_\s]+')).where((t) => t.isNotEmpty).toSet();
    final tokensB = b.split(RegExp(r'[_\s]+')).where((t) => t.isNotEmpty).toSet();

    if (tokensA.isEmpty || tokensB.isEmpty) return 0.0;

    final intersection = tokensA.intersection(tokensB).length;
    final union = tokensA.union(tokensB).length;

    final tokenScore = intersection / union;

    // Also compute Levenshtein on full strings
    final levScore = 1.0 - (_levenshteinDistance(a, b) / (a.length > b.length ? a.length : b.length));

    // Return weighted combination
    return (tokenScore * 0.7) + (levScore * 0.3);
  }

  /// Compute Levenshtein distance between two strings
  static int _levenshteinDistance(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final matrix = List.generate(
      a.length + 1,
      (_) => List.filled(b.length + 1, 0),
    );

    for (var i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }
    for (var j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }

    for (var i = 1; i <= a.length; i++) {
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1, // deletion
          matrix[i][j - 1] + 1, // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[a.length][b.length];
  }

  /// Detect measurement family from label keywords
  static String? _detectFamily(String label) {
    final upperBodyKeywords = ['shoulder', 'neck', 'bust', 'chest', 'arm', 'sleeve', 'wrist', 'elbow', 'bicep'];
    final torsoKeywords = ['waist', 'stomach', 'front', 'back', 'half'];
    final hipLegsKeywords = ['hip', 'thigh', 'knee', 'calf', 'ankle', 'trouser', 'inseam', 'rise', 'crotch', 'seat'];
    final garmentKeywords = ['dress', 'skirt', 'wrapper', 'senator', 'kaftan', 'agbada', 'jacket', 'vest', 'shirt', 'top', 'lapel'];
    final corsetKeywords = ['corset', 'cup'];

    for (final kw in upperBodyKeywords) {
      if (label.contains(kw)) return 'upper_body';
    }
    for (final kw in torsoKeywords) {
      if (label.contains(kw)) return 'torso';
    }
    for (final kw in hipLegsKeywords) {
      if (label.contains(kw)) return 'hip_legs';
    }
    for (final kw in garmentKeywords) {
      if (label.contains(kw)) return 'garment_specific';
    }
    for (final kw in corsetKeywords) {
      if (label.contains(kw)) return 'corset_female';
    }

    return null;
  }

  /// Validate alias registry integrity (Section 5.4 Contract Checks)
  static ValidationResult validateRegistry() {
    final errors = <String>[];
    final seenAliases = <String>{};

    // Check for duplicate aliases
    for (final entry in MeasurementAliasRegistry.aliases) {
      if (seenAliases.contains(entry.alias)) {
        errors.add('Duplicate alias: ${entry.alias}');
      }
      seenAliases.add(entry.alias);
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      aliasCount: MeasurementAliasRegistry.aliases.length,
    );
  }
}

/// Result of normalization
class NormalizeResult {
  final String key;
  final double confidence;
  final ResolutionMethod resolutionMethod;
  final String? family;

  const NormalizeResult({
    required this.key,
    required this.confidence,
    required this.resolutionMethod,
    this.family,
  });

  bool get isHighConfidence => confidence >= 0.82;
  bool get isAcceptable => confidence >= 0.70 && confidence < 0.82;
  bool get isLowConfidence => confidence < 0.70;
}

/// Resolution method used
enum ResolutionMethod {
  exactCanonical,
  exactAlias,
  normalizedAlias,
  fuzzyAlias,
  familyFallback,
  globalFallback,
}

/// Validation result for registry integrity
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final int aliasCount;

  const ValidationResult({
    required this.isValid,
    required this.errors,
    required this.aliasCount,
  });
}
