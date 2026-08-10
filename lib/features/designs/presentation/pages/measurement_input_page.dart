import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../theme/colors.dart';
import '../../../../core/utils/async_handler.dart';
import '../../../../core/utils/measurement_mapper.dart';
import '../widgets/guided_crop_widget.dart';
import 'ai_body_scan_page.dart';
// ignore: depend_on_referenced_packages
import 'package:o3d/o3d.dart';

/// Measurement Input Page - High-precision digital design station
/// Features dual-visual rigging (3D + 2D Zoom) and responsive multi-screen flow.
class MeasurementInputPage extends ConsumerStatefulWidget {
  const MeasurementInputPage({super.key});

  @override
  ConsumerState<MeasurementInputPage> createState() => _MeasurementInputPageState();
}

class _MeasurementInputPageState extends ConsumerState<MeasurementInputPage> with AsyncHandler {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  String _gender = 'MALE';
  String _unit = 'Inches';
  String? _focusedField;

  // Track which fields were auto-filled by AI
  final Set<String> _aiFields = {};

  // RESTORED: Detailed Parameters
  String _selectedOccasion = 'Casual';
  String _selectedColor = '#000000'; // Store as hex code
  String _selectedFabric = 'Cotton';
  double _budgetMin = 50000;
  double _budgetMax = 150000;
  
  // Height input (for clients)
  final _heightController = TextEditingController();
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();
  double _sliderColorValue = 0;

