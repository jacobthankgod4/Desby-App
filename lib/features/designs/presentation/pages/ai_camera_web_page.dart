import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:js_util' as js_util;
import 'dart:math';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../theme/colors.dart';

class AiCameraWebPage extends StatefulWidget {
  final String perspective;
  const AiCameraWebPage({super.key, required this.perspective});
  @override
  State<AiCameraWebPage> createState() => _AiCameraWebPageState();
}

class _AiCameraWebPageState extends State<AiCameraWebPage>
    with SingleTickerProviderStateMixin {
  late final String _viewType;
  html.VideoElement? _video;
  bool _cameraReady = false;
  bool _poseReady = false;
  bool _isAligned = false;
  DateTime? _alignmentStartTime;
  Uint8List? _capturedImageBytes;
  bool _isReviewing = false;
  String _statusMessage = 'Initializing camera...';
  List<_Landmark> _landmarks = [];
  Timer? _frameTimer;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _viewType = 'cam-${DateTime.now().millisecondsSinceEpoch}';
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _video = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..setAttribute('playsinline', '')
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';

      // ignore: undefined_prefixed_name
      ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
        return _video!;
      });

      final stream = await html.window.navigator.mediaDevices!
          .getUserMedia({'video': true});

      _video!.srcObject = stream;
      _video!.style.pointerEvents = 'none';
      await _video!.play();

      if (mounted) setState(() => _cameraReady = true);

      // Store video element for JS access
      js.context['__cameraVideo'] = _video;

      // Initialize MediaPipe PoseLandmarker
      _initPoseDetection();
    } catch (e, stack) {
      debugPrint('[CAMERA WEB] Init error: $e');
      debugPrint('[CAMERA WEB] Stack: $stack');
      if (mounted) {
        setState(() => _statusMessage = 'Camera error: $e');
      }
    }
  }

  Future<void> _initPoseDetection() async {
    debugPrint('[MEDIAPIPE] Waiting for pose detection to initialize...');
    if (mounted) {
      setState(() {
        _statusMessage = 'Loading pose detection...';
      });
    }

    // JS module self-initializes MediaPipe on load — just poll __mpReady
    for (var i = 0; i < 300; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      final ready = js.context['__mpReady'];
      if (ready == true) break;
    }

    _poseReady = js.context['__mpReady'] == true;
    if (_poseReady) {
      debugPrint('[MEDIAPIPE] Pose detection initialized');
      if (mounted) {
        setState(() {
          _statusMessage = widget.perspective == 'front'
              ? 'Stand facing the camera. Spread arms in A-shape.'
              : 'Turn sideways. Show full profile.';
        });
        _startFrameLoop();
      }
    } else {
      debugPrint('[MEDIAPIPE] Init timeout — using manual capture');
      if (mounted) {
        setState(() => _statusMessage = 'Tap to capture when ready.');
      }
    }
  }

  void _startFrameLoop() {
    _frameTimer = Timer.periodic(const Duration(milliseconds: 66), (_) {
      if (!_cameraReady || !_poseReady || _isReviewing || _capturedImageBytes != null) return;
      _processFrame();
    });
  }

  void _processFrame() {
    try {
      final raw = js.context.callMethod('detectPose', []);
      if (raw == null) return;

      final results = js_util.dartify(raw);
      final landmarksList = results as List?;
      if (landmarksList == null || landmarksList.isEmpty) {
        if (mounted && !_isReviewing && _capturedImageBytes == null) {
          setState(() {
            _statusMessage = 'Searching for you...';
            _isAligned = false;
            _alignmentStartTime = null;
          });
        }
        return;
      }

      final lmList = landmarksList
          .map((lm) => _Landmark(
                x: (lm as Map)['x']?.toDouble() ?? 0,
                y: lm['y']?.toDouble() ?? 0,
                z: lm['z']?.toDouble() ?? 0,
                visibility: lm['visibility']?.toDouble() ?? 0,
              ))
          .toList();

      if (mounted && !_isReviewing && _capturedImageBytes == null) {
        setState(() {
          _landmarks = lmList;
          _validatePose(lmList);
        });
      }
    } catch (e) {
      debugPrint('[MEDIAPIPE] Frame error: $e');
    }
  }

  // ─── Exact Korra pose validation algorithm ────────────────────────────────

  void _validatePose(List<_Landmark> lm) {
    if (lm.length < 33) return;

    final head = lm[0]; // nose
    final leftAnkle = lm[27]; // left_ankle
    final rightAnkle = lm[28]; // right_ankle
    final leftShoulder = lm[11]; // left_shoulder
    final rightShoulder = lm[12]; // right_shoulder
    final leftWrist = lm[15]; // left_wrist
    final rightWrist = lm[16]; // right_wrist
    final leftHip = lm[23]; // left_hip
    final rightHip = lm[24]; // right_hip

    bool aligned = true;
    String feedback = 'Hold steady...';

    // Visibility check: head and feet must be visible (Korra: visibility < 0.5)
    if (head.visibility < 0.5 ||
        leftAnkle.visibility < 0.5 ||
        rightAnkle.visibility < 0.5) {
      feedback = 'Step back: Head and feet must be visible.';
      aligned = false;
    } else if (widget.perspective == 'front') {
      // Front view A-pose check (Korra logic)
      final bool handsDown = leftWrist.visibility > 0.5 &&
          rightWrist.visibility > 0.5 &&
          leftShoulder.visibility > 0.5 &&
          rightShoulder.visibility > 0.5 &&
          leftWrist.y > leftShoulder.y &&
          rightWrist.y > rightShoulder.y;

      if (!handsDown) {
        feedback = 'A-POSE: Move arms down.';
        aligned = false;
      } else if (leftHip.visibility < 0.5 ||
          rightHip.visibility < 0.5 ||
          (leftWrist.x - leftHip.x).abs() < 0.15 ||
          (rightWrist.x - rightHip.x).abs() < 0.15) {
        feedback = 'A-POSE: Spread arms.';
        aligned = false;
      }
    } else if (widget.perspective == 'side') {
      // Side view check (Korra yaw estimation logic)
      final bool bothShouldersVisible = leftShoulder.visibility > 0.5 &&
          rightShoulder.visibility > 0.5 &&
          leftHip.visibility > 0.5;

      if (leftShoulder.visibility > 0.5 &&
          rightShoulder.visibility > 0.5 &&
          leftHip.visibility > 0.5) {
        final double xDelta = (leftShoulder.x - rightShoulder.x).abs();
        final double yDelta = (leftShoulder.y - leftHip.y).abs();
        final double sideRatio = yDelta > 0 ? xDelta / yDelta : 1.0;

        if (bothShouldersVisible) {
          final double zDelta = (leftShoulder.z - rightShoulder.z).abs();
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

    // Auto-capture logic: 1.5s alignment timer (Korra)
    if (aligned) {
      if (_alignmentStartTime == null) {
        _alignmentStartTime = DateTime.now();
        _progressController.forward(from: 0);
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
        _progressController.value = elapsed.inMilliseconds / 1500.0;
      }
    } else {
      _alignmentStartTime = null;
      _progressController.reset();
    }

    _statusMessage = feedback;
    _isAligned = aligned;
  }

  // ─── Capture ──────────────────────────────────────────────────────────────

  Future<void> _capturePhoto() async {
    if (_isReviewing || _capturedImageBytes != null || _video == null) return;

    HapticFeedback.heavyImpact();

    try {
      final video = _video!;
      final width = video.videoWidth;
      final height = video.videoHeight;

      final canvas = html.CanvasElement(width: width, height: height);
      canvas.context2D.drawImage(video, 0, 0);

      final blob = await canvas.toBlob('image/jpeg', 0.9);

      final reader = html.FileReader();
      final bytesFuture = Completer<Uint8List>();
      reader.onLoad.listen((_) {
        final buffer = reader.result as Uint8List;
        bytesFuture.complete(buffer);
      });
      reader.readAsArrayBuffer(blob);
      final bytes = await bytesFuture.future;

      if (bytes.isEmpty) return;

      setState(() {
        _capturedImageBytes = bytes;
        _isReviewing = true;
        _statusMessage = 'Photo captured!';
        _alignmentStartTime = null;
        _progressController.reset();
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
      _isAligned = false;
    });
    _progressController.reset();
  }

  void _keepPhoto() {
    Navigator.pop(context, _capturedImageBytes);
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    _progressController.dispose();
    _video?.srcObject = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraReady) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_statusMessage != 'Initializing camera...')
                const Icon(Icons.error_outline, color: AppColors.error, size: 48),
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
          // Video preview
          Positioned.fill(child: HtmlElementView(viewType: _viewType)),

          // Skeleton overlay (same as mobile Korra)
          if (!_isReviewing && _landmarks.length >= 33)
            Positioned.fill(
              child: CustomPaint(
                painter: _WebSkeletonPainter(
                  landmarks: _landmarks,
                  isAligned: _isAligned,
                ),
              ),
            ),

          // Status bar
          Positioned(
            top: 60,
            left: 24,
            right: 24,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: _isAligned ? const Color(0xFF76FF03) : Colors.black.withAlpha(200),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: _isAligned ? const Color(0xFF76FF03) : Colors.white.withAlpha(25),
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
                  color: Colors.black.withAlpha(150),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),

          // Review mode
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
                                backgroundColor: Colors.white.withAlpha(25),
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white24),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text('RECAPTURE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
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
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text('KEEP PHOTO', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Shutter button with progress ring
          if (!_isReviewing)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _capturePhoto,
                  child: SizedBox(
                    width: 84,
                    height: 84,
                    child: AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, child) {
                        return CircularProgressIndicator(
                          value: _progressController.value,
                          strokeWidth: 3,
                          color: const Color(0xFF76FF03),
                          backgroundColor: Colors.transparent,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

          // Silhouette guide overlay
          if (!_isReviewing)
            Positioned.fill(
              child: CustomPaint(
                painter: _SilhouetteGuidePainter(isAligned: _isAligned),
              ),
            ),
        ],
      ),
    );
  }
}

class _Landmark {
  final double x, y, z, visibility;
  _Landmark({required this.x, required this.y, required this.z, required this.visibility});
}

// ─── Exact same skeleton painter as mobile Korra ──────────────────────────

class _WebSkeletonPainter extends CustomPainter {
  final List<_Landmark> landmarks;
  final bool isAligned;

  _WebSkeletonPainter({
    required this.landmarks,
    required this.isAligned,
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

    // 31 skeleton connections matching Korra exactly
    // MediaPipe PoseLandmarker indices 0-32 = same as ML Kit PoseLandmarkType
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
      if (conn[0] < landmarks.length && conn[1] < landmarks.length) {
        final p1 = landmarks[conn[0]];
        final p2 = landmarks[conn[1]];
        if (p1.visibility > 0.5 && p2.visibility > 0.5) {
          canvas.drawLine(
            Offset(p1.x * size.width, p1.y * size.height),
            Offset(p2.x * size.width, p2.y * size.height),
            linePaint,
          );
        }
      }
    }

    // Draw joint nodes on ALL visible landmarks (matching Korra)
    for (var i = 0; i < landmarks.length; i++) {
      final lm = landmarks[i];
      if (lm.visibility > 0.5) {
        final center = Offset(lm.x * size.width, lm.y * size.height);
        canvas.drawCircle(center, 5, markerPaint);
        canvas.drawCircle(center, 5, strokePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WebSkeletonPainter oldDelegate) {
    return oldDelegate.isAligned != isAligned ||
        oldDelegate.landmarks != landmarks;
  }
}

// ─── Silhouette guide (same as mobile) ────────────────────────────────────

class _SilhouetteGuidePainter extends CustomPainter {
  final bool isAligned;
  _SilhouetteGuidePainter({required this.isAligned});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isAligned ? const Color(0x4D76FF03) : const Color(0x1AFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;

    final path = Path()
      ..moveTo(cx, cy - size.height * 0.4)
      ..lineTo(cx - size.width * 0.1, cy - size.height * 0.2)
      ..lineTo(cx - size.width * 0.2, cy + size.height * 0.1)
      ..moveTo(cx, cy - size.height * 0.4)
      ..lineTo(cx + size.width * 0.1, cy - size.height * 0.2)
      ..lineTo(cx + size.width * 0.2, cy + size.height * 0.1)
      ..moveTo(cx, cy - size.height * 0.2)
      ..lineTo(cx, cy + size.height * 0.1)
      ..lineTo(cx - size.width * 0.1, cy + size.height * 0.4)
      ..moveTo(cx, cy + size.height * 0.1)
      ..lineTo(cx + size.width * 0.1, cy + size.height * 0.4);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SilhouetteGuidePainter oldDelegate) {
    return oldDelegate.isAligned != isAligned;
  }
}
