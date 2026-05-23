import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/colors.dart';
import '../../../../core/utils/async_handler.dart';
import '../../domain/entities/client.dart';
import '../providers/client_provider.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/presentation/providers/order_provider.dart';
import '../../../designs/presentation/widgets/guided_crop_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
// ignore: depend_on_referenced_packages
import 'package:o3d/o3d.dart';

class UnifiedAddClientPage extends ConsumerStatefulWidget {
  const UnifiedAddClientPage({super.key});

  @override
  ConsumerState<UnifiedAddClientPage> createState() => _UnifiedAddClientPageState();
}

class _UnifiedAddClientPageState extends ConsumerState<UnifiedAddClientPage> with AsyncHandler {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final O3DController _o3dController = O3DController();

  final _textOnlyFormatter = FilteringTextInputFormatter.deny(RegExp(r'[\d]'));

  // 3D & 2D STATE
  bool? _isCurrentModelAssetAvailable;
  bool _show3DViewer = true;
  String? _focusedField;

  String get _modelAssetPath => _selectedGender == 'FEMALE'
      ? 'assets/models/female_mannequin.glb'
      : 'assets/models/male_mannequin.glb';

  // --- GUIDANCE ASSET MAPPING ---
  String _getGuidanceAsset(String field) {
    const String base = 'images/guidance';
    final Map<String, String> mapping = {
      'Shoulder': 'shoulder.jpg.jpeg',
      'Neck Round': 'neck_round.jpg.jpeg',
      'Chest Round': 'chest_round.jpg.jpeg',
      'Bust Round': 'female_bust_round.png', 
      'Stomach Round': 'stomach_round.jpg.jpeg',
      'Waist Round': 'waist_round.jpg.jpeg',
      'Trouser Waist': 'trouser_waist.jpg.jpeg',
      'Half Length': 'half_length.jpg.jpeg',
      'Across Back': 'across_back.jpg.jpeg',
      'Across Chest': 'across_chest.jpg.jpeg',
      'Upper Bicep': 'upper_bicep.jpg.jpeg',
      'Bicep Round': 'upper_bicep.jpg.jpeg',
      'Hip Round': 'hip_round.jpg.jpeg',
      'Thigh Round': 'thigh_round.jpg.jpeg',
      'Knee Round': 'knee_round.jpg.jpeg',
      'Calf Round': 'calf_round.jpg.jpeg',
      'Ankle Round': 'ankle_round.jpg.jpeg',
      'Trouser Length': 'trouser_length.jpg.jpeg',
      'Full Top Length': 'full_top_length.jpg.jpeg',
      'Bust Point': 'female_bust_point.png',
      'High Bust': 'female_high_bust.png',
      'Under Bust': 'female_under-bust.png',
      'Shoulder to Waist': 'female_shoulder_to_waist.png',
      'Inseam': 'inseam.jpg.jpeg',
      'Crotch Depth': 'crotch_depth.jpg.jpeg',
    };

    if (_selectedGender == 'FEMALE') {
       if (field == 'Neck Round') return '$base/female_neck_round.png';
       if (field == 'Shoulder') return '$base/female_shoulder.png';
       if (field == 'Half Length') return '$base/female_half_length.png';
    }

    if (mapping.containsKey(field)) return '$base/${mapping[field]}';
    return '$base/${field.toLowerCase().replaceAll(' ', '_')}.jpg.jpeg';
  }

  // Personal Info
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _heightController = TextEditingController(); // ADDED HEIGHT
  String _selectedGender = 'MALE'; 
  String _unit = 'Inches';

