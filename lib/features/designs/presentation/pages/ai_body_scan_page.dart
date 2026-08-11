import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/body_measurement_service.dart';
import '../../../../core/network/korra_client.dart';
import '../../../../theme/colors.dart';
import 'ai_camera_capture_page.dart';

class AiBodyScanPage extends ConsumerStatefulWidget {
  const AiBodyScanPage({super.key});

  @override
  ConsumerState<AiBodyScanPage> createState() => _AiBodyScanPageState();
}

class _AiBodyScanPageState extends ConsumerState<AiBodyScanPage>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final BodyMeasurementService _service = BodyMeasurementService();
  final FlutterTts _tts = FlutterTts();

  Uint8List? _frontImage;
  Uint8List? _sideImage;
  double _heightCm = 170.0;
  String _gender = 'male';
  bool _isProcessing = false;
  String? _errorMessage;
  Map<String, double>? _measurements;
  static const String _accuracyMode = 'dual';
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
  }

  @override
  void dispose() {
    _stepController.dispose();
    _resultsController.dispose();
    _pulseController.dispose();
    _processingController.dispose();
    _processingTimer?.cancel();
    _tts.stop();
    _service.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // VOICE GUIDANCE
  // ---------------------------------------------------------------------------

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    if (!_voiceEnabled) return;
    await _tts.speak(text);
  }

  void _speakStepGuidance(int step) {
    switch (step) {
      case 0:
        _speak(
          'Stand facing the camera with your arms relaxed at your sides. '
          'Make sure your full body is visible. Press the capture button when ready.',
        );
        break;
      case 1:
        _speak(
          'Now turn 90 degrees to the side. Stand sideways to the camera '
          'with your arms at your sides. Press the capture button when ready.',
        );
        break;
      case 2:
        _speak('Enter your height for accurate measurements.');
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // COUNTDOWN & CAPTURE
  // ---------------------------------------------------------------------------
  Future<void> _startCountdownAndCapture(String perspective) async {
    HapticFeedback.selectionClick();
    await _speak('Opening AI camera. Follow the pose guidance.');
    _capturePhoto(perspective);
  }
  Future<void> _capturePhoto(String perspective) async {
    try {
      Uint8List? imageBytes;

      imageBytes = await Navigator.push<Uint8List>(
        context,
        MaterialPageRoute(
          builder: (_) => AiCameraCapturePage(perspective: perspective),
        ),
      );

      if (imageBytes == null) {
        final XFile? picked = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );
        if (picked != null) imageBytes = await picked.readAsBytes();
      }

      if (imageBytes != null) {
        HapticFeedback.heavyImpact();
        setState(() {
          if (perspective == 'front') {
            _frontImage = imageBytes;
          } else {
            _sideImage = imageBytes;
          }
        });
        await _speak('Photo captured successfully.');
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
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _processingSeconds = 0;
      _currentStep = 3;
    });
    _speak('Processing your photos. This may take a few seconds.');
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
        await _speak(
          'Scan complete! ${result.measurements!.length} measurements extracted.',
        );
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
        await _speak('Scan failed. Please try again.');
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
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && _measurements != null) {
        await Supabase.instance.client.from('body_scans').insert({
          'user_id': user.id,
          'measurements': _measurements,
          'gender': _gender,
          'height_cm': _heightCm,
          'accuracy_mode': _accuracyMode,
          'accuracy': _accuracyDescription,
          'measurement_count': _measurements!.length,
        });
      }
    } catch (e) {
      debugPrint('[SCAN] Failed to persist scan: $e');
    }

    if (mounted) {
      Navigator.pop(context, _measurements);
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
      appBar: AppBar(
        backgroundColor: AppColors.darkNavy,
        elevation: 0,
        leading: IconButton(
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
              if (_voiceEnabled) _speak('Voice guidance enabled.');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
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
      bottomSheet: _buildBottomActions(),
    );
  }

  // ---------------------------------------------------------------------------
  // PROGRESS INDICATOR
  // ---------------------------------------------------------------------------

  Widget _buildProgressIndicator() {
    const totalSteps = 4;
    final completedSteps = _currentStep >= 4 ? 4 : _currentStep;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(totalSteps, (index) {
          final isDone = index < completedSteps;
          final isActive = index == completedSteps && _currentStep < 4;
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
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP CONTENT
  // ---------------------------------------------------------------------------

  Widget _buildStepContent() {
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

  // ---------------------------------------------------------------------------
  // STEP 0: FRONT PHOTO
  // ---------------------------------------------------------------------------

  Widget _buildFrontPhotoStep() {
    return SingleChildScrollView(
      key: const ValueKey('front_photo'),
      padding: const EdgeInsets.all(24),
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
            'Stand facing the camera with arms relaxed\nat your sides. Full body must be visible.',
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
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => _startCountdownAndCapture('front'),
              icon: const Icon(Icons.camera_alt_rounded),
              label: Text(
                _frontImage != null ? 'RECAPTURE FRONT' : 'CAPTURE FRONT PHOTO',
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
      padding: const EdgeInsets.all(24),
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
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => _startCountdownAndCapture('side'),
              icon: const Icon(Icons.camera_alt_rounded),
              label: Text(
                _sideImage != null ? 'RECAPTURE SIDE' : 'CAPTURE SIDE PHOTO',
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
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 2: HEIGHT INPUT
  // ---------------------------------------------------------------------------

  Widget _buildHeightInputStep() {
    return SingleChildScrollView(
      key: const ValueKey('height_input'),
      padding: const EdgeInsets.all(24),
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
          if (_showCelebration)
            AnimatedOpacity(
              opacity: _showCelebration ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withAlpha(80)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'EXTRACTION SUCCESSFUL',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                    setState(() {
                      _currentStep = 0;
                      _measurements = null;
                      _frontImage = null;
                      _sideImage = null;
                      _errorMessage = null;
                      _showCelebration = false;
                    });
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
