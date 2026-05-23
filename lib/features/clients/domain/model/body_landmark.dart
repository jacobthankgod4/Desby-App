import 'focus_models.dart';

/// Implements Section 7: Rig Metadata Contract
///
/// Defines the minimum fields per body segment:
/// - segmentId (e.g., SEG_NECK, SEG_CHEST, SEG_WAIST)
/// - boneNames[] (if available)
/// - landmarkIds[]
/// - preferredView
/// - highlightMode (bone, mesh, overlay)
/// - priority (for multi-segment measurements)

/// Segment IDs for body regions
enum SegmentId {
  // Upper body
  segNeck('neck'),
  segShoulderLeft('shoulder_left'),
  segShoulderRight('shoulder_right'),
  segChest('chest'),
  segUpperChest('upper_chest'),
  segBust('bust'),
  segUnderBust('under_bust'),
  segArmholeLeft('armhole_left'),
  segArmholeRight('armhole_right'),

  // Torso
  segWaist('waist'),
  segStomach('stomach'),
  segBack('back'),
  segSideLeft('side_left'),
  segSideRight('side_right'),

  // Hip & Pelvis
  segHip('hip'),
  segUpperHip('upper_hip'),
  segSeat('seat'),
  segCrotch('crotch'),

  // Arms
  segBicepLeft('bicep_left'),
  segBicepRight('bicep_right'),
  segElbowLeft('elbow_left'),
  segElbowRight('elbow_right'),
  segWristLeft('wrist_left'),
  segWristRight('wrist_right'),
  segForearmLeft('forearm_left'),
  segForearmRight('forearm_right'),

  // Legs
  segThighLeft('thigh_left'),
  segThighRight('thigh_right'),
  segKneeLeft('knee_left'),
  segKneeRight('knee_right'),
  segCalfLeft('calf_left'),
  segCalfRight('calf_right'),
  segAnkleLeft('ankle_left'),
  segAnkleRight('ankle_right'),

  // Full body
  segFullTorso('full_torso'),
  segFullLegLeft('full_leg_left'),
  segFullLegRight('full_leg_right');

  final String value;
  const SegmentId(this.value);
}

/// Highlight mode for segments
enum HighlightMode {
  bone, // Use actual bone highlighting (if supported)
  mesh, // Use mesh shading
  overlay, // Use overlay markers (fallback)
}

/// Preferred viewing angle for each segment
enum PreferredView {
  front,
  back,
  left,
  right,
  oblique,
  auto,
}

/// Rig metadata for a single segment
class SegmentMetadata {
  final SegmentId segmentId;
  final List<String> boneNames;
  final List<String> landmarkIds;
  final PreferredView preferredView;
  final HighlightMode highlightMode;
  final int priority;

  const SegmentMetadata({
    required this.segmentId,
    this.boneNames = const [],
    this.landmarkIds = const [],
    this.preferredView = PreferredView.auto,
    this.highlightMode = HighlightMode.overlay,
    this.priority = 0,
  });
}

/// Body landmark with 3D position
class BodyLandmark {
  final String id;
  final double x;
  final double y;
  final double z;
  final SegmentId? segmentId;

  const BodyLandmark({
    required this.id,
    required this.x,
    required this.y,
    required this.z,
    this.segmentId,
  });

  /// Convert to FocusTarget format
  FocusTarget toFocusTarget() {
    return FocusTarget(x, y, z);
  }
}

/// Rig metadata registry
class RigMetadataRegistry {
  RigMetadataRegistry._();

