import 'dart:async';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../../../../theme/colors.dart';

class AiCameraCapturePage extends StatefulWidget {
  final String perspective; // 'front' or 'side'
  const AiCameraCapturePage({super.key, required this.perspective});
  @override
  State<AiCameraCapturePage> createState() => _AiCameraCapturePageState();
}

class _AiCameraCapturePageState extends State<AiCameraCapturePage> {
  CameraController? _cameraController;
  PoseDetector? _poseDetector;
  final FlutterTts _tts = FlutterTts();
  bool _isProcessing = false;
  bool _isAligned = false;
  DateTime? _alignmentStartTime;
  Uint8List? _capturedImageBytes;
  bool _isReviewing = false;
  String _statusMessage = 'Initializing camera...';
  Map<PoseLandmarkType, PoseLandmark> _currentLandmarks = {};

  String _lastSpokenText = '';
  DateTime? _lastSpokenTime;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initPoseDetector();
    }
    _initTts();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() => _statusMessage = 'No camera found on this device.');
        }
        return;
      }
      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      debugPrint('[CAMERA] Found camera: ${backCamera.name}');
      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      debugPrint('[CAMERA] Camera initialized');
      if (!kIsWeb && mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
        try {
          await _cameraController!.startImageStream(_processCameraImage);
          debugPrint('[CAMERA] Image stream started');
        } catch (e) {
          debugPrint('[CAMERA] startImageStream error: $e');
        }
      }
      if (mounted) setState(() {});
      if (kIsWeb) {
        setState(() {
          _statusMessage = widget.perspective == 'front'
              ? 'Stand facing the camera. Tap to capture.'
              : 'Turn sideways to the camera. Tap to capture.';
        });
      } else {
        _speakStepGuidance();
      }
    } catch (e, stack) {
      debugPrint('[CAMERA] Init error: $e');
      debugPrint('[CAMERA] Stack: $stack');
      if (mounted) {
        setState(() {
          _statusMessage = 'Camera error: ${e.toString()}';
        });
      }
    }
  }

  void _initPoseDetector() {
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
      ),
    );
  }

  Future<void> _initTts() async {
    if (kIsWeb) return;
    try {
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
    } catch (e) {
      debugPrint('[CAMERA] TTS init error: $e');
    }
  }

  void _speakStepGuidance() {
    if (widget.perspective == 'front') {
      _speakFeedback(
          'Stand facing the camera. Spread your arms in an A-shape. Keep your head and feet visible.');
    } else {
      _speakFeedback(
          'Turn sideways to the camera. Show your full profile. Keep your head and feet visible.');
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing || _isReviewing || _capturedImageBytes != null) return;
    _isProcessing = true;

    try {
      final imageFormat = defaultTargetPlatform == TargetPlatform.iOS
          ? InputImageFormat.bgra8888
          : InputImageFormat.nv21;

      final inputImage = InputImage.fromBytes(
        bytes: _concatenatePlanes(image.planes),
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation90deg,
          format: imageFormat,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      final poses = await _poseDetector!.processImage(inputImage);
      if (poses.isNotEmpty && mounted) {
        final pose = poses.first;
        final landmarks = pose.landmarks;

        setState(() {
          _currentLandmarks = landmarks;
          _validatePose(landmarks);
        });
      } else if (mounted) {
        setState(() {
          _statusMessage = 'Searching for you...';
          _isAligned = false;
          _alignmentStartTime = null;
        });
      }
    } catch (e) {
      debugPrint('[CAMERA] Pose detection error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final allBytes = WriteBuffer();
    for (final plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  void _validatePose(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    // Landmarks map directly: PoseLandmarkType enum index == MediaPipe index
    final head = landmarks[PoseLandmarkType.nose];
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = landmarks[PoseLandmarkType.rightAnkle];
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    final leftWrist = landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = landmarks[PoseLandmarkType.rightWrist];
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];

    bool aligned = true;
    String feedback = 'Hold steady...';

    // Visibility check: head and feet must be visible (Korra: visibility < 0.5)
    if (head == null ||
        leftAnkle == null ||
        rightAnkle == null ||
        head.likelihood < 0.5 ||
        leftAnkle.likelihood < 0.5 ||
        rightAnkle.likelihood < 0.5) {
      feedback = 'Step back: Head and feet must be visible.';
      aligned = false;
    } else if (widget.perspective == 'front') {
      // Front view A-pose check (Korra logic)
      final bool handsDown = leftWrist != null &&
          rightWrist != null &&
          leftShoulder != null &&
          rightShoulder != null &&
          leftWrist.y > leftShoulder.y &&
          rightWrist.y > rightShoulder.y;

      if (!handsDown) {
        feedback = 'A-POSE: Move arms down.';
        aligned = false;
      } else if (leftHip == null ||
          rightHip == null ||
          (leftWrist.x - leftHip.x).abs() < 0.15 ||
          (rightWrist.x - rightHip.x).abs() < 0.15) {
        feedback = 'A-POSE: Spread arms.';
        aligned = false;
      }
    } else if (widget.perspective == 'side') {
      // Side view check (Korra yaw estimation logic)
      final bool bothShouldersVisible = leftShoulder != null &&
          rightShoulder != null &&
          leftShoulder.likelihood > 0.5 &&
          rightShoulder.likelihood > 0.5 &&
          leftHip != null;

      if (leftShoulder != null && rightShoulder != null && leftHip != null) {
        final double xDelta =
            (leftShoulder.x - rightShoulder.x).abs();
        final double yDelta =
            (leftShoulder.y - leftHip.y).abs();
        final double sideRatio = yDelta > 0 ? xDelta / yDelta : 1.0;

        if (bothShouldersVisible) {
          final double zDelta =
              (leftShoulder.z - rightShoulder.z).abs();
          final double yawRad = atan2(zDelta, xDelta);
          if (yawRad < 1.45 || sideRatio >= 0.1) {
            feedback = 'Turn Side: Face fully side.';
            aligned = false;
          }
        } else if (sideRatio > 0.1) {
          feedback = 'Turn Side: Face fully side.';
          aligned = false;
        }
      }
    }

    // Auto-capture logic: 1.5s alignment timer
    if (aligned) {
      if (_alignmentStartTime == null) {
        _alignmentStartTime = DateTime.now();
        _speakFeedback('Hold still.', force: true);
      } else {
        final elapsed = DateTime.now().difference(_alignmentStartTime!);
        if (elapsed.inMilliseconds >= 1500) {
          _capturePhoto();
          return;
        }
        final remainingMs = max(0, 1500 - elapsed.inMilliseconds);
        feedback = remainingMs > 0
            ? 'Capturing in ${(remainingMs / 1000).toStringAsFixed(1)}s...'
            : 'Processing...';
      }
    } else {
      _alignmentStartTime = null;
      _speakFeedback(feedback);
    }

    _statusMessage = feedback;
    _isAligned = aligned;
  }

  Future<void> _speakFeedback(String text, {bool force = false}) async {
    if (kIsWeb) return;
    final now = DateTime.now();
    if (!force &&
        text == _lastSpokenText &&
        _lastSpokenTime != null &&
        now.difference(_lastSpokenTime!).inSeconds < 3) {
      return;
    }
    if (!force) {
      final speaking = await _tts.awaitSpeakCompletion(true);
      if (speaking) return;
    }
    if (force) await _tts.stop();
    await _tts.speak(text);
    _lastSpokenText = text;
    _lastSpokenTime = now;
  }

  Future<void> _capturePhoto() async {
    if (_isReviewing || _capturedImageBytes != null) return;

    HapticFeedback.heavyImpact();
    await _speakFeedback('Captured.', force: true);

    try {
      final XFile file = await _cameraController!.takePicture();
      final bytes = await file.readAsBytes();
      setState(() {
        _capturedImageBytes = bytes;
        _isReviewing = true;
      });
    } catch (e) {
      setState(() => _statusMessage = 'Capture failed: $e');
    }
  }

  void _retakePhoto() {
    setState(() {
      _isReviewing = false;
      _capturedImageBytes = null;
      _alignmentStartTime = null;
    });
  }

  void _keepPhoto() {
    Navigator.pop(context, _capturedImageBytes);
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      try {
        _cameraController?.stopImageStream();
      } catch (_) {}
    }
    _cameraController?.dispose();
    try {
      _poseDetector?.close();
    } catch (_) {}
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_statusMessage != 'Initializing camera...')
                Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  foregroundColor: Colors.black,
                ),
                child: const Text('GO BACK'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          CameraPreview(_cameraController!),

          // Skeleton + silhouette overlay
          if (!_isReviewing && _currentLandmarks.isNotEmpty)
            CustomPaint(
              size: Size.infinite,
              painter: _SkeletonPainter(
                landmarks: _currentLandmarks,
                isAligned: _isAligned,
                perspective: widget.perspective,
              ),
            ),

          // Top status message
          Positioned(
            top: 60,
            left: 24,
            right: 24,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: _isAligned
                    ? const Color(0xFF76FF03)
                    : Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: _isAligned
                      ? const Color(0xFF76FF03)
                      : Colors.white.withValues(alpha: 0.1),
                  width: 2,
                ),
              ),
              child: Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _isAligned ? Colors.black : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.05,
                ),
              ),
            ),
          ),

          // Close button
          Positioned(
            top: 40,
            right: 24,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1)),
                ),
                child:
                    const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),

          // Review mode overlay
          if (_isReviewing && _capturedImageBytes != null)
            Positioned.fill(
              child: Container(
                color: Colors.black,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(_capturedImageBytes!, fit: BoxFit.cover),
                    Positioned(
                      bottom: 40,
                      left: 24,
                      right: 24,
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _retakePhoto,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white
                                    .withValues(alpha: 0.1),
                                foregroundColor: Colors.white,
                                side: const BorderSide(
                                    color: Colors.white24),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'RECAPTURE',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _keepPhoto,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.amber,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'KEEP PHOTO',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Shutter button
          if (!_isReviewing)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _capturePhoto,
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: _isAligned
                              ? const Color(0xFF76FF03)
                              : AppColors.amber,
                          width: 6),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isAligned
                                ? const Color(0xFF76FF03)
                                : Colors.white
                                    .withValues(alpha: 0.2),
                          ),
                        ),
                        if (_isAligned)
                          SizedBox(
                            width: 84,
                            height: 84,
                            child: CircularProgressIndicator(
                              value: _alignmentStartTime != null
                                  ? min(
                                      1.0,
                                      DateTime.now()
                                              .difference(
                                                  _alignmentStartTime!)
                                              .inMilliseconds /
                                          1500.0,
                                    )
                                  : 0.0,
                              strokeWidth: 3,
                              color: const Color(0xFF76FF03),
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SkeletonPainter extends CustomPainter {
  final Map<PoseLandmarkType, PoseLandmark> landmarks;
  final bool isAligned;
  final String perspective;

  _SkeletonPainter({
    required this.landmarks,
    required this.isAligned,
    required this.perspective,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final clr = isAligned ? const Color(0xFF76FF03) : Colors.white;

    final strokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final markerPaint = Paint()
      ..color = clr
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = clr
      ..strokeWidth = isAligned ? 7 : 5
      ..strokeCap = StrokeCap.round;

    // Draw silhouette guide (dashed) behind skeleton
    _drawSilhouette(canvas, size, isAligned);

    // 31 skeleton connections matching Korra exactly
    // Indices 0-32 map to PoseLandmarkType.values
    final connections = [
      // Face
      [0, 1], [1, 2], [2, 3], [3, 7], [0, 4], [4, 5], [5, 6], [6, 8],
      [9, 10], [0, 9], [0, 10],
      // Torso
      [11, 12], [11, 23], [12, 24], [23, 24],
      // Arms
      [11, 13], [13, 15], [12, 14], [14, 16],
      // Hands
      [15, 17], [15, 19], [15, 21], [17, 19],
      [16, 18], [16, 20], [16, 22], [18, 20],
      // Legs
      [23, 25], [25, 27], [27, 29], [29, 31], [27, 31],
      [24, 26], [26, 28], [28, 30], [30, 32], [28, 32],
    ];

    for (final conn in connections) {
      final p1 = landmarks[PoseLandmarkType.values[conn[0]]];
      final p2 = landmarks[PoseLandmarkType.values[conn[1]]];
      if (p1 != null &&
          p2 != null &&
          p1.likelihood > 0.5 &&
          p2.likelihood > 0.5) {
        canvas.drawLine(
          Offset(p1.x * size.width, p1.y * size.height),
          Offset(p2.x * size.width, p2.y * size.height),
          linePaint,
        );
      }
    }

    // Draw joint nodes on ALL visible landmarks (matching Korra)
    for (final type in PoseLandmarkType.values) {
      final lm = landmarks[type];
      if (lm != null && lm.likelihood > 0.5) {
        final center = Offset(lm.x * size.width, lm.y * size.height);
        canvas.drawCircle(center, 5, markerPaint);
        canvas.drawCircle(center, 5, strokePaint);
      }
    }
  }

  void _drawSilhouette(Canvas canvas, Size size, bool isAligned) {
    final paint = Paint()
      ..color = isAligned
          ? const Color(0x4D76FF03) // rgba(118,255,3,0.3)
          : const Color(0x1AFFFFFF) // rgba(255,255,255,0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;

    final path = Path()
      // Head to left shoulder
      ..moveTo(cx, cy - size.height * 0.4)
      ..lineTo(cx - size.width * 0.1, cy - size.height * 0.2)
      // Left shoulder to left hand
      ..lineTo(cx - size.width * 0.2, cy + size.height * 0.1)
      // Head to right shoulder
      ..moveTo(cx, cy - size.height * 0.4)
      ..lineTo(cx + size.width * 0.1, cy - size.height * 0.2)
      // Right shoulder to right hand
      ..lineTo(cx + size.width * 0.2, cy + size.height * 0.1)
      // Torso: neck to hip
      ..moveTo(cx, cy - size.height * 0.2)
      ..lineTo(cx, cy + size.height * 0.1)
      // Left leg
      ..lineTo(cx - size.width * 0.1, cy + size.height * 0.4)
      // Right leg
      ..moveTo(cx, cy + size.height * 0.1)
      ..lineTo(cx + size.width * 0.1, cy + size.height * 0.4);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SkeletonPainter oldDelegate) {
    return oldDelegate.isAligned != isAligned ||
        oldDelegate.landmarks != landmarks;
  }
}