  void _launchAiScan() async {
    final Map<String, double>? results = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AiBodyScanPage()),
    );

    if (results != null && results.isNotEmpty) {
      _populateFromScan(results);
    }
  }

  void _populateFromScan(Map<String, double> rawResults) {
    // 1. Map keys to UI labels
    final mapped = MeasurementMapper.mapResults(rawResults);

    setState(() {
      _aiFields.clear();
      mapped.forEach((label, value) {
        if (_controllers.containsKey(label)) {
          // Convert CM to Inches if necessary
          final double finalValue = _unit == 'Inches' ? value / 2.54 : value;
          _controllers[label]!.text = finalValue.toStringAsFixed(1);
          _aiFields.add(label);
        }
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('NEURAL SYNC: ${_aiFields.length} metrics auto-filled.'),
        backgroundColor: Colors.greenAccent,
        duration: const Duration(seconds: 4),
      ),
    );
  }
  
  // Visual color palette with actual colors
  static const Map<String, Color> _colorPalette = {
    'Black': Color(0xFF000000),
    'White': Color(0xFFFFFFFF),
    'Navy': Color(0xFF000080),
    'Brown': Color(0xFF8B4513),
    'Green': Color(0xFF008000),
    'Red': Color(0xFFFF0000),
    'Blue': Color(0xFF0000FF),
    'Beige': Color(0xFFF5F5DC),
    'Grey': Color(0xFF808080),
    'Gold': Color(0xFFFFD700),
    'Silver': Color(0xFFC0C0C0),
    'Pink': Color(0xFFFFC0CB),
    'Purple': Color(0xFF800080),
    'Orange': Color(0xFFFFA500),
    'Maroon': Color(0xFF800000),
    'Teal': Color(0xFF008080),
  };
  
  final O3DController _o3dController = O3DController();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  
  bool? _isModelAvailable;
  bool _show3D = true;

  String get _modelPath => _gender == 'FEMALE'
      ? 'assets/models/female_mannequin.glb'
      : 'assets/models/male_mannequin.glb';

  // --- GUIDANCE ASSET MAPPING (Synced with new female assets) ---
  String _getAssetPath(String field) {
    const String base = 'images/guidance';
    final Map<String, String> mapping = {
      // Male Assets
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
      'Upper Bicep': 'upper_bicep.jpg.jpeg',
      'Waist Round': 'waist_round.jpg.jpeg',
      // NEW: Female Assets Mapping
      'Bust Round': 'female_bust_round.png',
      'Bust Point': 'female_bust_point.png',
      'High Bust': 'female_high_bust.png',
      'Under Bust': 'female_under-bust.png',
      'Shoulder to Waist': 'female_shoulder_to_waist.png',
      'Inseam': 'inseam.jpg.jpeg',
      'Crotch Depth': 'crotch_depth.jpg.jpeg',
    };

    if (_gender == 'FEMALE') {
       if (field == 'Neck Round') return '$base/female_neck_round.png';
       if (field == 'Shoulder') return '$base/female_shoulder.png';
       if (field == 'Half Length') return '$base/female_half_length.png';
    }

    if (mapping.containsKey(field)) return '$base/${mapping[field]}';
    return '$base/${field.toLowerCase().replaceAll(' ', '_')}.jpg.jpeg';
  }

  // PARAMETER REGISTRY
  final List<String> _maleMeasurements = [
    'Shoulder', 'Neck Round', 'Chest Round', 'Stomach Round', 'Waist Round', 
    'Half Length', 'Full Top Length', 'Across Back', 'Across Chest', 'Hip Round', 
    'Thigh Round', 'Knee Round', 'Calf Round', 'Ankle Round', 'Trouser Waist', 
    'Trouser Length', 'Inseam', 'Crotch Depth'
  ];
  
  final List<String> _femaleMeasurements = [
    'Shoulder', 'Neck Round', 'Bust Round', 'High Bust', 'Under Bust', 
    'Bust Point', 'Shoulder to Bust Point', 'Shoulder to Under Bust', 
    'Shoulder to Waist', 'Front Waist Length', 'Back Waist Length', 
    'Across Chest', 'Across Back', 'Armhole Round', 'Sleeve Length', 
    'Bicep Round', 'Elbow Round', 'Wrist Round', 'Waist Round', 
    'Half Length', 'Waist to Hip', 'Upper Hip', 'Hip Round', 
    'Thigh Round', 'Knee Round', 'Calf Round', 'Ankle Round'
  ];

  @override
  void initState() {
    super.initState();
    _initControllers();
    _checkModel();
    _budgetMinController.text = _budgetMin.toInt().toString();
    _budgetMaxController.text = _budgetMax.toInt().toString();
  }

  void _initControllers() {
    final all = {..._maleMeasurements, ..._femaleMeasurements};
    for (var p in all) {
      _controllers[p] = TextEditingController();
      _focusNodes[p] = FocusNode();
      _focusNodes[p]!.addListener(() {
        if (_focusNodes[p]!.hasFocus) _onFieldFocus(p);
      });
    }
  }

  Future<void> _checkModel() async {
    final path = _modelPath;
    setState(() => _isModelAvailable = null);
    try {
      await rootBundle.load(path);
      if (mounted) setState(() => _isModelAvailable = true);
    } catch (e) {
      debugPrint('❌ [3D] Asset missing: $path');
      if (mounted) setState(() => _isModelAvailable = false);
    }
  }

  void _switchGender(String g) {
    if (_gender == g) return;
    setState(() {
      _gender = g;
      _currentStep = 0;
      _show3D = false;
      _focusedField = null;
    });
    _checkModel();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _show3D = true);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _heightController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    _controllers.forEach((_, c) => c.dispose());
    _focusNodes.forEach((_, n) => n.dispose());
    super.dispose();
  }

  // --- NAVIGATION ---
  void _next(int total) {
    FocusManager.instance.primaryFocus?.unfocus();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      if (_currentStep < total - 1) {
        _pageController.nextPage(duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic);
      } else {
        _save();
      }
    });
  }

  void _prev() {
    FocusManager.instance.primaryFocus?.unfocus();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      _pageController.previousPage(duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic);
    });
  }

  void _save() {
    final Map<String, dynamic> saveData = {
      'occasion': _selectedOccasion,
      'color': _selectedColor,
      'fabric': _selectedFabric,
      'height': _heightController.text,
      'budget_min': _budgetMin,
      'budget_max': _budgetMax,
      'unit': _unit,
      'gender': _gender,
      'measurements': {},
    };

    _controllers.forEach((key, controller) {
      if (controller.text.isNotEmpty) {
        saveData['measurements'][key] = controller.text;
      }
    });

    debugPrint('[MEASUREMENT] Establishing Profile: $saveData');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profile established: ${saveData['measurements'].length} metrics captured.'), 
        backgroundColor: AppColors.amber
      ),
    );
    
    if (ref.read(navigationProvider).route != '/main') {
      ref.read(navigationProvider.notifier).state = const NavigationState('/main');
    } else {
      Navigator.maybePop(context);
    }
  }

  // --- RIGGING & DYNAMIC ZOOM ---
  void _onFieldFocus(String label) {
    if (_focusedField == label) return;
    setState(() => _focusedField = label);

    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted || _focusedField != label) return;

      final double centerX = 0.0;
      final double centerZ = 0.0;

      switch (label) {
        case 'Half Length':
        case 'Across Back':
        case 'Back Waist Length':
          _o3dController.cameraTarget(centerX, 0.2, centerZ);
          _o3dController.cameraOrbit(180, 75, 1.8); 
          break;
        case 'Full Top Length':
          _o3dController.cameraTarget(centerX, 0.1, centerZ);
          _o3dController.cameraOrbit(90, 80, 1.6);
          break;
        case 'Ankle Round':
          _o3dController.cameraTarget(centerX, -0.6, centerZ);
          _o3dController.cameraOrbit(0, 90, 1.2); 
          break;
        case 'Shoulder': case 'Neck Round':
          _o3dController.cameraTarget(centerX, 0.45, centerZ); 
          _o3dController.cameraOrbit(0, 75, 1.4); 
          break;
        case 'Chest Round': case 'Across Chest': case 'Bust Round':
          _o3dController.cameraTarget(centerX, 0.3, centerZ); 
          _o3dController.cameraOrbit(0, 85, 1.7); 
          break;
        case 'Waist Round': case 'Stomach Round':
          _o3dController.cameraTarget(centerX, 0.1, centerZ); 
          _o3dController.cameraOrbit(0, 90, 1.6); 
          break;
        case 'Trouser Waist': case 'Upper Hip':
          _o3dController.cameraTarget(centerX, -0.1, centerZ); 
          _o3dController.cameraOrbit(0, 90, 1.6); 
          break;
        case 'Hip Round': case 'Seat Round': case 'Waist to Hip':
          _o3dController.cameraTarget(centerX, -0.15, centerZ); 
          _o3dController.cameraOrbit(0, 90, 1.7); 
          break;
        case 'Thigh Round':
          _o3dController.cameraTarget(centerX, -0.3, centerZ); 
          _o3dController.cameraOrbit(0, 90, 1.5); 
          break;
        case 'Knee Round':
          _o3dController.cameraTarget(centerX, -0.45, centerZ); 
          _o3dController.cameraOrbit(0, 90, 1.4); 
          break;
        case 'Calf Round':
          _o3dController.cameraTarget(centerX, -0.55, centerZ); 
          _o3dController.cameraOrbit(0, 90, 1.3); 
          break;
        case 'Crotch Depth': case 'Inseam':
          _o3dController.cameraTarget(centerX, -0.3, centerZ); 
          _o3dController.cameraOrbit(0, 90, 1.8); 
          break;
        default:
          _o3dController.cameraTarget(centerX, -0.4, centerZ); 
          _o3dController.cameraOrbit(0, 75, 1.8);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      _buildStylePreferencesStep(), 
      ...(_gender == 'MALE' ? _buildMenWizard() : _buildWomenWizard()),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0A1921),
      appBar: AppBar(
        title: const Text('BESPOKE STATION', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.amber, size: 18),
          onPressed: () {
            Navigator.of(context).maybePop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_fix_high_rounded, color: AppColors.amber),
            tooltip: 'AI Body Scan',
            onPressed: _launchAiScan,
          ),
          TextButton(onPressed: _save, child: const Text('SAVE', style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.bold)))
        ],
      ),
      body: Column(
        children: [
          _buildToggles(),
          _buildProgressBar(steps.length),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (i) {
                setState(() => _currentStep = i);
                FocusScope.of(context).unfocus();
              },
              physics: const NeverScrollableScrollPhysics(),
              children: steps,
            ),
          ),
          _buildBottomAction(steps.length),
        ],
      ),
    );
  }

