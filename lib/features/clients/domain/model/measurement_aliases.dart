import 'measurement_key.dart';

/// Alias mapping from UI-facing labels to canonical keys.
/// Part of Step 5: Canonical Dictionary Contract - Alias Policy.
class MeasurementAlias {
  final String alias;
  final String canonicalKey;
  final String? family;

  const MeasurementAlias({
    required this.alias,
    required this.canonicalKey,
    this.family,
  });
}

/// Complete alias registry following Section 5.2 policy:
/// - aliases point to exactly one canonical key
/// - no ambiguity
class MeasurementAliasRegistry {
  MeasurementAliasRegistry._();

  /// All aliases - maps UI labels to canonical keys
  static const List<MeasurementAlias> aliases = [
    // Upper Body aliases
    MeasurementAlias(alias: 'shoulder_width', canonicalKey: MeasurementKey.shoulder, family: 'upper_body'),
    MeasurementAlias(alias: 'shoulder', canonicalKey: MeasurementKey.shoulder, family: 'upper_body'),
    MeasurementAlias(alias: 'neck', canonicalKey: MeasurementKey.neckRound, family: 'upper_body'),
    MeasurementAlias(alias: 'neck_circumference', canonicalKey: MeasurementKey.neckRound, family: 'upper_body'),
    MeasurementAlias(alias: 'neck_round', canonicalKey: MeasurementKey.neckRound, family: 'upper_body'),
    MeasurementAlias(alias: 'bust', canonicalKey: MeasurementKey.bustRound, family: 'upper_body'),
    MeasurementAlias(alias: 'bust_circumference', canonicalKey: MeasurementKey.bustRound, family: 'upper_body'),
    MeasurementAlias(alias: 'bust_round', canonicalKey: MeasurementKey.bustRound, family: 'upper_body'),
    MeasurementAlias(alias: 'chest', canonicalKey: MeasurementKey.chestRound, family: 'upper_body'),
    MeasurementAlias(alias: 'chest_circumference', canonicalKey: MeasurementKey.chestRound, family: 'upper_body'),
    MeasurementAlias(alias: 'chest_round', canonicalKey: MeasurementKey.chestRound, family: 'upper_body'),
    MeasurementAlias(alias: 'high_bust', canonicalKey: MeasurementKey.highBust, family: 'upper_body'),
    MeasurementAlias(alias: 'under_bust', canonicalKey: MeasurementKey.underBust, family: 'upper_body'),
    MeasurementAlias(alias: 'bust_point', canonicalKey: MeasurementKey.bustPoint, family: 'upper_body'),
    MeasurementAlias(alias: 'shoulder_to_bust_point', canonicalKey: MeasurementKey.shoulderToBustPoint, family: 'upper_body'),
    MeasurementAlias(alias: 'shoulder_to_under_bust', canonicalKey: MeasurementKey.shoulderToUnderBust, family: 'upper_body'),
    MeasurementAlias(alias: 'across_chest', canonicalKey: MeasurementKey.acrossChest, family: 'upper_body'),
    MeasurementAlias(alias: 'across_back', canonicalKey: MeasurementKey.acrossBack, family: 'upper_body'),
    MeasurementAlias(alias: 'armhole', canonicalKey: MeasurementKey.armholeRound, family: 'upper_body'),
    MeasurementAlias(alias: 'armhole_round', canonicalKey: MeasurementKey.armholeRound, family: 'upper_body'),

    // Sleeve measurements
    MeasurementAlias(alias: 'sleeve', canonicalKey: MeasurementKey.sleeveLength, family: 'upper_body'),
    MeasurementAlias(alias: 'sleeve_length', canonicalKey: MeasurementKey.sleeveLength, family: 'upper_body'),
    MeasurementAlias(alias: 'bicep', canonicalKey: MeasurementKey.bicepRound, family: 'upper_body'),
    MeasurementAlias(alias: 'bicep_round', canonicalKey: MeasurementKey.bicepRound, family: 'upper_body'),
    MeasurementAlias(alias: 'elbow', canonicalKey: MeasurementKey.elbowRound, family: 'upper_body'),
    MeasurementAlias(alias: 'elbow_round', canonicalKey: MeasurementKey.elbowRound, family: 'upper_body'),
    MeasurementAlias(alias: 'wrist', canonicalKey: MeasurementKey.wristRound, family: 'upper_body'),
    MeasurementAlias(alias: 'wrist_round', canonicalKey: MeasurementKey.wristRound, family: 'upper_body'),

    // Torso & Waist
    MeasurementAlias(alias: 'shoulder_to_waist', canonicalKey: MeasurementKey.shoulderToWaist, family: 'torso'),
    MeasurementAlias(alias: 'front_waist', canonicalKey: MeasurementKey.frontWaistLength, family: 'torso'),
    MeasurementAlias(alias: 'front_waist_length', canonicalKey: MeasurementKey.frontWaistLength, family: 'torso'),
    MeasurementAlias(alias: 'back_waist', canonicalKey: MeasurementKey.backWaistLength, family: 'torso'),
    MeasurementAlias(alias: 'back_waist_length', canonicalKey: MeasurementKey.backWaistLength, family: 'torso'),
    MeasurementAlias(alias: 'waist', canonicalKey: MeasurementKey.waistRound, family: 'torso'),
    MeasurementAlias(alias: 'waist_circumference', canonicalKey: MeasurementKey.waistRound, family: 'torso'),
    MeasurementAlias(alias: 'waist_round', canonicalKey: MeasurementKey.waistRound, family: 'torso'),
    MeasurementAlias(alias: 'half', canonicalKey: MeasurementKey.halfLength, family: 'torso'),
    MeasurementAlias(alias: 'half_length', canonicalKey: MeasurementKey.halfLength, family: 'torso'),
    MeasurementAlias(alias: 'stomach', canonicalKey: MeasurementKey.stomachRound, family: 'torso'),
    MeasurementAlias(alias: 'stomach_round', canonicalKey: MeasurementKey.stomachRound, family: 'torso'),

    // Hip & Legs
    MeasurementAlias(alias: 'waist_to_hip', canonicalKey: MeasurementKey.waistToHip, family: 'hip_legs'),
    MeasurementAlias(alias: 'upper_hip', canonicalKey: MeasurementKey.upperHip, family: 'hip_legs'),
    MeasurementAlias(alias: 'hip', canonicalKey: MeasurementKey.hipRound, family: 'hip_legs'),
    MeasurementAlias(alias: 'hip_circumference', canonicalKey: MeasurementKey.hipRound, family: 'hip_legs'),
    MeasurementAlias(alias: 'hip_round', canonicalKey: MeasurementKey.hipRound, family: 'hip_legs'),
    MeasurementAlias(alias: 'thigh', canonicalKey: MeasurementKey.thighRound, family: 'hip_legs'),
    MeasurementAlias(alias: 'thigh_circumference', canonicalKey: MeasurementKey.thighRound, family: 'hip_legs'),
    MeasurementAlias(alias: 'thigh_round', canonicalKey: MeasurementKey.thighRound, family: 'hip_legs'),
    MeasurementAlias(alias: 'knee', canonicalKey: MeasurementKey.kneeRound, family: 'hip_legs'),
    MeasurementAlias(alias: 'knee_round', canonicalKey: MeasurementKey.kneeRound, family: 'hip_legs'),
    MeasurementAlias(alias: 'calf', canonicalKey: MeasurementKey.calfRound, family: 'hip_legs'),
    MeasurementAlias(alias: 'calf_round', canonicalKey: MeasurementKey.calfRound, family: 'hip_legs'),
    MeasurementAlias(alias: 'ankle', canonicalKey: MeasurementKey.ankleRound, family: 'hip_legs'),
    MeasurementAlias(alias: 'ankle_round', canonicalKey: MeasurementKey.ankleRound, family: 'hip_legs'),
    MeasurementAlias(alias: 'waist_to_knee', canonicalKey: MeasurementKey.waistToKnee, family: 'hip_legs'),
    MeasurementAlias(alias: 'waist_to_calf', canonicalKey: MeasurementKey.waistToCalf, family: 'hip_legs'),
    MeasurementAlias(alias: 'waist_to_floor', canonicalKey: MeasurementKey.waistToFloor, family: 'hip_legs'),

    // Garment Specific
    MeasurementAlias(alias: 'full_dress', canonicalKey: MeasurementKey.fullDressLength, family: 'garment_specific'),
    MeasurementAlias(alias: 'full_dress_length', canonicalKey: MeasurementKey.fullDressLength, family: 'garment_specific'),
    MeasurementAlias(alias: 'skirt', canonicalKey: MeasurementKey.skirtLength, family: 'garment_specific'),
    MeasurementAlias(alias: 'skirt_length', canonicalKey: MeasurementKey.skirtLength, family: 'garment_specific'),
    MeasurementAlias(alias: 'wrapper', canonicalKey: MeasurementKey.wrapperLength, family: 'garment_specific'),
    MeasurementAlias(alias: 'wrapper_length', canonicalKey: MeasurementKey.wrapperLength, family: 'garment_specific'),
    MeasurementAlias(alias: 'senator', canonicalKey: MeasurementKey.senatorLength, family: 'garment_specific'),
    MeasurementAlias(alias: 'senator_length', canonicalKey: MeasurementKey.senatorLength, family: 'garment_specific'),
    MeasurementAlias(alias: 'kaftan', canonicalKey: MeasurementKey.kaftanLength, family: 'garment_specific'),
    MeasurementAlias(alias: 'kaftan_length', canonicalKey: MeasurementKey.kaftanLength, family: 'garment_specific'),
    MeasurementAlias(alias: 'agbada', canonicalKey: MeasurementKey.agbadaLength, family: 'garment_specific'),
    MeasurementAlias(alias: 'agbada_length', canonicalKey: MeasurementKey.agbadaLength, family: 'garment_specific'),
    MeasurementAlias(alias: 'agbada_sleeve', canonicalKey: MeasurementKey.agbadaSleeveLength, family: 'garment_specific'),
    MeasurementAlias(alias: 'agbada_sleeve_length', canonicalKey: MeasurementKey.agbadaSleeveLength, family: 'garment_specific'),
    MeasurementAlias(alias: 'jacket', canonicalKey: MeasurementKey.jacketLength, family: 'garment_specific'),
    MeasurementAlias(alias: 'jacket_length', canonicalKey: MeasurementKey.jacketLength, family: 'garment_specific'),
    MeasurementAlias(alias: 'lapel', canonicalKey: MeasurementKey.lapelWidth, family: 'garment_specific'),
    MeasurementAlias(alias: 'lapel_width', canonicalKey: MeasurementKey.lapelWidth, family: 'garment_specific'),
    MeasurementAlias(alias: 'jacket_sleeve', canonicalKey: MeasurementKey.jacketSleeveLength, family: 'garment_specific'),
    MeasurementAlias(alias: 'jacket_sleeve_length', canonicalKey: MeasurementKey.jacketSleeveLength, family: 'garment_specific'),
    MeasurementAlias(alias: 'vest', canonicalKey: MeasurementKey.vestLength, family: 'garment_specific'),
    MeasurementAlias(alias: 'vest_length', canonicalKey: MeasurementKey.vestLength, family: 'garment_specific'),
    MeasurementAlias(alias: 'shirt', canonicalKey: MeasurementKey.shirtLength, family: 'garment_specific'),
    MeasurementAlias(alias: 'shirt_length', canonicalKey: MeasurementKey.shirtLength, family: 'garment_specific'),
    MeasurementAlias(alias: 'full_top', canonicalKey: MeasurementKey.fullTopLength, family: 'garment_specific'),
    MeasurementAlias(alias: 'full_top_length', canonicalKey: MeasurementKey.fullTopLength, family: 'garment_specific'),

    // Trouser measurements
    MeasurementAlias(alias: 'trouser_waist', canonicalKey: MeasurementKey.trouserWaist, family: 'hip_legs'),
    MeasurementAlias(alias: 'trouser_length', canonicalKey: MeasurementKey.trouserLength, family: 'hip_legs'),
    MeasurementAlias(alias: 'inseam', canonicalKey: MeasurementKey.inseam, family: 'hip_legs'),
    MeasurementAlias(alias: 'crotch', canonicalKey: MeasurementKey.crotchDepth, family: 'hip_legs'),
    MeasurementAlias(alias: 'crotch_depth', canonicalKey: MeasurementKey.crotchDepth, family: 'hip_legs'),
    MeasurementAlias(alias: 'rise', canonicalKey: MeasurementKey.rise, family: 'hip_legs'),
    MeasurementAlias(alias: 'seat', canonicalKey: MeasurementKey.seatRound, family: 'hip_legs'),
    MeasurementAlias(alias: 'seat_round', canonicalKey: MeasurementKey.seatRound, family: 'hip_legs'),
    MeasurementAlias(alias: 'trouser_opening', canonicalKey: MeasurementKey.trouserOpeningWidth, family: 'hip_legs'),
    MeasurementAlias(alias: 'trouser_opening_width', canonicalKey: MeasurementKey.trouserOpeningWidth, family: 'hip_legs'),

    // Corset/Female Specific
    MeasurementAlias(alias: 'corset_front', canonicalKey: MeasurementKey.corsetFrontLength, family: 'corset_female'),
    MeasurementAlias(alias: 'corset_front_length', canonicalKey: MeasurementKey.corsetFrontLength, family: 'corset_female'),
    MeasurementAlias(alias: 'corset_side', canonicalKey: MeasurementKey.corsetSideLength, family: 'corset_female'),
    MeasurementAlias(alias: 'corset_side_length', canonicalKey: MeasurementKey.corsetSideLength, family: 'corset_female'),
    MeasurementAlias(alias: 'corset_back', canonicalKey: MeasurementKey.corsetBackLength, family: 'corset_female'),
    MeasurementAlias(alias: 'corset_back_length', canonicalKey: MeasurementKey.corsetBackLength, family: 'corset_female'),
    MeasurementAlias(alias: 'under_bust_to_waist', canonicalKey: MeasurementKey.underBustToWaist, family: 'corset_female'),
    MeasurementAlias(alias: 'waist_to_lower_corset', canonicalKey: MeasurementKey.waistToLowerCorsetEdge, family: 'corset_female'),
    MeasurementAlias(alias: 'cup', canonicalKey: MeasurementKey.cupSize, family: 'corset_female'),
    MeasurementAlias(alias: 'cup_size', canonicalKey: MeasurementKey.cupSize, family: 'corset_female'),
  ];

  /// Get all unique canonical keys that have at least one alias
  static Set<String> get canonicalKeysWithAliases {
    return aliases.map((a) => a.canonicalKey).toSet();
  }

  /// Get family for a given measurement key
  static String? getFamilyForKey(String key) {
    final alias = aliases.where((a) => a.canonicalKey == key).firstOrNull;
    return alias?.family;
  }
}
