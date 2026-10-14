import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:o3d/o3d.dart';
import '../../../../theme/colors.dart';
import '../../../../core/providers/layout_provider.dart';
import '../../../payments/presentation/widgets/subscription_gate.dart';
import '../../../payments/domain/models/plan_registry.dart';
import '../widgets/guided_crop_widget.dart';
import '../../../../core/widgets/shell_app_bar.dart';

/// Measurement Explorer — Interactive body measurement viewer.
/// Shows a 3D mannequin with body-region zoom.
/// Tap a measurement to see the guided crop for that body region.
///
/// Usage:
///   Navigator.push(context, MaterialPageRoute(
///     builder: (_) => MeasurementExplorerPage(
///       measurements: {'Chest Round': 96.5, 'Waist Round': 82.0, ...},
///       gender: 'male',
///       heightCm: 175,
///       scanLabel: 'Scan — Aug 21, 2026',
///     ),
///   ));
class MeasurementExplorerPage extends ConsumerStatefulWidget {
  final Map<String, double> measurements;
  final String gender;
  final double? heightCm;
  final String? scanLabel;

  const MeasurementExplorerPage({
    super.key,
    required this.measurements,
    this.gender = 'male',
    this.heightCm,
    this.scanLabel,
  });

  @override
  ConsumerState<MeasurementExplorerPage> createState() =>
      _MeasurementExplorerPageState();
}

