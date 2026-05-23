import '../../domain/model/measurement_key.dart';

/// Implements Section 9: Full Measurement Mapping Matrix (Canonical Families)
///
/// Provides canonical family groupings and validates all measurement keys
/// are covered by the focus registry.

/// Canonical family categories per Section 9
enum MeasurementFamily {
  upperBody('upper_body', 'Upper Body'),
  torso('torso', 'Torso & Waist'),
  hipLegs('hip_legs', 'Hip & Legs'),
  garmentSpecific('garment_specific', 'Garment Specific'),
  corsetFemale('corset_female', 'Corset/Female Specific');

  final String id;
  final String displayName;
  const MeasurementFamily(this.id, this.displayName);
}

/// Measurement to family mapping per Section 9
class MeasurementMappingRegistry {
  MeasurementMappingRegistry._();

  /// Section 9.1: Upper Body measurements
  static const Map<String, MeasurementFamily> upperBody = {
    MeasurementKey.shoulder: MeasurementFamily.upperBody,
    MeasurementKey.neckRound: MeasurementFamily.upperBody,
    MeasurementKey.bustRound: MeasurementFamily.upperBody,
    MeasurementKey.chestRound: MeasurementFamily.upperBody,
    MeasurementKey.highBust: MeasurementFamily.upperBody,
    MeasurementKey.underBust: MeasurementFamily.upperBody,
    MeasurementKey.bustPoint: MeasurementFamily.upperBody,
    MeasurementKey.acrossChest: MeasurementFamily.upperBody,
    MeasurementKey.acrossBack: MeasurementFamily.upperBody,
    MeasurementKey.armholeRound: MeasurementFamily.upperBody,
  };

  /// Section 9.2: Torso & Waist measurements
  static const Map<String, MeasurementFamily> torso = {
    MeasurementKey.shoulderToWaist: MeasurementFamily.torso,
    MeasurementKey.frontWaistLength: MeasurementFamily.torso,
    MeasurementKey.backWaistLength: MeasurementFamily.torso,
    MeasurementKey.waistRound: MeasurementFamily.torso,
    MeasurementKey.stomachRound: MeasurementFamily.torso,
    MeasurementKey.halfLength: MeasurementFamily.torso,
  };

  /// Section 9.3: Hip & Legs measurements
  static const Map<String, MeasurementFamily> hipLegs = {
    MeasurementKey.waistToHip: MeasurementFamily.hipLegs,
    MeasurementKey.upperHip: MeasurementFamily.hipLegs,
    MeasurementKey.hipRound: MeasurementFamily.hipLegs,
    MeasurementKey.thighRound: MeasurementFamily.hipLegs,
    MeasurementKey.kneeRound: MeasurementFamily.hipLegs,
    MeasurementKey.calfRound: MeasurementFamily.hipLegs,
    MeasurementKey.ankleRound: MeasurementFamily.hipLegs,
    MeasurementKey.waistToKnee: MeasurementFamily.hipLegs,
    MeasurementKey.waistToCalf: MeasurementFamily.hipLegs,
    MeasurementKey.waistToFloor: MeasurementFamily.hipLegs,
    MeasurementKey.trouserWaist: MeasurementFamily.hipLegs,
    MeasurementKey.trouserLength: MeasurementFamily.hipLegs,
    MeasurementKey.inseam: MeasurementFamily.hipLegs,
    MeasurementKey.crotchDepth: MeasurementFamily.hipLegs,
    MeasurementKey.rise: MeasurementFamily.hipLegs,
    MeasurementKey.seatRound: MeasurementFamily.hipLegs,
    MeasurementKey.trouserOpeningWidth: MeasurementFamily.hipLegs,
  };

  /// Section 9.4: Garment Specific measurements
  static const Map<String, MeasurementFamily> garmentSpecific = {
    MeasurementKey.senatorLength: MeasurementFamily.garmentSpecific,
    MeasurementKey.kaftanLength: MeasurementFamily.garmentSpecific,
    MeasurementKey.agbadaLength: MeasurementFamily.garmentSpecific,
    MeasurementKey.agbadaSleeveLength: MeasurementFamily.garmentSpecific,
    MeasurementKey.jacketLength: MeasurementFamily.garmentSpecific,
    MeasurementKey.lapelWidth: MeasurementFamily.garmentSpecific,
    MeasurementKey.jacketSleeveLength: MeasurementFamily.garmentSpecific,
    MeasurementKey.vestLength: MeasurementFamily.garmentSpecific,
    MeasurementKey.shirtLength: MeasurementFamily.garmentSpecific,
    MeasurementKey.fullTopLength: MeasurementFamily.garmentSpecific,
  };

