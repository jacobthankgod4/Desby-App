/// Measurement Mapper - Lookup table for Korra AI -> Desby OS labels
///
/// Maps Korra API measurement keys (from /measurements/estimate and /measurements/extract)
/// to the Bespoke Station UI field labels used in MeasurementInputPage.
class MeasurementMapper {
  /// Primary mapping: Korra API keys -> Desby UI labels
  static const Map<String, String> korraToDesby = {
    // Core measurements (returned by estimate and extract)
    'chest': 'Chest Round',
    'waist': 'Waist Round',
    'hip': 'Hip Round',
    'shoulder': 'Shoulder',
    'neck': 'Neck Round',
    'inseam': 'Inseam',
    'outseam': 'Trouser Length',
    'sleeve': 'Sleeve Length',
    'bicep': 'Bicep Round',
    'wrist': 'Wrist Round',
    'thigh': 'Thigh Round',
    'calf': 'Calf Round',
    'ankle': 'Ankle Round',

    // Derived measurements (returned by estimate)
    'chest_to_waist_drop': 'Chest to Waist Drop',
    'waist_to_hip_drop': 'Waist to Hip Drop',

    // Extended keys (may be returned by full extraction)
    'chest_circumference': 'Chest Round',
    'waist_circumference': 'Waist Round',
    'hip_circumference': 'Hip Round',
    'shoulder_width': 'Shoulder',
    'neck_circumference': 'Neck Round',
    'thigh_circumference': 'Thigh Round',
    'knee_circumference': 'Knee Round',
    'calf_circumference': 'Calf Round',
    'ankle_circumference': 'Ankle Round',
    'inside_leg_length': 'Inseam',
    'crotch_length': 'Crotch Depth',
    'waist_to_hip_length': 'Waist to Hip',
    'upper_hip_circumference': 'Upper Hip',
    'bust_circumference': 'Bust Round',
    'under_bust_circumference': 'Under Bust',
    'across_back_width': 'Across Back',
    'across_chest_width': 'Across Chest',
    'armhole_circumference': 'Armhole Round',
    'sleeve_length': 'Sleeve Length',
    'bicep_circumference': 'Bicep Round',
    'elbow_circumference': 'Elbow Round',
    'wrist_circumference': 'Wrist Round',
    'front_waist_length': 'Front Waist Length',
    'back_waist_length': 'Back Waist Length',
    'full_top_length': 'Full Top Length',
    'half_length': 'Half Length',
    'trouser_length': 'Trouser Length',
    'trouser_waist': 'Trouser Waist',
  };

  /// Map a single Korra key to a Desby UI label
  static String mapToLabel(String korraKey) {
    return korraToDesby[korraKey] ?? korraKey.split('_').map((word) {
      if (word.isEmpty) return "";
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  /// Map raw API results to a label-indexed map
  static Map<String, double> mapResults(Map<String, double> rawResults) {
    final Map<String, double> mapped = {};
    rawResults.forEach((key, value) {
      // Skip metadata keys that aren't actual measurements
      if (key == 'height') return;
      mapped[mapToLabel(key)] = value;
    });
    return mapped;
  }
}