class _MeasurementExplorerPageState
    extends ConsumerState<MeasurementExplorerPage> {
  final O3DController _o3dController = O3DController();
  String? _focusedField;
  String _unit = 'CM';
  final bool _show3D = true;
  bool? _isModelAvailable;

  String get _modelPath => widget.gender.toLowerCase() == 'female'
      ? 'assets/models/female_mannequin.glb'
      : 'assets/models/male_mannequin.glb';

  // --- Guidance asset mapping ---
  String _getAssetPath(String field) {
    const String base = 'images/guidance';
    final Map<String, String> mapping = {
      'Across Back': 'across_back.jpg.jpeg',
      'Across Chest': 'across_chest.jpg.jpeg',
      'Ankle Round': 'ankle_round.jpg.jpeg',
      'Calf Round': 'calf_round.jpg.jpeg',
      'Chest Round': 'chest_round.jpg.jpeg',
      'Full Top Length': 'full_top_length.jpg.jpeg',
      'Half Length': 'half_length.jpg.jpeg',
      'Hip Round': 'hip_round.jpg.jpeg',
      'Knee Round': 'knee_round.jpg.jpeg',
      'Neck Round': 'neck_round.jpg.jpeg',
      'Shoulder': 'shoulder.jpg.jpeg',
      'Stomach Round': 'stomach_round.jpg.jpeg',
      'Thigh Round': 'thigh_round.jpg.jpeg',
      'Trouser Length': 'trouser_length.jpg.jpeg',
      'Trouser Waist': 'trouser_waist.jpg.jpeg',
      'Waist Round': 'waist_round.jpg.jpeg',
      'Bust Round': 'female_bust_round.png',
      'Bust Point': 'female_bust_point.png',
      'High Bust': 'female_high_bust.png',
      'Under Bust': 'female_under-bust.png',
      'Shoulder to Waist': 'female_shoulder_to_waist.png',
      'Inseam': 'inseam.jpg.jpeg',
      'Crotch Depth': 'crotch_depth.jpg.jpeg',
    };

    if (widget.gender.toLowerCase() == 'female') {
      if (field == 'Neck Round') return '$base/female_neck_round.png';
      if (field == 'Shoulder') return '$base/female_shoulder.png';
      if (field == 'Half Length') return '$base/female_half_length.png';
    }

    if (mapping.containsKey(field)) return '$base/${mapping[field]}';
    return '$base/${field.toLowerCase().replaceAll(' ', '_')}.jpg.jpeg';
  }

  // --- Measurement grouping ---
  static const _upperBody = [
    'Shoulder',
    'Neck Round',
    'Chest Round',
    'Across Chest',
    'Across Back',
    'Bust Round',
    'High Bust',
    'Under Bust',
    'Bust Point',
    'Armhole Round',
    'Sleeve Length',
    'Bicep Round',
    'Elbow Round',
    'Wrist Round',
  ];
  static const _midBody = [
    'Stomach Round',
    'Waist Round',
    'Half Length',
    'Full Top Length',
    'Shoulder to Waist',
    'Front Waist Length',
    'Back Waist Length',
    'Shoulder to Bust Point',
    'Shoulder to Under Bust',
    'Waist to Hip',
  ];
  static const _lowerBody = [
    'Hip Round',
    'Upper Hip',
    'Thigh Round',
    'Knee Round',
    'Calf Round',
    'Ankle Round',
    'Inseam',
    'Trouser Length',
    'Trouser Waist',
    'Crotch Depth',
  ];

  List<String> get _allMeasurementKeys {
    final keys = widget.measurements.keys.toList();
    // Sort by body region
    final sorted = <String>[];
    for (final list in [_upperBody, _midBody, _lowerBody]) {
      for (final k in list) {
        if (keys.contains(k)) sorted.add(k);
      }
    }
    // Append any remaining
    for (final k in keys) {
      if (!sorted.contains(k)) sorted.add(k);
    }
    return sorted;
  }

  @override
  void initState() {
    super.initState();
    _checkModel();
  }

  Future<void> _checkModel() async {
    setState(() => _isModelAvailable = null);
    try {
      await rootBundle.load(_modelPath);
      if (mounted) setState(() => _isModelAvailable = true);
    } catch (e) {
      debugPrint('❌ [3D] Asset missing: $_modelPath');
      if (mounted) setState(() => _isModelAvailable = false);
    }
  }

  // --- Camera rigging for body regions ---
  void _onFieldFocus(String label) async {
    if (_focusedField == label) return;

    final hasAccess = await SubscriptionGate.checkAccess(
      context,
      requiredTier: PlanRegistry.proTier,
      featureLabel: 'Measurement Explorer',
    );
    if (!hasAccess || !mounted) return;

    setState(() => _focusedField = label);

    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted || _focusedField != label) return;

      const double cx = 0.0, cz = 0.0;
      switch (label) {
        case 'Half Length':
        case 'Across Back':
        case 'Back Waist Length':
          _o3dController.cameraTarget(cx, 0.2, cz);
          _o3dController.cameraOrbit(180, 75, 1.8);
          break;
        case 'Full Top Length':
          _o3dController.cameraTarget(cx, 0.1, cz);
          _o3dController.cameraOrbit(90, 80, 1.6);
          break;
        case 'Ankle Round':
          _o3dController.cameraTarget(cx, -0.6, cz);
          _o3dController.cameraOrbit(0, 90, 1.2);
          break;
        case 'Shoulder':
        case 'Neck Round':
          _o3dController.cameraTarget(cx, 0.45, cz);
          _o3dController.cameraOrbit(0, 75, 1.4);
          break;
        case 'Chest Round':
        case 'Across Chest':
        case 'Bust Round':
        case 'High Bust':
        case 'Under Bust':
        case 'Bust Point':
          _o3dController.cameraTarget(cx, 0.3, cz);
          _o3dController.cameraOrbit(0, 85, 1.7);
          break;
        case 'Waist Round':
        case 'Stomach Round':
          _o3dController.cameraTarget(cx, 0.1, cz);
          _o3dController.cameraOrbit(0, 90, 1.6);
          break;
        case 'Trouser Waist':
        case 'Upper Hip':
          _o3dController.cameraTarget(cx, -0.1, cz);
          _o3dController.cameraOrbit(0, 90, 1.6);
          break;
        case 'Hip Round':
        case 'Waist to Hip':
          _o3dController.cameraTarget(cx, -0.15, cz);
          _o3dController.cameraOrbit(0, 90, 1.7);
          break;
        case 'Thigh Round':
          _o3dController.cameraTarget(cx, -0.3, cz);
          _o3dController.cameraOrbit(0, 90, 1.5);
          break;
        case 'Knee Round':
          _o3dController.cameraTarget(cx, -0.45, cz);
          _o3dController.cameraOrbit(0, 90, 1.4);
          break;
        case 'Calf Round':
          _o3dController.cameraTarget(cx, -0.55, cz);
          _o3dController.cameraOrbit(0, 90, 1.3);
          break;
        case 'Crotch Depth':
        case 'Inseam':
        case 'Trouser Length':
          _o3dController.cameraTarget(cx, -0.3, cz);
          _o3dController.cameraOrbit(0, 90, 1.8);
          break;
        default:
          _o3dController.cameraTarget(cx, -0.4, cz);
          _o3dController.cameraOrbit(0, 75, 1.8);
      }
    });
  }

  double _convertValue(double cmValue) {
    return _unit == 'Inches' ? cmValue / 2.54 : cmValue;
  }

  String _unitLabel() => _unit == 'Inches' ? 'IN' : 'CM';

  @override
  Widget build(BuildContext context) {
    final keys = _allMeasurementKeys;
    final isDesktop = ref.watch(isDesktopProvider);

    return Scaffold(
      backgroundColor: context.colors.scaffoldBg,
      appBar: shellAppBar(
        context,
        title: widget.scanLabel ?? 'MEASUREMENT EXPLORER',
        actions: [
          // Unit toggle
          ToggleButtons(
            isSelected: [_unit == 'CM', _unit == 'Inches'],
            onPressed: (i) => setState(() => _unit = i == 0 ? 'CM' : 'Inches'),
            borderRadius: BorderRadius.circular(8),
            color: context.colors.textMuted,
            selectedColor: AppColors.darkNavy,
            fillColor: AppColors.amber,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 32),
            children: const [
              Text(
                'CM',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
              ),
              Text(
                'IN',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(width: 8),
          if (widget.heightCm != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  'Height: ${_convertValue(widget.heightCm!).toStringAsFixed(0)} ${_unitLabel()}',
                  style: TextStyle(
                    color: context.colors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: isDesktop ? _buildDesktopLayout(keys) : _buildMobileLayout(keys),
    );
  }

  Widget _buildDesktopLayout(List<String> keys) {
    return Row(
      children: [
        // Left: 3D Model + Zoom
        Expanded(flex: 3, child: _buildRiggingStation()),
        const SizedBox(width: 16),
        // Right: Measurement list
        Expanded(flex: 2, child: _buildMeasurementList(keys)),
      ],
    );
  }

  Widget _buildMobileLayout(List<String> keys) {
    return Column(
      children: [
        // Top: 3D Model + Zoom (compact)
        SizedBox(height: 280, child: _buildRiggingStation()),
        const SizedBox(height: 8),
        // Bottom: Measurement list
        Expanded(child: _buildMeasurementList(keys)),
      ],
    );
  }

  Widget _buildRiggingStation() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colors.divider),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            // 3D Model
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_isModelAvailable == null)
                    const CircularProgressIndicator(color: AppColors.amber)
                  else if (_isModelAvailable == false)
                    Text(
                      '3D MODEL UNAVAILABLE',
                      style: TextStyle(
                        color: context.colors.textMuted,
                        fontSize: 10,
                      ),
                    )
                  else if (_show3D)
                    O3D.asset(
                      controller: _o3dController,
                      src: _modelPath,
                      autoRotate: false,
                      backgroundColor: Colors.transparent,
                      cameraTarget: CameraTarget(0, -0.4, 0),
                      cameraOrbit: CameraOrbit(0, 75, 1.8),
                    ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: context.colors.overlayMedium,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '3D',
                        style: TextStyle(
                          color: context.colors.textPrimary,
                          fontSize: 7,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(width: 1, color: context.colors.divider),
            // Guided crop zoom
            Expanded(
              child: Stack(
                children: [
                  if (_focusedField != null)
                    StaticGuidedCrop(
                      imagePath: _getAssetPath(_focusedField!),
                      borderRadius: 0,
                    )
                  else
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.touch_app,
                            color: context.colors.textMuted,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'TAP A\nMEASUREMENT',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: context.colors.textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.amber.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'ZOOM',
                        style: TextStyle(
                          color: context.colors.scaffoldBg,
                          fontSize: 7,
                          fontWeight: FontWeight.w900,
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
    );
  }

  Widget _buildMeasurementList(List<String> keys) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        _buildSectionHeader(
          'UPPER BODY',
          keys.where((k) => _upperBody.contains(k)).toList(),
        ),
        _buildSectionHeader(
          'MID BODY',
          keys.where((k) => _midBody.contains(k)).toList(),
        ),
        _buildSectionHeader(
          'LOWER BODY',
          keys.where((k) => _lowerBody.contains(k)).toList(),
        ),
        // Any remaining
        _buildSectionHeader(
          'OTHER',
          keys
              .where(
                (k) =>
                    !_upperBody.contains(k) &&
                    !_midBody.contains(k) &&
                    !_lowerBody.contains(k),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, List<String> keys) {
    if (keys.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Text(
            title,
            style: TextStyle(
              color: context.colors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
        ...keys.map((k) => _buildMeasurementTile(k)),
      ],
    );
  }

  Widget _buildMeasurementTile(String key) {
    final value = widget.measurements[key];
    if (value == null) return const SizedBox.shrink();

    final isFocused = _focusedField == key;
    final displayValue = _convertValue(value);

    return GestureDetector(
      onTap: () => _onFieldFocus(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isFocused
              ? AppColors.amber.withValues(alpha: 0.1)
              : context.colors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isFocused ? AppColors.amber : context.colors.borderSubtle,
          ),
        ),
        child: Row(
          children: [
            // Focus indicator
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFocused ? AppColors.amber : context.colors.textMuted,
              ),
            ),
            const SizedBox(width: 10),
            // Label
            Expanded(
              child: Text(
                key.toUpperCase(),
                style: TextStyle(
                  color: isFocused
                      ? context.colors.textPrimary
                      : context.colors.textMuted,
                  fontSize: 11,
                  fontWeight: isFocused ? FontWeight.w900 : FontWeight.w600,
                ),
              ),
            ),
            // Value
            Text(
              '${displayValue.toStringAsFixed(1)} ${_unitLabel()}',
              style: TextStyle(
                color: isFocused ? AppColors.amber : context.colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
