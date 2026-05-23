
/// Manages interaction with the model's rig/bones or overlays.
/// Part of Step 4.1: Rig Interaction Layer.
class RigInteractionLayer {
  final Map<String, List<String>> _segmentBones;
  
  RigInteractionLayer({
    required Map<String, List<String>> segmentBones,
  }) : _segmentBones = segmentBones;

  List<String> getBonesForSegment(String segmentId) {
    return _segmentBones[segmentId] ?? [];
  }

  // Step 7: Define highlight modes (bone, mesh, overlay)
  String getHighlightMode(String segmentId) {
    return 'overlay'; // Default fallback until bone access is verified
  }
}