Widget _buildStylePreferencesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DESIGN ARCHITECTURE', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const Text('Define your style and fabric requirements.', style: TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 32),
          _buildStyleSelector('OCCASION', _selectedOccasion, _occasions, (v) => setState(() => _selectedOccasion = v)),
          const SizedBox(height: 20),
          _buildColorPicker(),
          const SizedBox(height: 20),
          _buildStyleSelector('FABRIC', _selectedFabric, _fabrics, (v) => setState(() => _selectedFabric = v)),
          const SizedBox(height: 20),
          // Height input for clients
          _buildHeightInput(),
          const SizedBox(height: 32),
          _buildBudgetSlider(),
        ],
      ),
    );
  }
  
  Widget _buildColorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('COLOR', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        // Visual color palette
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _colorPalette.entries.map((entry) {
            final isSelected = _selectedColor.toUpperCase() == entry.key.toUpperCase() || 
                           _selectedColor.toUpperCase() == '#${entry.value.value.toRadixString(16).toUpperCase()}';
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = '#${entry.value.value.toRadixString(16).toUpperCase()}';
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: entry.value,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.amber : Colors.white24,
                    width: isSelected ? 3 : 1,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(color: entry.value.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2)
                  ] : null,
                ),
                child: isSelected 
                  ? Icon(
                      entry.value == Colors.white || entry.value == const Color(0xFFF5F5DC)
                        ? Icons.check : Icons.check,
                      color: entry.value == Colors.white || entry.value == const Color(0xFFF5F5DC) 
                        ? Colors.black : Colors.white,
                      size: 20,
                    )
                  : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        // Hex code input
        TextField(
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
          decoration: InputDecoration(
            labelText: 'CUSTOM HEX CODE',
            labelStyle: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900),
            prefixText: '# ',
            prefixStyle: const TextStyle(color: AppColors.amber, fontSize: 14, fontWeight: FontWeight.w900),
            hintText: 'e.g. FF5733',
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.03),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.amber),
            ),
          ),
          onChanged: (value) {
            if (value.length == 6) {
              final hex = value.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');
              if (hex.length == 6) {
                setState(() => _selectedColor = '#$hex');
              }
            }
          },
        ),
        const SizedBox(height: 16),
        // Color slider
        const Text('COLOR SLIDER', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 20,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            thumbColor: AppColors.amber,
            activeTrackColor: AppColors.amber,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
            overlayColor: AppColors.amber.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: _sliderColorValue,
            min: 0,
            max: 360,
            onChanged: (value) {
              setState(() {
                _sliderColorValue = value;
                // Convert HSL to hex
                final color = HSLColor.fromAHSL(1.0, value, 0.8, 0.5).toColor();
                _selectedColor = '#${color.value.toRadixString(16).toUpperCase()}';
              });
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildHeightInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('YOUR HEIGHT', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _heightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                decoration: InputDecoration(
                  hintText: 'Enter height',
                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                  suffixText: _unit == 'Inches' ? 'IN' : 'CM',
                  suffixStyle: const TextStyle(color: AppColors.amber, fontSize: 12, fontWeight: FontWeight.w900),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.03),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.amber),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Unit toggle
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ToggleButtons(
                isSelected: [_unit == 'Inches', _unit == 'CM'],
                onPressed: (index) {
                  setState(() => _unit = index == 0 ? 'Inches' : 'CM');
                },
                borderRadius: BorderRadius.circular(12),
                color: Colors.white54,
                selectedColor: AppColors.darkNavy,
                fillColor: AppColors.amber,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                children: const [
                  Text('IN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                  Text('CM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToggles() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Expanded(child: _buildToggleGroup(['MALE', 'FEMALE'], _gender, (v) => _switchGender(v))),
          const SizedBox(width: 12),
          Expanded(child: _buildToggleGroup(['Inches', 'CM'], _unit, (v) => setState(() => _unit = v))),
        ],
      ),
    );
  }

  Widget _buildToggleGroup(List<String> items, String current, Function(String) onSelect) {
    return Row(children: items.map((it) {
      final isSel = current == it;
      return Expanded(child: GestureDetector(onTap: () => onSelect(it), child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12), margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(color: isSel ? AppColors.amber : Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(12), border: isSel ? null : Border.all(color: Colors.white10)),
        alignment: Alignment.center, child: Text(it.toUpperCase(), style: TextStyle(color: isSel ? AppColors.darkNavy : Colors.white60, fontWeight: FontWeight.w900, fontSize: 10)),
      )));
    }).toList());
  }

  Widget _buildProgressBar(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      child: Row(children: List.generate(count, (i) => Expanded(child: Container(
        height: 3, margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(color: i <= _currentStep ? AppColors.amber : Colors.white10, borderRadius: BorderRadius.circular(2)),
      )))),
    );
  }

  List<Widget> _buildMenWizard() {
    return [
      _buildStep('Upper Structure', _maleMeasurements.sublist(0, 9)),
      _buildStep('Lower Structure', _maleMeasurements.sublist(9, 14)),
      _buildStep('Precision Fit', _maleMeasurements.sublist(14)),
    ];
  }

  List<Widget> _buildWomenWizard() {
    return [
      _buildStep('Upper Structure', _femaleMeasurements.sublist(0, 9)),
      _buildStep('Waist & Hips', _femaleMeasurements.sublist(9, 18)),
      _buildStep('Legs & Alignment', _femaleMeasurements.sublist(18)),
    ];
  }

  Widget _buildStep(String title, List<String> fields) {
    return LayoutBuilder(builder: (context, constraints) {
      final isDesktop = constraints.maxWidth > 1000;
      final station = _buildRiggingStation();
      final inputs = SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 2.8,
          children: fields.map((f) => _buildInput(f)).toList(),
        ),
        const SizedBox(height: 32),
      ]));

      return Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: isDesktop 
        ? Row(children: [Expanded(flex: 3, child: station), const SizedBox(width: 24), Expanded(flex: 2, child: inputs)])
        : Column(children: [Expanded(flex: 5, child: station), const SizedBox(height: 12), Expanded(flex: 4, child: inputs)]));
    });
  }

  Widget _buildInput(String label) {
    final isFocused = _focusedField == label;
    final isAiFilled = _aiFields.contains(label);
    
    return Focus(onFocusChange: (h) { if (h) _onFieldFocus(label); }, child: TextField(
      controller: _controllers[label],
      focusNode: _focusNodes[label],
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      style: TextStyle(
        color: isAiFilled ? Colors.greenAccent : Colors.white, 
        fontSize: 15, 
        fontWeight: FontWeight.w900
      ),
      decoration: InputDecoration(
        labelText: label.toUpperCase(), 
        labelStyle: TextStyle(color: isFocused ? Colors.white : (isAiFilled ? Colors.greenAccent.withValues(alpha: 0.5) : Colors.white38), fontSize: 7, fontWeight: FontWeight.w900),
        suffixText: _unit == 'Inches' ? 'IN' : 'CM', suffixStyle: const TextStyle(color: AppColors.amber, fontSize: 7, fontWeight: FontWeight.w900),
        filled: true, fillColor: isAiFilled ? Colors.greenAccent.withValues(alpha: 0.02) : Colors.white.withValues(alpha: 0.04),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isAiFilled ? Colors.greenAccent.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isAiFilled ? Colors.greenAccent : Colors.white)),
        prefixIcon: isAiFilled ? const Icon(Icons.auto_fix_normal_rounded, color: Colors.greenAccent, size: 10) : null,
      ),
      onChanged: (_) {
        if (isAiFilled) setState(() => _aiFields.remove(label));
      },
    ));
  }

  Widget _buildRiggingStation() {
    return Container(width: double.infinity, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white10)), child: ClipRRect(borderRadius: BorderRadius.circular(24), child: Row(children: [
      Expanded(child: Stack(alignment: Alignment.center, children: [
        if (_isModelAvailable == null) const CircularProgressIndicator(color: AppColors.amber)
        else if (_isModelAvailable == false) const Text('RIG ERROR', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900))
        else if (_show3D) O3D.asset(controller: _o3dController, src: _modelPath, autoRotate: false, backgroundColor: Colors.transparent, cameraTarget: CameraTarget(0, -0.4, 0), cameraOrbit: CameraOrbit(0, 75, 1.8)),
        Positioned(bottom: 12, left: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12)), child: const Text('RIG', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)))),
      ])),
      Container(width: 1, color: Colors.white10),
      Expanded(child: Stack(children: [
        if (_focusedField != null)
          StaticGuidedCrop(imagePath: _getAssetPath(_focusedField!), borderRadius: 0)
        else const Center(child: Icon(Icons.zoom_in, color: Colors.white10, size: 40)),
        Positioned(bottom: 12, right: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.amber.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(12)), child: const Text('ZOOM', style: TextStyle(color: AppColors.darkNavy, fontSize: 8, fontWeight: FontWeight.w900)))),
      ])),
    ])));
  }

  Widget _buildBottomAction(int total) {
    return Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: const Color(0xFF0A1921), border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05)))), child: SafeArea(child: Row(children: [
      if (_currentStep > 0) Padding(padding: const EdgeInsets.only(right: 12), child: IconButton(onPressed: _prev, icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white38, size: 18), style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.03), padding: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
      Expanded(child: SizedBox(height: 56, child: ElevatedButton(onPressed: () => _next(total), style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber, foregroundColor: AppColors.darkNavy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(_currentStep == total - 1 ? 'ESTABLISH PROFILE' : 'CONTINUE', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13)), const SizedBox(width: 8), const Icon(Icons.arrow_forward_rounded, size: 18)]))))
    ])));
  }

  Widget _buildStyleSelector(String label, String currentValue, List<String> options, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: options.map((opt) {
            final isSelected = currentValue == opt;
            return InkWell(
              onTap: () => onChanged(opt),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.amber : Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected ? null : Border.all(color: Colors.white10),
                ),
                child: Text(opt.toUpperCase(), style: TextStyle(color: isSelected ? AppColors.darkNavy : Colors.white70, fontSize: 10, fontWeight: FontWeight.w900)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBudgetSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('BUDGET RANGE (NGN)', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _buildBudgetInput('MIN', _budgetMinController, (v) => setState(() => _budgetMin = v))),
          const SizedBox(width: 16),
          const Icon(Icons.arrow_forward, color: Colors.white24, size: 20),
          const SizedBox(width: 16),
          Expanded(child: _buildBudgetInput('MAX', _budgetMaxController, (v) => setState(() => _budgetMax = v))),
        ]),
      ],
    );
  }

  Widget _buildBudgetInput(String label, TextEditingController controller, Function(double) onChanged) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900),
        prefixText: '₦ ', prefixStyle: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.w900),
        filled: true, fillColor: Colors.white.withValues(alpha: 0.03),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      onChanged: (text) {
        final parsed = double.tryParse(text.replaceAll(RegExp(r'[^0-9.]'), ''));
        if (parsed != null) {
          onChanged(parsed);
        }
      },
    );
  }

  static const List<String> _occasions = ['Casual', 'Corporate', 'Wedding', 'Cultural Event', 'Party', 'Resort', 'Funeral', 'Business Meeting'];
  static const List<String> _colors = ['Black', 'White', 'Navy', 'Brown', 'Green', 'Red', 'Blue', 'Beige', 'Grey', 'Gold', 'Silver', 'Multi'];
  static const List<String> _fabrics = ['Cotton', 'Linen', 'Silk', 'Wool', 'Chiffon', 'Lace', 'Ankara', 'Aso Oke', 'George', 'Denim', 'Velvet'];
}
