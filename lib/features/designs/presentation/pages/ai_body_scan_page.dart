import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../../theme/colors.dart';
import '../../../../core/services/body_measurement_service.dart';

/// AI Body Scan Page - Capture measurements from dual photos
/// 
/// This page guides users through capturing front + side photos
/// for AI-powered body measurement extraction (±1-3cm accuracy).
class AiBodyScanPage extends ConsumerStatefulWidget {
  const AiBodyScanPage({super.key});

  @override
  ConsumerState<AiBodyScanPage> createState() => _AiBodyScanPageState();
}

class _AiBodyScanPageState extends ConsumerState<AiBodyScanPage> {
  final ImagePicker _picker = ImagePicker();
  
  File? _frontImage;
  File? _sideImage;
  double _heightCm = 170.0;
  String _gender = 'male';
  bool _isProcessing = false;
  String? _errorMessage;
  Map<String, double>? _measurements;
  
  int _currentStep = 0; // 0 = front, 1 = side, 2 = height, 3 = results

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
      ),
      body: _buildStepContent(),
      bottomSheet: _buildBottomActions(),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildFrontPhotoStep();
      case 1:
        return _buildSidePhotoStep();
      case 2:
        return _buildHeightInputStep();
      case 3:
        return _buildResultsStep();
      default:
        return _buildFrontPhotoStep();
    }
  }

  /// Step 1: Front Photo Capture
  Widget _buildFrontPhotoStep() {
    return SingleChildScrollView(
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
            'Stand in front of camera with arms relaxed at your sides.\nFull body should be visible.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 32),
          // Photo guidance overlay
          _buildPhotoGuidance(
            image: _frontImage,
            label: 'FRONT',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 32),
          // Capture button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => _capturePhoto('front'),
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text(
                'CAPTURE FRONT PHOTO',
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
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

  /// Step 2: Side Photo Capture
  Widget _buildSidePhotoStep() {
    return SingleChildScrollView(
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
            'Turn 90° to the right or left.\nStand sideways to camera.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 32),
          // Photo guidance overlay
          _buildPhotoGuidance(
            image: _sideImage,
            label: 'SIDE',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 32),
          // Capture button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => _capturePhoto('side'),
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text(
                'CAPTURE SIDE PHOTO',
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
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

  /// Step 3: Height Input
  Widget _buildHeightInputStep() {
    return SingleChildScrollView(
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
          const SizedBox(height: 32),
          // Height slider
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  '${_heightCm.toInt()} cm',
                  style: const TextStyle(
                    color: AppColors.amber,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Slider(
                  value: _heightCm,
                  min: 120,
                  max: 220,
                  divisions: 100,
                  activeColor: AppColors.amber,
                  inactiveColor: Colors.white24,
                  onChanged: (value) {
                    setState(() => _heightCm = value);
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('120 cm', style: TextStyle(color: Colors.white38)),
                    const Text('220 cm', style: TextStyle(color: Colors.white38)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Gender selection
          Row(
            children: [
              Expanded(
                child: _buildGenderButton('male', 'MALE'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGenderButton('female', 'FEMALE'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderButton(String value, String label) {
    final isSelected = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.amber : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.amber : Colors.white12,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.darkNavy : Colors.white70,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  /// Results Display
  Widget _buildResultsStep() {
    if (_measurements == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.amber),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'YOUR MEASUREMENTS',
            style: TextStyle(
              color: AppColors.amber,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'AI SCAN COMPLETE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                SizedBox(width: 8),
                Text(
                  '±1-3cm Accuracy',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Measurements list
          ..._measurements!.entries.map((entry) => _buildMeasurementRow(
            entry.key,
            entry.value,
          )),
        ],
      ),
    );
  }

  Widget _buildMeasurementRow(String name, double value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name.toUpperCase(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '${value.toStringAsFixed(1)} cm',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  /// Photo guidance overlay widget
  Widget _buildPhotoGuidance({
    File? image,
    required String label,
    required IconData icon,
  }) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
      ),
      child: image != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                image,
                fit: BoxFit.cover,
              ),
            )
          : Stack(
              children: [
                // Silhouette guide
                Center(
                  child: Icon(
                    icon,
                    size: 120,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                // Instructions overlay
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      label == 'FRONT'
                          ? '• Stand straight\n• Arms at sides\n• Full body visible'
                          : '• Turn 90° to camera\n• Side profile visible',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.darkNavy,
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep--),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
                  backgroundColor: _canProceed() ? AppColors.amber : Colors.white24,
                  foregroundColor: AppColors.darkNavy,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(_currentStep == 3 ? 'SAVE MEASUREMENTS' : 'CONTINUE'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _frontImage != null;
      case 1:
        return _sideImage != null;
      case 2:
        return _heightCm >= 120 && _heightCm <= 220;
      case 3:
        return _measurements != null;
      default:
        return false;
    }
  }

  void _proceed() async {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      // Save measurements - navigate back
      Navigator.pop(context, _measurements);
    }
  }

  Future<void> _capturePhoto(String perspective) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (photo != null) {
        setState(() {
          if (perspective == 'front') {
            _frontImage = File(photo.path);
          } else {
            _sideImage = File(photo.path);
          }
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to capture photo: $e');
    }
  }

  Future<void> _processMeasurements() async {
    if (_frontImage == null || _sideImage == null) return;
    
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final service = BodyMeasurementService();
      final result = await service.extractMeasurements(
        frontImage: _frontImage!,
        sideImage: _sideImage!,
        heightCm: _heightCm,
        gender: _gender,
      );

      if (result.success && result.measurements != null) {
        setState(() {
          _measurements = result.measurements;
          _currentStep = 3;
        });
      } else {
        setState(() {
          _errorMessage = result.error ?? 'Failed to process';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() => _isProcessing = false);
    }
  }
}
