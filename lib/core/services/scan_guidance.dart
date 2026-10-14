/// Canonical spoken guidance for the body scan flow.
///
/// The scan guidance used to live inline in each page, which let the two drift
/// apart: the setup page told the user to keep their arms *relaxed at their
/// sides* while the capture screen told them to *spread their arms*, and both
/// talked about a "capture button" that does not exist on the upload path. The
/// capture screen then rejected the instruction it had just given. Every string spoken during a scan now comes from here, so
/// the wording matches the page it is spoken on and matches the pose the
/// detector actually accepts.
class ScanGuidance {
  ScanGuidance._();

  /// The capture screen validates a T-pose, and that is the neutral pose SMPL
  /// measurements are taken in, so guidance must describe one. The detector
  /// previously demanded an A-pose and rejected this instruction on screen.
  static const poseFront =
      'Stand facing the camera and raise both arms straight out to the sides, '
      'level with your shoulders, in the shape of a T. '
      'Keep your head, hands and feet inside the frame.';

  static const poseSide =
      'Turn to face the side. Stand sideways with your arms at your sides '
      'and show your full profile. Keep your head, hands and feet inside the frame.';

  static const holdStill = 'Hold still.';

  /// Shown while the alignment timer runs. Spoken once, not per frame.
  static const alignThenCapture = 'Great, hold that pose. Capturing now.';

  /// Setup screen, before a mode is chosen.
  static const chooseMethod =
      'You need one front photo and one side photo. '
      'Use your camera, or upload photos you already took.';

  static const modeCamera =
      'Camera selected. Stand in the T-pose and we will guide you through '
      'the front and side photos.';

  static const modeUpload =
      'Upload selected. Choose a front photo and a side photo from your '
      'gallery. Stand in the T-pose in both.';

  /// Upload path has no shutter button, so guidance describes choosing a photo.
  static const uploadFront =
      'Choose your front photo. Stand in the T-pose with your whole body in '
      'frame.';

  static const uploadSide =
      'Now choose your side photo. Stand sideways with your whole body in '
      'frame.';

  static const heightPrompt =
      'Enter your height so the measurements can be scaled to you.';

  static const processing =
      'Working out your measurements. This usually takes a few seconds.';

  static const done =
      'All done. Your measurements are ready.';

  static const failed =
      'That did not work. Please try the scan again.';

  static const photoAdded = 'Photo added.';

  static const captured = 'Captured.';

  static const voiceOn = 'Voice guidance on.';

  static const voiceOff = 'Voice guidance off.';

  /// Alignment correction, kept short so it stays useful while the user is
  /// holding a pose.
  static String alignmentCorrection(String feedback) => feedback;
}