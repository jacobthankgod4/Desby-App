import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/tts_service.dart';
import '../../../../core/services/scan_guidance.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/body_measurement_service.dart';
import '../../../../core/network/korra_client.dart';
import '../../../../theme/colors.dart';
import 'package:image_picker/image_picker.dart';

import 'ai_camera_capture_page.dart';
import 'ai_camera_web_page.dart';
import '../../../../core/widgets/shell_scope.dart';

class AiBodyScanPage extends ConsumerStatefulWidget {
  const AiBodyScanPage({
    super.key,
    this.onMeasurementsReady,
    this.inFlow = false,
    this.expanded = false,
    this.onToggleExpanded,
  });

  /// When set, measurements are handed back through this callback on save
  /// instead of being written to `body_scans` by this page.
  final void Function(
    Map<String, dynamic> measurements,
    String gender,
    double heightCm,
  )? onMeasurementsReady;

  /// Hosted inside another page's layout: render without our own app bar so the
  /// host's header stays the only chrome.
  final bool inFlow;

  /// The host has given the scan the full screen.
  final bool expanded;

  /// Lets the embedded scan ask the host to collapse it again.
  final VoidCallback? onToggleExpanded;

  @override
  ConsumerState<AiBodyScanPage> createState() => _AiBodyScanPageState();
}

/// Where the client's photos come from. Chosen before the camera is touched.
enum _CaptureMode { camera, upload }