  /// All segment metadata definitions
  static const Map<SegmentId, SegmentMetadata> segments = {
    // Upper body segments
    SegmentId.segNeck: SegmentMetadata(
      segmentId: SegmentId.segNeck,
      boneNames: ['neck_joint'],
      landmarkIds: ['neck_front', 'neck_back'],
      preferredView: PreferredView.front,
      highlightMode: HighlightMode.overlay,
      priority: 10,
    ),
    SegmentId.segChest: SegmentMetadata(
      segmentId: SegmentId.segChest,
      boneNames: ['spine_mid'],
      landmarkIds: ['chest_left', 'chest_right', 'chest_center'],
      preferredView: PreferredView.front,
      highlightMode: HighlightMode.overlay,
      priority: 8,
    ),
    SegmentId.segBust: SegmentMetadata(
      segmentId: SegmentId.segBust,
      landmarkIds: ['bust_point_l', 'bust_point_r'],
      preferredView: PreferredView.front,
      highlightMode: HighlightMode.overlay,
      priority: 9,
    ),
    SegmentId.segUnderBust: SegmentMetadata(
      segmentId: SegmentId.segUnderBust,
      landmarkIds: ['under_bust_l', 'under_bust_r'],
      preferredView: PreferredView.front,
      highlightMode: HighlightMode.overlay,
      priority: 9,
    ),
    SegmentId.segWaist: SegmentMetadata(
      segmentId: SegmentId.segWaist,
      boneNames: ['spine_lower'],
      landmarkIds: ['waist_front', 'waist_back', 'waist_left', 'waist_right'],
      preferredView: PreferredView.front,
      highlightMode: HighlightMode.overlay,
      priority: 7,
    ),
    SegmentId.segHip: SegmentMetadata(
      segmentId: SegmentId.segHip,
      boneNames: ['hip_l', 'hip_r'],
      landmarkIds: ['hip_left', 'hip_right', 'hip_front', 'hip_back'],
      preferredView: PreferredView.front,
      highlightMode: HighlightMode.overlay,
      priority: 6,
    ),
    SegmentId.segThighLeft: SegmentMetadata(
      segmentId: SegmentId.segThighLeft,
      boneNames: ['thigh_l'],
      landmarkIds: ['thigh_upper_l', 'thigh_lower_l'],
      preferredView: PreferredView.front,
      highlightMode: HighlightMode.overlay,
      priority: 5,
    ),
    SegmentId.segKneeLeft: SegmentMetadata(
      segmentId: SegmentId.segKneeLeft,
      boneNames: ['knee_l'],
      landmarkIds: ['knee_l'],
      preferredView: PreferredView.front,
      highlightMode: HighlightMode.overlay,
      priority: 4,
    ),
    SegmentId.segAnkleLeft: SegmentMetadata(
      segmentId: SegmentId.segAnkleLeft,
      boneNames: ['ankle_l'],
      landmarkIds: ['ankle_l'],
      preferredView: PreferredView.front,
      highlightMode: HighlightMode.overlay,
      priority: 3,
    ),
  };

  /// Get metadata for a segment
  static SegmentMetadata? getMetadata(SegmentId id) => segments[id];

  /// Get metadata for a measurement key
  static SegmentId? getSegmentForMeasurement(String measurementKey) {
    const mapping = <String, SegmentId>{
      'neck_round': SegmentId.segNeck,
      'shoulder': SegmentId.segShoulderLeft,
      'bust_round': SegmentId.segBust,
      'high_bust': SegmentId.segUpperChest,
      'under_bust': SegmentId.segUnderBust,
      'chest_round': SegmentId.segChest,
      'waist_round': SegmentId.segWaist,
      'stomach_round': SegmentId.segStomach,
      'hip_round': SegmentId.segHip,
      'upper_hip': SegmentId.segUpperHip,
      'thigh_round': SegmentId.segThighLeft,
      'knee_round': SegmentId.segKneeLeft,
      'calf_round': SegmentId.segCalfLeft,
      'ankle_round': SegmentId.segAnkleLeft,
      'back_waist_length': SegmentId.segBack,
      'front_waist_length': SegmentId.segWaist,
    };
    return mapping[measurementKey] ?? SegmentId.segFullTorso;
  }
}