  // Project Info
  String _selectedGarment = 'Suit';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 14));
  
  // Multi-Selection Style Preferences (CARD STYLE)
  final Set<String> _selectedOccasions = {'Casual'};
  final Set<String> _selectedColors = {'Black'};
  final Set<String> _selectedFabrics = {'Cotton'};
  double _budgetMin = 50000;
  double _budgetMax = 150000;

  // Measurement State
  final Map<String, TextEditingController> _measurementControllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _checkCurrentModelAsset();
    
    _nameController.addListener(_onTextChanged);
    _phoneController.addListener(_onTextChanged);
    _addressController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _checkCurrentModelAsset() async {
    final modelSrc = _modelAssetPath;
    setState(() => _isCurrentModelAssetAvailable = null);
    try {
      await rootBundle.load(modelSrc);
      if (mounted) setState(() => _isCurrentModelAssetAvailable = true);
    } catch (e) {
      debugPrint('❌ [3D] Asset missing: $modelSrc');
      if (mounted) setState(() => _isCurrentModelAssetAvailable = false);
    }
  }

  void _restart3DViewerSafely() {
    if (!mounted) return;
    setState(() => _show3DViewer = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _show3DViewer = true);
    });
  }

  void _initializeControllers() {
    final allParams = [
      'Shoulder', 'Neck Round', 'Bust Round', 'High Bust', 'Under Bust', 
      'Bust Point', 'Shoulder to Bust Point', 'Shoulder to Under Bust', 
      'Shoulder to Waist', 'Front Waist Length', 'Back Waist Length', 
      'Across Chest', 'Across Back', 'Armhole Round', 'Sleeve Length', 
      'Bicep Round', 'Elbow Round', 'Wrist Round', 'Waist Round', 
      'Half Length', 'Waist to Hip', 'Upper Hip', 'Hip Round', 
      'Thigh Round', 'Knee Round', 'Calf Round', 'Ankle Round', 
      'Waist to Knee', 'Waist to Calf', 'Waist to Floor', 'Full Dress Length', 
      'Skirt Length', 'Wrapper Length', 'Corset Front Length', 
      'Corset Side Length', 'Corset Back Length', 'Under Bust to Waist', 
      'Waist to Lower Corset Edge', 'Cup Size', 'Stomach Round', 
      'Full Top Length', 'Shirt Length', 'Chest Round', 
      'Trouser Waist', 'Trouser Length', 'Inseam', 'Crotch Depth', 'Rise', 
      'Seat Round', 'Senator Length', 'Kaftan Length', 'Agbada Length', 
      'Agbada Sleeve Length', 'Jacket Length', 'Lapel Width', 
      'Jacket Sleeve Length', 'Trouser Opening Width', 'Vest Length'
    ];
    for (var p in allParams) {
      _measurementControllers[p] = TextEditingController();
      _focusNodes[p] = FocusNode();
      _focusNodes[p]!.addListener(() {
        if (_focusNodes[p]!.hasFocus) _focusOn(p);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _heightController.dispose();
    _measurementControllers.forEach((_, c) => c.dispose());
    _focusNodes.forEach((_, n) => n.dispose());
    super.dispose();
  }

  // --- NAVIGATION ---
  bool _isStepValid() {
    if (_currentStep == 0) {
      final nameValid = _nameController.text.isNotEmpty;
      final phoneValid = _phoneController.text.isNotEmpty && RegExp(r'^[\d]+$').hasMatch(_phoneController.text);
      final heightValid = _heightController.text.isNotEmpty;
      return nameValid && phoneValid && _addressController.text.isNotEmpty && heightValid;
    }
    if (_currentStep == 1) return _selectedGarment.isNotEmpty;
    return true; 
  }

  void _nextStep(int lastStep) {
    FocusManager.instance.primaryFocus?.unfocus();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      if (!_isStepValid()) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Identity, Height and logistics are mandatory.'), backgroundColor: Colors.orange));
        return;
      }
      if (_currentStep < lastStep) {
        _pageController.nextPage(duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic);
      } else {
        _finish();
      }
    });
  }

  void _prevStep() {
    FocusManager.instance.primaryFocus?.unfocus();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      _pageController.previousPage(duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic);
    });
  }

  void _finish() async {
    await handleAsync(context, () async {
      final Map<String, String> measurementMap = {
        'Height': _heightController.text, // INCLUDE HEIGHT
      };
      _measurementControllers.forEach((key, controller) {
        if (controller.text.isNotEmpty) measurementMap[key] = controller.text;
      });

      final client = Client(
        id: 'CL_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text, email: _emailController.text, phone: _phoneController.text,
        address: _addressController.text, gender: _selectedGender,
        createdAt: DateTime.now(), measurements: measurementMap,
      );

      await ref.read(createClientUsecaseProvider)(client);

      final orderId = 'ORD_${DateTime.now().millisecondsSinceEpoch}';
      final order = OrderEntity(
        id: orderId, clientId: client.id, clientName: client.name,
        status: OrderStatus.pending, totalAmount: 0.0, dueDate: _dueDate, createdAt: DateTime.now(),
        items: [OrderItem(id: 'item_$orderId', garmentType: _selectedGarment, price: 0.0, measurements: measurementMap)],
      );

      await ref.read(createOrderUsecaseProvider)(order);
    }, successMessage: 'Booking complete. Processing design.');

    if (mounted) {
      ref.invalidate(clientsProvider(null));
      Navigator.pop(context);
    }
  }

  // --- RIGGING STATION ---
  void _focusOn(String part) {
    if (_focusedField == part) return;
    setState(() => _focusedField = part);

    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted || _focusedField != part) return;
      final double centerX = 0.0;
      final double centerZ = 0.0;

      switch (part) {
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
      _buildPersonalInfoStep(),
      _buildOrderStep(),
      ...(_selectedGender == 'FEMALE' ? _buildWomenWizard() : _buildMenWizard()),
      _buildReviewStep(), 
    ];

    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard Progress?'),
            content: const Text('You will lose all entered measurements and client details.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('KEEP EDITING')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('DISCARD', style: TextStyle(color: Colors.redAccent))),
            ],
          ),
        );

        if (confirmed == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0A1921),
        appBar: AppBar(
          title: const Text('NEW BOOKING', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
          backgroundColor: Colors.transparent, elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.amber, size: 18),
            onPressed: () {
              if (_currentStep == 0) {
                Navigator.pop(context);
              } else {
                // Trigger PopScope logic
                Navigator.maybePop(context);
              }
            },
          ),
        ),
        body: Column(
          children: [
            _buildProgressIndicator(steps.length),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentStep = i),
                physics: const NeverScrollableScrollPhysics(),
                children: steps,
              ),
            ),
            _buildBottomAction(steps.length - 1),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
      child: Row(
        children: List.generate(count, (index) => Expanded(
          child: Container(
            height: 3, margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(color: index <= _currentStep ? AppColors.amber : Colors.white10, borderRadius: BorderRadius.circular(2)),
          ),
        )),
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader('Identity Verification', 'Capture core contact and gender data.'),
          const SizedBox(height: 32),
          _buildGenderSelector(),
          const SizedBox(height: 24),
          _buildUnitSelector(),
          const SizedBox(height: 32),
          _buildField('FULL NAME *', Icons.person_outline, _nameController, isTextOnly: true),
          _buildField('EMAIL ADDRESS', Icons.email_outlined, _emailController, type: TextInputType.emailAddress),
          _buildField('PHONE NUMBER *', Icons.phone_outlined, _phoneController, type: TextInputType.phone, isNumberOnly: true),
          _buildField('PHYSICAL HEIGHT *', Icons.height_rounded, _heightController, type: TextInputType.number, isNumberOnly: true), 
          _buildField('DELIVERY ADDRESS *', Icons.location_on_outlined, _addressController),
        ],
      ),
    );
  }

  Widget _buildOrderStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader('Project Definition', 'Define the masterpiece architecture.'),
          const SizedBox(height: 32),
          _buildGarmentSelector(),
          const SizedBox(height: 48),
          _buildDatePicker(),
          const SizedBox(height: 48),
          _buildStylePreferences(),
        ],
      ),
    );
  }

  Widget _buildStylePreferences() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('STYLE PREFERENCES', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 24),
        _buildStyleCardSelector('OCCASIONS', _selectedOccasions, _occasions),
        const SizedBox(height: 24),
        _buildStyleCardSelector('COLORS', _selectedColors, _colors),
        const SizedBox(height: 24),
        _buildStyleCardSelector('FABRICS', _selectedFabrics, _fabrics),
        const SizedBox(height: 32),
        _buildBudgetSlider(),
      ],
    );
  }

  Widget _buildStyleCardSelector(String label, Set<String> selection, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.2,
          ),
          itemCount: options.length,
          itemBuilder: (context, index) {
            final opt = options[index];
            final isSelected = selection.contains(opt);
            return InkWell(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    if (selection.length > 1) selection.remove(opt);
                  } else {
                    selection.add(opt);
                  }
                });
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.amber : Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected ? null : Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Text(opt.toUpperCase(), style: TextStyle(color: isSelected ? AppColors.darkNavy : Colors.white60, fontSize: 8, fontWeight: FontWeight.w900)),
              ),
            );
          },
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
          Expanded(child: _buildBudgetInput('MIN', _budgetMin, (v) => setState(() => _budgetMin = v))),
          const SizedBox(width: 16),
          const Icon(Icons.arrow_forward, color: Colors.white24, size: 20),
          const SizedBox(width: 16),
          Expanded(child: _buildBudgetInput('MAX', _budgetMax, (v) => setState(() => _budgetMax = v))),
        ]),
      ],
    );
  }

  Widget _buildBudgetInput(String label, double value, Function(double) onChanged) {
    return TextField(
      keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900),
        prefixText: '₦ ', prefixStyle: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.w900),
        filled: true, fillColor: Colors.white.withValues(alpha: 0.03),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      onChanged: (text) {
        final parsed = double.tryParse(text.replaceAll(RegExp(r'[^\d.]'), ''));
        if (parsed != null) onChanged(parsed);
      },
    );
  }

  List<Widget> _buildWomenWizard() {
    return [
      _buildWizardStep('Upper Structure', ['Shoulder', 'Neck Round', 'Bust Round', 'High Bust', 'Under Bust', 'Bust Point', 'Shoulder to Bust Point', 'Shoulder to Under Bust', 'Shoulder to Waist']),
      _buildWizardStep('Waist & Hips', ['Front Waist Length', 'Back Waist Length', 'Waist Round', 'Half Length', 'Waist to Hip', 'Upper Hip', 'Hip Round']),
      _buildWizardStep('Legs & Alignment', ['Thigh Round', 'Knee Round', 'Calf Round', 'Ankle Round', 'Waist to Floor', 'Full Dress Length', 'Skirt Length']),
    ];
  }

  List<Widget> _buildMenWizard() {
    return [
      _buildWizardStep('Upper Structure', ['Shoulder', 'Neck Round', 'Chest Round', 'Stomach Round', 'Waist Round', 'Half Length', 'Full Top Length', 'Across Back', 'Across Chest']),
      _buildWizardStep('Lower Structure', ['Hip Round', 'Thigh Round', 'Knee Round', 'Calf Round', 'Ankle Round', 'Trouser Waist', 'Trouser Length', 'Inseam', 'Crotch Depth']),
      _buildWizardStep('Native & Suit', ['Senator Length', 'Kaftan Length', 'Agbada Length', 'Jacket Length', 'Vest Length']),
    ];
  }

  Widget _buildWizardStep(String title, List<String> fields) {
    return LayoutBuilder(builder: (context, constraints) {
      final isDesktop = constraints.maxWidth > 1000;
      final station = _buildRiggingStation();
      final inputs = SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 2.8,
              children: fields.map((f) => _buildUltraModernField(f)).toList(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      );

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: isDesktop 
          ? Row(children: [
              Expanded(flex: 3, child: station),
              const SizedBox(width: 24),
              Expanded(flex: 2, child: inputs),
            ])
          : Column(children: [
              Expanded(flex: 5, child: station), 
              const SizedBox(height: 12),
              Expanded(flex: 4, child: inputs),
            ]),
      );
    });
  }

  Widget _buildRiggingStation() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Row(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_isCurrentModelAssetAvailable == null)
                    const CircularProgressIndicator(color: AppColors.amber)
                  else if (_isCurrentModelAssetAvailable == false)
                    const Text('RIG ERROR', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900))
                  else if (_show3DViewer)
                    O3D.asset(
                      controller: _o3dController, src: _modelAssetPath,
                      autoRotate: false, backgroundColor: Colors.transparent, 
                      cameraTarget: CameraTarget(0, -0.4, 0), 
                      cameraOrbit: CameraOrbit(0, 75, 1.8) 
                    ),
                  Positioned(
                    bottom: 12, left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12)),
                      child: const Text('RIG', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ),
            Container(width: 1, color: Colors.white10),
            Expanded(
              child: Stack(
                children: [
                  if (_focusedField != null)
                    StaticGuidedCrop(
                      imagePath: _getGuidanceAsset(_focusedField!), 
                      borderRadius: 0,
                    )
                  else
                    const Center(child: Icon(Icons.zoom_in, color: Colors.white10, size: 40)),
                  Positioned(
                    bottom: 12, right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.amber.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(12)),
                      child: const Text('ZOOM', style: TextStyle(color: AppColors.darkNavy, fontSize: 8, fontWeight: FontWeight.w900)),
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

  Widget _buildGenderSelector() {
    return Row(children: ['MALE', 'FEMALE'].map((g) {
      final isSelected = _selectedGender == g;
      return Expanded(child: Padding(padding: const EdgeInsets.only(right: 8.0), child: InkWell(onTap: () {
        if (_selectedGender == g) return;
        setState(() => _selectedGender = g);
        _restart3DViewerSafely();
        _checkCurrentModelAsset();
      }, child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: isSelected ? AppColors.amber : Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(16), border: isSelected ? null : Border.all(color: Colors.white10)), alignment: Alignment.center, child: Text(g, style: TextStyle(color: isSelected ? AppColors.darkNavy : Colors.white60, fontWeight: FontWeight.w900, fontSize: 11))))));
    }).toList());
  }

  Widget _buildUnitSelector() {
    return Row(children: ['Inches', 'Centimeters'].map((u) {
      final isSelected = _unit == u;
      return Expanded(child: Padding(padding: const EdgeInsets.only(right: 8.0), child: InkWell(onTap: () => setState(() => _unit = u), child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: isSelected ? AppColors.amber : Colors.white10.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: isSelected ? null : Border.all(color: Colors.white10)), alignment: Alignment.center, child: Text(u.toUpperCase(), style: TextStyle(color: isSelected ? AppColors.darkNavy : Colors.white60, fontWeight: FontWeight.w900, fontSize: 11))))));
    }).toList());
  }

  Widget _buildStepHeader(String title, String sub) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1)),
      const SizedBox(height: 4),
      Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 13)),
    ]);
  }

  Widget _buildField(String label, IconData icon, TextEditingController controller, {TextInputType type = TextInputType.text, bool isTextOnly = false, bool isNumberOnly = false, bool isReadOnly = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller, keyboardType: type,
        readOnly: isReadOnly,
        inputFormatters: isNumberOnly ? [FilteringTextInputFormatter.digitsOnly] : isTextOnly ? [_textOnlyFormatter] : null,
        style: TextStyle(color: isReadOnly ? Colors.white38 : Colors.white, fontWeight: FontWeight.bold), 
        decoration: InputDecoration(
          labelText: label, labelStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
          prefixIcon: Icon(icon, size: 20, color: isReadOnly ? Colors.white12 : AppColors.amber), 
          filled: true, fillColor: Colors.white.withValues(alpha: 0.03), 
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none)
        ),
      ),
    );
  }

  Widget _buildUltraModernField(String label) {
    final isFocused = _focusedField == label;
    return Focus(
      onFocusChange: (h) { if (h) _focusOn(label); },
      child: TextField(
        controller: _measurementControllers[label],
        focusNode: _focusNodes[label],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900), 
        decoration: InputDecoration(
          labelText: label.toUpperCase(), 
          labelStyle: TextStyle(color: isFocused ? Colors.white : Colors.white54, fontSize: 8, fontWeight: FontWeight.w900),
          suffixText: _unit == 'Inches' ? 'IN' : 'CM', 
          suffixStyle: const TextStyle(color: AppColors.amber, fontSize: 8, fontWeight: FontWeight.w900), 
          filled: true, fillColor: Colors.white.withValues(alpha: 0.04), 
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))), 
focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white)),
          contentPadding: const EdgeInsets.symmetric(vertical: 0)
        ),
      ),
    );
  }

  Widget _buildGarmentSelector() {
    final types = _selectedGender == 'MALE' ? _maleGarments : _femaleGarments;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_selectedGender == 'MALE' ? 'MALE GARMENTS' : 'FEMALE GARMENTS', style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 16),
        Wrap(spacing: 12, runSpacing: 12, children: types.map((type) {
            final isSelected = _selectedGarment == type;
            return InkWell(onTap: () => setState(() => _selectedGarment = type), child: Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), decoration: BoxDecoration(color: isSelected ? AppColors.amber : Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(16), border: isSelected ? null : Border.all(color: Colors.white10)), child: Text(type.toUpperCase(), style: TextStyle(color: isSelected ? AppColors.darkNavy : Colors.white70, fontWeight: FontWeight.w900, fontSize: 11))));
          }).toList()),
      ],
    );
  }

  Widget _buildDatePicker() {
    return InkWell(onTap: () async {
        final date = await showDatePicker(context: context, initialDate: _dueDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
        if (date != null) setState(() => _dueDate = date);
      }, child: Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)), child: Row(children: [const Icon(Icons.calendar_today_outlined, color: AppColors.amber, size: 20), const SizedBox(width: 20), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('HANDOVER TARGET', style: TextStyle(fontSize: 9, color: Colors.white24, fontWeight: FontWeight.w900)), Text(_dueDate.toString().split(' ')[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16))]), const Spacer(), const Icon(Icons.edit_calendar_outlined, color: Colors.white10)])));
  }

  Widget _buildReviewStep() {
    final Map<String, String> m = {};
    _measurementControllers.forEach((key, controller) {
      if (controller.text.isNotEmpty) m[key] = controller.text;
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader('Review & Confirm', 'Verify all architecture details.'),
          const SizedBox(height: 32),
          _buildReviewCard('IDENTITY', {
            'NAME': _nameController.text,
            'PHONE': _phoneController.text,
            'EMAIL': _emailController.text,
            'HEIGHT': '${_heightController.text} $_unit',
            'GENDER': _selectedGender,
          }),
          const SizedBox(height: 24),
          _buildReviewCard('ARCHITECTURE', {
            'GARMENT': _selectedGarment,
            'OCCASIONS': _selectedOccasions.join(', '),
            'COLORS': _selectedColors.join(', '),
            'FABRICS': _selectedFabrics.join(', '),
            'DUE DATE': _dueDate.toString().split(' ')[0],
          }),
          const SizedBox(height: 24),
          _buildReviewCard('MEASUREMENTS', m),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildReviewCard(String title, Map<String, String> data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          ...data.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(e.key, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w700)),
                Text(e.value.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildBottomAction(int lastStep) {
    return Container(padding: const EdgeInsets.all(32), decoration: BoxDecoration(color: const Color(0xFF0A1921), border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05)))), child: SafeArea(child: Row(children: [
      if (_currentStep > 0) Padding(padding: const EdgeInsets.only(right: 16.0), child: IconButton(onPressed: _prevStep, icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white38), style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.03), padding: const EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
      Expanded(child: SizedBox(height: 64, child: ElevatedButton(onPressed: () => _nextStep(lastStep), style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber, foregroundColor: AppColors.darkNavy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(_currentStep == lastStep ? 'FINISH SETUP' : 'CONTINUE', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)), const SizedBox(width: 12), const Icon(Icons.arrow_forward_rounded)]))))
    ])));
  }

  static const List<String> _maleGarments = ['Suit', 'Agbada', 'Kaftan', 'Senator', 'Shirt', 'Jacket', 'Trousers', 'Jeans', 'Shorts', 'Tuxedo', 'Polo', 'Babariga'];
  static const List<String> _femaleGarments = ['Dress', 'Ankara', 'Aso Ebi', 'Gown', 'Blazer', 'Trousers', 'Skirt', 'Jeans', 'Jumpsuit', 'Maxi', 'Midi', 'Bridal Gown', 'Lace', 'Kaftan', 'Iro & Buba', 'Boubou'];
  static const List<String> _occasions = ['Casual', 'Corporate', 'Wedding', 'Cultural', 'Party', 'Resort', 'Funeral', 'Business'];
  static const List<String> _colors = ['Black', 'White', 'Navy', 'Brown', 'Green', 'Red', 'Blue', 'Beige', 'Grey', 'Gold', 'Silver', 'Multi'];
  static const List<String> _fabrics = ['Cotton', 'Linen', 'Silk', 'Wool', 'Chiffon', 'Lace', 'Ankara', 'Aso Oke', 'George', 'Denim', 'Velvet'];
}