class _AiBodyScanPageState extends ConsumerState<AiBodyScanPage>
    with TickerProviderStateMixin {
  final BodyMeasurementService _service = BodyMeasurementService();

  Uint8List? _frontImage;
  Uint8List? _sideImage;
  double _heightCm = 170.0;
  String _gender = 'male';
  bool _isProcessing = false;
  String? _errorMessage;
  Map<String, double>? _measurements;
  String _accuracyDescription = 'Professional accuracy (±1-3cm)';
  int _currentStep = 0;
  List<KorraMeasurementSummary> _scanHistory = [];
  bool _voiceEnabled = true;

  late AnimationController _stepController;
  late AnimationController _resultsController;
  late AnimationController _pulseController;
  late AnimationController _processingController;

  Timer? _processingTimer;
  int _processingSeconds = 0;

  bool _showCelebration = false;

  /// How the client wants their photos taken. Null until they choose.
  ///
  /// Opening straight into a live camera asked for a permission prompt before
  /// anyone had agreed to use the camera, and left no obvious way to say "I
  /// already have pictures". Choosing first also lets the primary button on the
  /// photo steps match the choice instead of offering the camera with an upload
  /// buried underneath it.
  _CaptureMode? _captureMode;

  void _chooseCaptureMode(_CaptureMode mode) {
    setState(() => _captureMode = mode);
    _speak(mode == _CaptureMode.camera
        ? ScanGuidance.modeCamera
        : ScanGuidance.modeUpload);
  }

  /// Flip the method from inside a photo step without losing progress.
  void _switchCaptureMode(_CaptureMode mode) {
    if (_captureMode == mode) return;
    setState(() => _captureMode = mode);
  }

  void _resetScan() {
    setState(() {
      _currentStep = 0;
      _measurements = null;
      _frontImage = null;
      _sideImage = null;
      _errorMessage = null;
      _showCelebration = false;
      _captureMode = null;
    });
  }

  static const Map<String, String> _measurementLabels = {
    'neck': 'NECK',
    'shoulder': 'SHOULDER',
    'chest': 'CHEST',
    'waist': 'WAIST',
    'hip': 'HIP',
    'inseam': 'INSEAM',
    'outseam': 'OUTSEAM',
    'thigh': 'THIGH',
    'bicep': 'BICEP',
    'wrist': 'WRIST',
    'bust': 'BUST',
    'underbust': 'UNDERBUST',
    'arm_length': 'ARM LENGTH',
    'torso': 'TORSO',
    'shoulder_width': 'SHOULDER WIDTH',
    'back_width': 'BACK WIDTH',
  };

  @override
  void initState() {
    super.initState();

    _stepController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _resultsController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _processingController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _pulseController.repeat(reverse: true);
    _processingController.repeat();

    _stepController.forward();
    _loadScanHistory();
    _initTts();
    _speakStepGuidance(0);
    _checkExistingMeasurements();
  }

  @override
  void dispose() {
    _stepController.dispose();
    _resultsController.dispose();
    _pulseController.dispose();
    _processingController.dispose();
    _processingTimer?.cancel();
    TtsService.instance.stop();
    _service.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // VOICE GUIDANCE
  // ---------------------------------------------------------------------------

  Future<void> _initTts() async {
    await TtsService.instance.configure();
  }

  /// Check if the user already has a saved scan in the database.
  /// If yes, auto-populate measurements and jump to the results step.
  /// If no, show the normal scan interface.
  Future<void> _checkExistingMeasurements() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final tailorId = user.id;

    try {
      final response = await Supabase.instance.client
          .from('body_scans')
          .select('id, measurements, created_at, front_image_url, side_image_url, metadata')
          .eq('tailor_id', tailorId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        // No existing measurements found — start normal scan flow
        debugPrint('[SCAN] No existing measurements found — starting fresh scan');
        if (!mounted) return;
        setState(() {
          _currentStep = 0;
        });
        return;
      }

      // ✅ Existing measurements found — auto-populate
      debugPrint('[SCAN] Found existing measurement from ${response['created_at']} — auto-populating');

      final measurements = response['measurements'];
      final metadata = response['metadata'] ?? {};

      setState(() {
        _measurements = measurements;
        _heightCm = metadata['height_cm'] ?? 170.0;
        _accuracyDescription =
            metadata['accuracy'] ?? 'Professional accuracy (±1-3cm)';
        _gender = metadata['gender'] ?? 'male';
        _currentStep = 4; // Jump directly to results step
        _isProcessing = false;
      });

      // Show the celebration banner (green "EXTRACTION SUCCESSFUL" banner)
      setState(() => _showCelebration = true);
      _resultsController.forward();
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _showCelebration = false);
      });
    } catch (e) {
      debugPrint('[SCAN] Failed to check existing measurements: $e');
      if (!mounted) return;
      // On error, fall back to normal scan flow
      if (!mounted) return;
      setState(() {
        _currentStep = 0;
      });
    }
  }

  Future<void> _speak(String text, {bool force = false}) async {
    if (!_voiceEnabled) return;
    await TtsService.instance.speak(text, force: force);
  }

  /// Spoken guidance for the current step.
  ///
  /// The upload path has no shutter button, so it must not tell the user to
  /// press one — it tells them to choose a photo instead. Both paths describe
  /// the same A-pose the capture screen validates.
  void _speakStepGuidance(int step) {
    final usingUpload = _captureMode == _CaptureMode.upload;
    switch (step) {
      case 0:
        _speak(usingUpload ? ScanGuidance.uploadFront : ScanGuidance.poseFront);
        break;
      case 1:
        _speak(usingUpload ? ScanGuidance.uploadSide : ScanGuidance.poseSide);
        break;
      case 2:
        _speak(ScanGuidance.heightPrompt);
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // COUNTDOWN & CAPTURE
  // ---------------------------------------------------------------------------
  Future<void> _startCountdownAndCapture(String perspective) async {
    HapticFeedback.selectionClick();
    await _speak(ScanGuidance.poseFront, force: true);
    _capturePhoto(perspective);
  }
  /// Lets the user supply a photo from their gallery instead of the camera.
  ///
  /// The measurement pipeline only needs two full-body JPEGs, so an existing
  /// photo is equivalent to a fresh capture. Not everyone can pose and shoot
  /// themselves in one go, and re-taking a photo to satisfy the flow is the
  /// single most common reason people abandon the scan step.
  Future<void> _uploadPhoto(String perspective) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        // Downscaling keeps the upload light; HMR resizes internally anyway.
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 90,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (!mounted) return;

      HapticFeedback.heavyImpact();
      setState(() {
        if (perspective == 'front') {
          _frontImage = bytes;
        } else {
          _sideImage = bytes;
        }
      });
      await _speak(ScanGuidance.photoAdded);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Could not open that photo: $e');
    }
  }

  Future<void> _capturePhoto(String perspective) async {
    try {
      Uint8List? imageBytes;

      final cameraPage = kIsWeb
          ? AiCameraWebPage(perspective: perspective)
          : AiCameraCapturePage(perspective: perspective);

      imageBytes = await Navigator.push<Uint8List>(
        context,
        MaterialPageRoute(builder: (_) => cameraPage),
      );

      if (imageBytes != null) {
        HapticFeedback.heavyImpact();
        setState(() {
          if (perspective == 'front') {
            _frontImage = imageBytes;
          } else {
            _sideImage = imageBytes;
          }
        });
        await _speak(ScanGuidance.captured);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to capture photo: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // DATA
  // ---------------------------------------------------------------------------

  Future<void> _loadScanHistory() async {
    try {
      _scanHistory = await _service.listMeasurements();
    } catch (e) {
      debugPrint('[SCAN] Failed to load history: $e');
    }
    if (mounted) setState(() {});
  }

  void _transitionToStep(int step) {
    _stepController.reset();
    setState(() => _currentStep = step);
    _stepController.forward();
    if (step < 3) _speakStepGuidance(step);
  }

  Future<void> _processMeasurements() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _processingSeconds = 0;
      _currentStep = 3;
    });
    _speak(ScanGuidance.processing);
    _processingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _processingSeconds++);
    });
    try {
      BodyMeasurementResult result;
      if (_frontImage != null && _sideImage != null) {
        result = await _service.extractMeasurements(
          frontImageBytes: _frontImage!,
          sideImageBytes: _sideImage!,
          heightCm: _heightCm,
          gender: _gender,
        );
      } else {
        result = BodyMeasurementResult.error('Missing required photos');
      }
      if (result.success && result.measurements != null) {
        setState(() {
          _measurements = result.measurements;
          _accuracyDescription = result.accuracyDescription;
          _isProcessing = false;
        });
        _processingTimer?.cancel();
        _transitionToStep(4);
        _resultsController.forward();
        _loadScanHistory();
        await _speak(ScanGuidance.done, force: true);
        setState(() => _showCelebration = true);
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) setState(() => _showCelebration = false);
        });
      } else {
        _processingTimer?.cancel();
        setState(() {
          _errorMessage = result.error ?? 'Failed to process';
          _isProcessing = false;
        });
        await _speak(ScanGuidance.failed, force: true);
      }
    } catch (e) {
      _processingTimer?.cancel();
      setState(() {
        _errorMessage = 'Error: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _saveMeasurements() async {
    HapticFeedback.selectionClick();
    final measurements = _measurements;
    if (measurements == null) return;

    final onReady = widget.onMeasurementsReady;
    if (onReady != null) {
      final payload = Map<String, dynamic>.from(measurements);
      onReady(payload, _gender, _heightCm);
      if (!widget.inFlow && mounted) {
        Navigator.pop(context, payload);
      }
      return;
    }

    bool saved = false;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.from('body_scans').insert({
          'tailor_id': user.id,
          'measurements': measurements,
          'client_gender': _gender,
          'metadata': {
            'gender': _gender,
            'height_cm': _heightCm,
            'accuracy': _accuracyDescription,
            'accuracy_mode': 'dual_photo',
            'measurement_count': measurements.length,
          },
        });
        saved = true;
      }
    } catch (e) {
      debugPrint('[SCAN] Failed to persist scan: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save measurements: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      Navigator.pop(context, saved ? measurements : null);
    }
  }

  void _showScanHistory() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkNavy,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'SCAN HISTORY',
                      style: TextStyle(
                        color: AppColors.amber,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  Text(
                    '${_scanHistory.length} scans',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white10, height: 1),
            Expanded(
              child: _scanHistory.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history,
                            color: Colors.white12,
                            size: 48,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No scans yet',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Complete your first scan to see history here',
                            style: TextStyle(
                              color: Colors.white24,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _scanHistory.length,
                      itemBuilder: (context, index) {
                        final scan = _scanHistory[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.amber.withAlpha(25),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  scan.gender == 'female'
                                      ? Icons.female
                                      : Icons.male,
                                  color: AppColors.amber,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${scan.gender ?? "Unknown"} • ${scan.heightCm?.toInt() ?? "?"}cm',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${scan.measurementCount ?? "?"} measurements • ${scan.accuracyMode ?? "dual"}',
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                scan.createdAt != null
                                    ? '${scan.createdAt!.day}/${scan.createdAt!.month}/${scan.createdAt!.year}'
                                    : '',
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canProceed() {
    if (_isProcessing) return false;
    // Before a method is chosen there is nothing to continue past.
    if (_captureMode == null) return false;
    switch (_currentStep) {
      case 0:
        return _frontImage != null;
      case 1:
        return _sideImage != null;
      case 2:
        return _heightCm >= 120 && _heightCm <= 220;
      default:
        return false;
    }
  }

  void _proceed() {
    HapticFeedback.selectionClick();
    if (_currentStep < 2) {
      _transitionToStep(_currentStep + 1);
    } else if (_currentStep == 2) {
      _processMeasurements();
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      appBar: widget.inFlow ? null : AppBar(
        backgroundColor: AppColors.darkNavy,
        elevation: 0,
        leading: ShellScope.isInside(context)
            ? null
            : IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
        title: const Text(
          'AI BODY SCAN',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_scanHistory.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.history, color: Colors.white70),
              onPressed: _showScanHistory,
            ),
          IconButton(
            icon: Icon(
              _voiceEnabled ? Icons.volume_up : Icons.volume_off,
              color: Colors.white70,
            ),
            onPressed: () {
              setState(() => _voiceEnabled = !_voiceEnabled);
              _speak(_voiceEnabled ? ScanGuidance.voiceOn : ScanGuidance.voiceOff);
            },
          ),
          if (_showCelebration)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                radius: 8,
                backgroundColor: AppColors.success,
                child: const Icon(
                  Icons.check,
                  size: 12,
                  color: AppColors.darkNavy,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              // The default layoutBuilder stacks children and sizes itself to
              // the largest one, handing each a *loose* height. The per-step
              // SingleChildScrollView then took the full content height instead
              // of the viewport height, so it had nothing to scroll and the
              // step could not be moved on a phone. StackFit.expand pins every
              // child to the available height, which is what a scroll view needs.
              layoutBuilder: (currentChild, previousChildren) => Stack(
                fit: StackFit.expand,
                alignment: Alignment.topCenter,
                children: <Widget>[
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              ),
              transitionBuilder: (child, animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.15, 0.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: _buildStepContent(),
            ),
          ),
        ],
      ),
      // bottomNavigationBar, not bottomSheet: a bottomSheet is free to paint
      // over the body, which is what buried the last control on a small phone.
      // bottomNavigationBar always reserves its own height, so the scrolling
      // area ends above it and nothing is ever hidden underneath.
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  // ---------------------------------------------------------------------------
  // PROGRESS INDICATOR
  // ---------------------------------------------------------------------------

  Widget _buildProgressIndicator() {
    const totalSteps = 4;
    // Nothing is finished until they have actually chosen how to take the
    // photos, otherwise the bar claimed progress they never made.
    final completedSteps = (_captureMode == null || _currentStep >= 4)
        ? 0
        : _currentStep;
    final showCollapse = widget.inFlow && widget.expanded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          if (showCollapse)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                tooltip: 'Collapse scan',
                icon: const Icon(
                  Icons.close_fullscreen,
                  color: Colors.white70,
                  size: 20,
                ),
                onPressed: widget.onToggleExpanded,
              ),
            ),
          ...List.generate(totalSteps, (index) {
            final isDone = index < completedSteps;
            final isActive = _captureMode != null &&
                index == completedSteps &&
                _currentStep < 4;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDone || isActive
                        ? AppColors.amber
                        : Colors.white.withAlpha(26),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP CONTENT
  // ---------------------------------------------------------------------------

  Widget _buildStepContent() {
    // Ask how they want to photograph themselves before anything else. The
    // camera is not opened, and no permission is requested, until they pick it.
    if (_captureMode == null && _measurements == null) {
      return _buildCaptureModeStep();
    }
    // ✅ If measurements already loaded from DB, jump to results step
    if (_measurements != null && _measurements!.isNotEmpty) {
      return _buildResultsStep();
    }
    switch (_currentStep) {
      case 0:
        return _buildFrontPhotoStep();
      case 1:
        return _buildSidePhotoStep();
      case 2:
        return _buildHeightInputStep();
      case 3:
        return _buildProcessingView();
      case 4:
        if (_errorMessage != null) return _buildErrorView();
        return _buildResultsStep();
      default:
        return _buildFrontPhotoStep();
    }
  }

  /// ---------------------------------------------------------------------------
  /// STEP -1: HOW DO YOU WANT TO SUPPLY YOUR PHOTOS
  /// ---------------------------------------------------------------------------

  Widget _buildCaptureModeStep() {
    return SingleChildScrollView(
      key: const ValueKey('capture_mode'),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'GET STARTED',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.amber,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'How should we take\nyour photos?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'You need one front photo and one side photo. Pick whichever is '
            'easier right now — you can switch later.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 28),
          _buildModeOption(
            icon: Icons.photo_camera_rounded,
            title: 'Use my camera',
            blurb: 'Take the photos now. Nothing is saved to your gallery.',
            onTap: () => _chooseCaptureMode(_CaptureMode.camera),
          ),
          const SizedBox(height: 12),
          _buildModeOption(
            icon: Icons.photo_library_rounded,
            title: 'Upload photos',
            blurb: 'Choose a front and a side photo you already took.',
            onTap: () => _chooseCaptureMode(_CaptureMode.upload),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 16, color: Colors.white38),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Stand in the T-pose with both arms out level with your shoulders, '
                  'whole body in frame. Measurements are accurate to about 1–3cm.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11.5,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeOption({
    required IconData icon,
    required String title,
    required String blurb,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppColors.amber, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      blurb,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.white38,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 0: FRONT PHOTO
  // ---------------------------------------------------------------------------

  Widget _buildFrontPhotoStep() {
    return SingleChildScrollView(
      key: const ValueKey('front_photo'),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'STEP 1 OF 3',
            style: TextStyle(
              color: AppColors.amber,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'FRONT PHOTO',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Stand facing the camera in the T-pose, arms straight out\nto the sides. Full body must be visible.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 32),
          _buildPhotoGuidance(
            image: _frontImage,
            label: 'FRONT',
            isFront: true,
          ),
          const SizedBox(height: 32),
          _buildPhotoAction('front'),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 1: SIDE PHOTO
  // ---------------------------------------------------------------------------

  Widget _buildSidePhotoStep() {
    return SingleChildScrollView(
      key: const ValueKey('side_photo'),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'STEP 2 OF 3',
            style: TextStyle(
              color: AppColors.amber,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'SIDE PHOTO',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Turn 90° to the side. Stand sideways\nto the camera with arms at your sides.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 32),
          _buildPhotoGuidance(
            image: _sideImage,
            label: 'SIDE',
            isFront: false,
          ),
          const SizedBox(height: 32),
          _buildPhotoAction('side'),
        ],
      ),
    );
  }

  /// Primary action for a photo step, driven by the method chosen up front.
  ///
  /// Whichever method they picked is the big obvious button; the other one is
  /// offered underneath as a secondary link, so the choice is a starting point
  /// rather than a trap.
  Widget _buildPhotoAction(String perspective) {
    final isFront = perspective == 'front';
    final hasImage = isFront ? _frontImage != null : _sideImage != null;
    final noun = isFront ? 'FRONT' : 'SIDE';
    final useCamera = _captureMode != _CaptureMode.upload;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () => useCamera
                ? _startCountdownAndCapture(perspective)
                : _uploadPhoto(perspective),
            icon: Icon(
              useCamera ? Icons.camera_alt_rounded : Icons.photo_library_rounded,
            ),
            label: Text(
              useCamera
                  ? (hasImage ? 'RECAPTURE $noun' : 'CAPTURE $noun PHOTO')
                  : (hasImage ? 'CHOOSE ANOTHER $noun PHOTO' : 'UPLOAD $noun PHOTO'),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amber,
              foregroundColor: AppColors.darkNavy,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildUploadAlternative(perspective),
      ],
    );
  }

  /// Secondary link that switches to the other method.
  ///
  /// It is a switch, not just an extra upload link: tapping it also flips which
  /// method is primary, so the client never ends up with a "Upload front photo"
  /// screen whose main button opens the camera again.
  Widget _buildUploadAlternative(String perspective) {
    final useCamera = _captureMode != _CaptureMode.upload;

    return TextButton.icon(
      onPressed: () => useCamera
          ? _switchCaptureMode(_CaptureMode.upload)
          : _switchCaptureMode(_CaptureMode.camera),
      icon: Icon(
        useCamera ? Icons.photo_library_outlined : Icons.camera_alt_outlined,
        size: 18,
      ),
      label: Text(
        useCamera
            ? 'Use photos from my gallery instead'
            : 'Use the camera instead',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.amber,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.amber,
        minimumSize: const Size(double.infinity, 44),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 2: HEIGHT INPUT
  // ---------------------------------------------------------------------------

  Widget _buildHeightInputStep() {
    return SingleChildScrollView(
      key: const ValueKey('height_input'),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'STEP 3 OF 3',
            style: TextStyle(
              color: AppColors.amber,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'YOUR HEIGHT',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Enter your height for accurate measurements.\nThis is required for scaling.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_heightCm.toInt()}',
                      style: const TextStyle(
                        color: AppColors.amber,
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        'CM',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppColors.amber,
                    inactiveTrackColor: Colors.white12,
                    thumbColor: AppColors.amber,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 10,
                    ),
                    overlayColor: AppColors.amber.withAlpha(40),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 20,
                    ),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _heightCm,
                    min: 120,
                    max: 220,
                    divisions: 100,
                    onChanged: (value) {
                      HapticFeedback.selectionClick();
                      setState(() => _heightCm = value);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '120 cm',
                      style: TextStyle(color: Colors.white24, fontSize: 11),
                    ),
                    Text(
                      '220 cm',
                      style: TextStyle(color: Colors.white24, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildGenderToggle('male', Icons.male, 'MALE'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGenderToggle('female', Icons.female, 'FEMALE'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderToggle(String value, IconData icon, String label) {
    final isSelected = _gender == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _gender = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.amber
              : Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.amber : Colors.white12,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.darkNavy : Colors.white54,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.darkNavy : Colors.white70,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PROCESSING VIEW
  // ---------------------------------------------------------------------------

  Widget _buildProcessingView() {
    return Center(
      key: const ValueKey('processing'),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _processingController,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(100, 100),
                  painter: _ProcessingRingPainter(
                    progress: _processingController.value,
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'PROCESSING PHOTOS...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${_processingSeconds}s elapsed',
              style: const TextStyle(
                color: AppColors.amber,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _accuracyDescription,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 40),
            _buildShimmerBar(0),
            const SizedBox(height: 8),
            _buildShimmerBar(1),
            const SizedBox(height: 8),
            _buildShimmerBar(2),
            const SizedBox(height: 8),
            _buildShimmerBar(3),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerBar(int index) {
    return AnimatedBuilder(
      animation: _processingController,
      builder: (context, child) {
        final offset = (_processingController.value + index * 0.25) % 1.0;
        return Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              colors: [
                Colors.white.withAlpha(5),
                AppColors.amber.withAlpha(40),
                Colors.white.withAlpha(5),
              ],
              stops: [
                (offset - 0.3).clamp(0.0, 1.0),
                offset,
                (offset + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // ERROR VIEW
  // ---------------------------------------------------------------------------

  Widget _buildErrorView() {
    return Center(
      key: const ValueKey('error'),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'SCAN FAILED',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'An unexpected error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _errorMessage = null;
                    _currentStep = 0;
                    _frontImage = null;
                    _sideImage = null;
                    _measurements = null;
                  });
                  _speakStepGuidance(0);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  foregroundColor: AppColors.darkNavy,
                ),
                child: const Text(
                  'TRY AGAIN',
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
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 4: RESULTS
  // ---------------------------------------------------------------------------

  Widget _buildResultsStep() {
    if (_measurements == null) {
      return _buildErrorView();
    }

    final entries = _measurements!.entries.toList();

    return SingleChildScrollView(
      key: const ValueKey('results'),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'SCAN COMPLETE',
            style: TextStyle(
              color: AppColors.amber,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'YOUR MEASUREMENTS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.success.withAlpha(25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.success.withAlpha(80)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  _accuracyDescription,
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_measurements!.length} measurements extracted',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 24),
          ...List.generate(entries.length, (index) {
            final entry = entries[index];
            return AnimatedBuilder(
              animation: _resultsController,
              builder: (context, child) {
                final delay = (index * 0.05).clamp(0.0, 1.0);
                final progress =
                    (_resultsController.value - delay).clamp(0.0, 1.0);
                final opacity = progress;
                final translateY =
                    30.0 * (1.0 - Curves.easeOutCubic.transform(progress));

                return Opacity(
                  opacity: opacity,
                  child: Transform.translate(
                    offset: Offset(0, translateY),
                    child: _buildMeasurementRow(
                      _measurementLabels[entry.key] ?? entry.key.toUpperCase(),
                      entry.value,
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMeasurementRow(String name, double value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.amber,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${value.toStringAsFixed(1)} cm',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PHOTO GUIDANCE
  // ---------------------------------------------------------------------------

  Widget _buildPhotoGuidance({
    Uint8List? image,
    required String label,
    required bool isFront,
  }) {
    return Container(
      height: 320,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: image != null
              ? AppColors.amber.withAlpha(200)
              : AppColors.amber.withAlpha(60),
          width: image != null ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: image != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                   Image.memory(image, fit: BoxFit.cover),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(80),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withAlpha(180),
                          ],
                        ),
                      ),
                      child: Text(
                        '$label PHOTO CAPTURED',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: Image.asset(
                      isFront
                          ? 'assets/images/guidance/pose_front.png'
                          : 'assets/images/guidance/pose_side.png',
                      fit: BoxFit.contain,
                      height: 280,
                      errorBuilder: (context, error, stackTrace) =>
                          CustomPaint(
                        painter: isFront
                            ? _FrontSilhouettePainter()
                            : _SideSilhouettePainter(),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withAlpha(180),
                          ],
                        ),
                      ),
                      child: Text(
                        isFront
                            ? 'Stand straight • Arms at sides • Full body visible'
                            : 'Turn 90° • Side profile visible • Arms at sides',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BOTTOM ACTIONS
  // ---------------------------------------------------------------------------

  Widget _buildBottomActions() {
    // No bar while choosing a method: the two cards are the only actions, and a
    // permanently disabled CONTINUE beside them just looked broken.
    if (_captureMode == null) return const SizedBox.shrink();
    if (_currentStep == 3) {
      return const SizedBox.shrink();
    }

    if (_currentStep == 4 && !_isProcessing && _errorMessage == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.darkNavy,
          border: Border(top: BorderSide(color: Colors.white10)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _resetScan();
                    _speakStepGuidance(0);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('NEW SCAN'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _measurements != null ? _saveMeasurements : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    foregroundColor: AppColors.darkNavy,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'SAVE MEASUREMENTS',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.darkNavy,
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _transitionToStep(_currentStep - 1);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('BACK'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _canProceed() ? _proceed : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _canProceed() ? AppColors.amber : Colors.white12,
                  foregroundColor: AppColors.darkNavy,
                  disabledBackgroundColor: Colors.white12,
                  disabledForegroundColor: Colors.white38,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _isProcessing ? 'PROCESSING...' : 'CONTINUE',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// CUSTOM PAINTERS
// =============================================================================

class _FrontSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final dashedPaint = Paint()
      ..color = Colors.white.withAlpha(15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final centerX = size.width / 2;
    final topY = size.height * 0.08;

    // Head
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, topY + 18),
        width: 36,
        height: 42,
      ),
      paint,
    );

    // Neck
    final neckTop = topY + 39;
    canvas.drawLine(
      Offset(centerX - 6, neckTop),
      Offset(centerX - 6, neckTop + 10),
      paint,
    );
    canvas.drawLine(
      Offset(centerX + 6, neckTop),
      Offset(centerX + 6, neckTop + 10),
      paint,
    );

    // Shoulders + Torso
    final shoulderY = neckTop + 10;
    final shoulderLeft = centerX - 50;
    final shoulderRight = centerX + 50;
    final waistY = shoulderY + 70;
    final waistLeft = centerX - 35;
    final waistRight = centerX + 35;

    final torsoPath = Path()
      ..moveTo(shoulderLeft, shoulderY)
      ..lineTo(shoulderRight, shoulderY)
      ..lineTo(waistRight, waistY)
      ..lineTo(waistLeft, waistY)
      ..close();
    canvas.drawPath(torsoPath, paint);

    // Left arm
    canvas.drawLine(
      Offset(shoulderLeft, shoulderY),
      Offset(shoulderLeft - 10, shoulderY + 55),
      paint,
    );
    canvas.drawLine(
      Offset(shoulderLeft - 10, shoulderY + 55),
      Offset(shoulderLeft - 5, shoulderY + 100),
      paint,
    );

    // Right arm
    canvas.drawLine(
      Offset(shoulderRight, shoulderY),
      Offset(shoulderRight + 10, shoulderY + 55),
      paint,
    );
    canvas.drawLine(
      Offset(shoulderRight + 10, shoulderY + 55),
      Offset(shoulderRight + 5, shoulderY + 100),
      paint,
    );

    // Hips
    final hipY = waistY + 15;
    canvas.drawLine(
      Offset(waistLeft - 5, hipY),
      Offset(waistRight + 5, hipY),
      paint,
    );

    // Left leg
    final legTopLeft = waistLeft + 5;
    final legBottomLeft = centerX - 22;
    canvas.drawLine(
      Offset(legTopLeft, hipY),
      Offset(legBottomLeft, hipY + 90),
      paint,
    );
    canvas.drawLine(
      Offset(legBottomLeft, hipY + 90),
      Offset(legBottomLeft - 3, hipY + 130),
      paint,
    );

    // Right leg
    final legTopRight = waistRight - 5;
    final legBottomRight = centerX + 22;
    canvas.drawLine(
      Offset(legTopRight, hipY),
      Offset(legBottomRight, hipY + 90),
      paint,
    );
    canvas.drawLine(
      Offset(legBottomRight, hipY + 90),
      Offset(legBottomRight + 3, hipY + 130),
      paint,
    );

    // Dashed horizontal guidelines
    _drawDashedLine(
      canvas,
      dashedPaint,
      centerX - 65,
      centerX + 65,
      shoulderY,
    );
    _drawDashedLine(canvas, dashedPaint, centerX - 50, centerX + 50, waistY);
    _drawDashedLine(canvas, dashedPaint, centerX - 55, centerX + 55, hipY);
  }

  void _drawDashedLine(
    Canvas canvas,
    Paint paint,
    double startX,
    double endX,
    double y,
  ) {
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    double currentX = startX;
    while (currentX < endX) {
      canvas.drawLine(
        Offset(currentX, y),
        Offset(min(currentX + dashWidth, endX), y),
        paint,
      );
      currentX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SideSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final centerX = size.width * 0.45;
    final topY = size.height * 0.08;

    // Head (side profile - circle)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, topY + 18),
        width: 32,
        height: 40,
      ),
      paint,
    );

    // Nose bump
    final nosePath = Path()
      ..moveTo(centerX + 16, topY + 18)
      ..quadraticBezierTo(centerX + 24, topY + 22, centerX + 16, topY + 26);
    canvas.drawPath(nosePath, paint);

    // Neck
    final neckTop = topY + 38;
    canvas.drawLine(
      Offset(centerX - 4, neckTop),
      Offset(centerX - 4, neckTop + 12),
      paint,
    );
    canvas.drawLine(
      Offset(centerX + 4, neckTop),
      Offset(centerX + 4, neckTop + 12),
      paint,
    );

    // Torso (side view - single column)
    final shoulderY = neckTop + 12;
    final waistY = shoulderY + 65;
    final hipY = waistY + 15;

    // Front of torso
    canvas.drawLine(
      Offset(centerX + 20, shoulderY),
      Offset(centerX + 18, waistY),
      paint,
    );
    canvas.drawLine(
      Offset(centerX + 18, waistY),
      Offset(centerX + 22, hipY),
      paint,
    );

    // Back of torso
    canvas.drawLine(
      Offset(centerX - 18, shoulderY),
      Offset(centerX - 14, waistY),
      paint,
    );
    canvas.drawLine(
      Offset(centerX - 14, waistY),
      Offset(centerX - 18, hipY),
      paint,
    );

    // Shoulder line
    canvas.drawLine(
      Offset(centerX - 18, shoulderY),
      Offset(centerX + 20, shoulderY),
      paint,
    );

    // Hip line
    canvas.drawLine(
      Offset(centerX - 18, hipY),
      Offset(centerX + 22, hipY),
      paint,
    );

    // Arm (hanging at side)
    canvas.drawLine(
      Offset(centerX + 22, shoulderY + 5),
      Offset(centerX + 28, shoulderY + 55),
      paint,
    );
    canvas.drawLine(
      Offset(centerX + 28, shoulderY + 55),
      Offset(centerX + 26, shoulderY + 100),
      paint,
    );

    // Leg
    canvas.drawLine(
      Offset(centerX + 5, hipY),
      Offset(centerX + 5, hipY + 100),
      paint,
    );
    canvas.drawLine(
      Offset(centerX + 5, hipY + 100),
      Offset(centerX + 5, hipY + 130),
      paint,
    );

    // Back leg line
    canvas.drawLine(
      Offset(centerX - 10, hipY),
      Offset(centerX - 10, hipY + 100),
      paint,
    );
    canvas.drawLine(
      Offset(centerX - 10, hipY + 100),
      Offset(centerX - 10, hipY + 130),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ProcessingRingPainter extends CustomPainter {
  final double progress;

  _ProcessingRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withAlpha(15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );

    // Animated sweep gradient ring
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: pi * 2,
        colors: const [
          Colors.transparent,
          AppColors.amber,
          AppColors.amber,
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
        transform: GradientRotation(progress * pi * 2),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant _ProcessingRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