  /// Section 9.5: Corset/Female Specific measurements
  static const Map<String, MeasurementFamily> corsetFemale = {
    MeasurementKey.corsetFrontLength: MeasurementFamily.corsetFemale,
    MeasurementKey.corsetSideLength: MeasurementFamily.corsetFemale,
    MeasurementKey.corsetBackLength: MeasurementFamily.corsetFemale,
    MeasurementKey.underBustToWaist: MeasurementFamily.corsetFemale,
    MeasurementKey.waistToLowerCorsetEdge: MeasurementFamily.corsetFemale,
    MeasurementKey.cupSize: MeasurementFamily.corsetFemale,
  };

  /// Combined mapping for all families
  static Map<String, MeasurementFamily> get allMappings => {
        ...upperBody,
        ...torso,
        ...hipLegs,
        ...garmentSpecific,
        ...corsetFemale,
      };

  /// Get family for a measurement key
  static MeasurementFamily? getFamily(String measurementKey) {
    return allMappings[measurementKey];
  }

  /// Get all measurement keys for a family
  static List<String> getKeysForFamily(MeasurementFamily family) {
    switch (family) {
      case MeasurementFamily.upperBody:
        return upperBody.keys.toList();
      case MeasurementFamily.torso:
        return torso.keys.toList();
      case MeasurementFamily.hipLegs:
        return hipLegs.keys.toList();
      case MeasurementFamily.garmentSpecific:
        return garmentSpecific.keys.toList();
      case MeasurementFamily.corsetFemale:
        return corsetFemale.keys.toList();
    }
  }

  /// Verify all keys from MeasurementKey are mapped
  static List<String> getUnmappedKeys() {
    final allKeys = <String>[
      MeasurementKey.shoulder,
      MeasurementKey.neckRound,
      MeasurementKey.bustRound,
      MeasurementKey.chestRound,
      MeasurementKey.highBust,
      MeasurementKey.underBust,
      MeasurementKey.bustPoint,
      MeasurementKey.shoulderToBustPoint,
      MeasurementKey.shoulderToUnderBust,
      MeasurementKey.shoulderToWaist,
      MeasurementKey.frontWaistLength,
      MeasurementKey.backWaistLength,
      MeasurementKey.acrossChest,
      MeasurementKey.acrossBack,
      MeasurementKey.armholeRound,
      MeasurementKey.sleeveLength,
      MeasurementKey.bicepRound,
      MeasurementKey.elbowRound,
      MeasurementKey.wristRound,
      MeasurementKey.waistRound,
      MeasurementKey.halfLength,
      MeasurementKey.waistToHip,
      MeasurementKey.upperHip,
      MeasurementKey.hipRound,
      MeasurementKey.thighRound,
      MeasurementKey.kneeRound,
      MeasurementKey.calfRound,
      MeasurementKey.ankleRound,
      MeasurementKey.waistToKnee,
      MeasurementKey.waistToCalf,
      MeasurementKey.waistToFloor,
      MeasurementKey.fullDressLength,
      MeasurementKey.skirtLength,
      MeasurementKey.wrapperLength,
      MeasurementKey.corsetFrontLength,
      MeasurementKey.corsetSideLength,
      MeasurementKey.corsetBackLength,
      MeasurementKey.underBustToWaist,
      MeasurementKey.waistToLowerCorsetEdge,
      MeasurementKey.cupSize,
      MeasurementKey.stomachRound,
      MeasurementKey.fullTopLength,
      MeasurementKey.shirtLength,
      MeasurementKey.trouserWaist,
      MeasurementKey.trouserLength,
      MeasurementKey.inseam,
      MeasurementKey.crotchDepth,
      MeasurementKey.rise,
      MeasurementKey.seatRound,
      MeasurementKey.senatorLength,
      MeasurementKey.kaftanLength,
      MeasurementKey.agbadaLength,
      MeasurementKey.agbadaSleeveLength,
      MeasurementKey.jacketLength,
      MeasurementKey.lapelWidth,
      MeasurementKey.jacketSleeveLength,
      MeasurementKey.vestLength,
      MeasurementKey.fallback,
    ];

    return allKeys.where((key) => !allMappings.containsKey(key)).toList();
  }

  /// Get family counts for reporting
  static Map<MeasurementFamily, int> getFamilyCounts() {
    return {
      MeasurementFamily.upperBody: upperBody.length,
      MeasurementFamily.torso: torso.length,
      MeasurementFamily.hipLegs: hipLegs.length,
      MeasurementFamily.garmentSpecific: garmentSpecific.length,
      MeasurementFamily.corsetFemale: corsetFemale.length,
    };
  }

  /// Total count
  static int get totalCount => allMappings.length;

  /// Validation: all keys should be mapped?
  static bool get isFullyMapped => getUnmappedKeys().isEmpty;
}
