import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../../core/constants/nigeria_lga_data.dart';
import '../../../../core/widgets/onboarding_scaffold.dart';
import '../../../../theme/colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

class ClientOnboardingPage extends ConsumerStatefulWidget {
  const ClientOnboardingPage({super.key});

  @override
  ConsumerState<ClientOnboardingPage> createState() => _ClientOnboardingPageState();
}

class _ClientOnboardingPageState extends ConsumerState<ClientOnboardingPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Data State
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  String _selectedGender = 'MALE';
  String? _selectedCountry = 'Nigeria';
  String? _selectedState;
  String? _selectedLga;
  List<String> _availableLgas = [];

  String _selectedOccasion = 'Casual';
  String _selectedColor = 'Black';
  String _selectedFabric = 'Cotton';
  double _budgetMin = 50000;
  double _budgetMax = 150000;

  String _selectedBodyType = 'Average';
  String _selectedUnit = 'Inches';

  bool _isLoading = false;

  static const List<String> genderOptions = ['MALE', 'FEMALE'];
  static const List<String> occasionOptions = ['Casual', 'Business', 'Formal', 'Traditional', 'Wedding', 'Party'];
  static const List<String> bodyTypeOptions = ['Slim', 'Average', 'Athletic', 'Curvy', 'Plus Size'];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  bool get _isCurrentStepValid {
    switch (_currentStep) {
      case 0: return _nameController.text.isNotEmpty && _phoneController.text.isNotEmpty && _selectedState != null && _selectedLga != null;
      case 1: return _selectedOccasion.isNotEmpty;
      case 2: return _selectedBodyType.isNotEmpty;
      default: return true;
    }
  }

  void _nextStep() {
    if (!_isCurrentStepValid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete all required fields'), backgroundColor: Colors.orangeAccent));
      return;
    }
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic);
    } else {
      _finishOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic);
    }
  }

  Future<void> _finishOnboarding() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final updatedProfile = UserProfile(
        id: user.id, email: _emailController.text, name: _nameController.text, userType: user.userType,
        phone: _phoneController.text, address: _addressController.text,
        state: _selectedState ?? '', country: _selectedCountry ?? 'Nigeria', lga: _selectedLga ?? '',
        createdAt: user.createdAt, updatedAt: DateTime.now(),
        // EXPERT SYNC: Persist Lifestyle & Style Preferences
        preferredOccasions: [_selectedOccasion],
        preferredFabrics: [_selectedFabric],
        bodyType: _selectedBodyType,
        measurementUnit: _selectedUnit,
      );

      await ref.read(updateProfileUsecaseProvider)(updatedProfile);
      await localStorage.save(StorageKeys.clientOnboardingComplete, true);
      if (mounted) Navigator.of(context).pushReplacementNamed('/main');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      currentStep: _currentStep,
      totalSteps: _totalSteps,
      title: 'Welcome to Desby OS',
      stepLabel: 'Step ${_currentStep + 1} of $_totalSteps',
      prompt: _getPrompt(),
      isLoading: _isLoading,
      nextLabel: _currentStep == _totalSteps - 1 ? 'DISCOVER TAILORS' : 'CONTINUE',
      onBack: _currentStep > 0 ? _previousStep : null,
      onNext: _nextStep,
      content: SizedBox(
        height: 500,
        child: PageView(
          controller: _pageController,
          onPageChanged: (i) => setState(() => _currentStep = i),
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildPersonalDetailsStep(),
            _buildStylePreferencesStep(),
            _buildBodyTypeStep(),
            _buildReviewStep(),
          ],
        ),
      ),
    );
  }

  String _getPrompt() {
    switch (_currentStep) {
      case 0: return 'Tell us about yourself';
      case 1: return 'Help us understand your taste';
      case 2: return 'What is your body type?';
      case 3: return 'Ready for the perfect fit?';
      default: return 'Setup your profile';
    }
  }

  Widget _buildPersonalDetailsStep() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildField('FULL NAME', Icons.person_rounded, _nameController),
          const SizedBox(height: 16),
          _buildField('PHONE NUMBER', Icons.phone_rounded, _phoneController, type: TextInputType.phone),
          const SizedBox(height: 16),
          _buildDropdown('GENDER', Icons.face_rounded, _selectedGender, genderOptions, (v) => setState(() => _selectedGender = v!)),
          const SizedBox(height: 16),
          _buildDropdown('STATE', Icons.map_rounded, _selectedState, NigeriaLgaData.states, (v) {
            setState(() { _selectedState = v; _selectedLga = null; _availableLgas = v != null ? NigeriaLgaData.getLgasForState(v) : []; });
          }),
          const SizedBox(height: 16),
          _buildDropdown('LGA', Icons.location_city_rounded, _selectedLga, _availableLgas, (v) => setState(() => _selectedLga = v), enabled: _selectedState != null),
        ],
      ),
    );
  }

  Widget _buildStylePreferencesStep() {
    return Column(
      children: [
        const Text('PREFERRED OCCASION', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12, runSpacing: 12, alignment: WrapAlignment.center,
          children: occasionOptions.map((o) => OptionPill(
            label: o, isSelected: _selectedOccasion == o,
            onTap: () => setState(() => _selectedOccasion = o),
          )).toList(),
        ),
        const SizedBox(height: 32),
        const Text('PREFERRED FABRIC', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12, runSpacing: 12, alignment: WrapAlignment.center,
          children: ['Cotton', 'Silk', 'Linen', 'Wool', 'Lace'].map((f) => OptionPill(
            label: f, isSelected: _selectedFabric == f,
            onTap: () => setState(() => _selectedFabric = f),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildBodyTypeStep() {
    return Column(
      children: [
        const Text('BODY TYPE', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12, runSpacing: 12, alignment: WrapAlignment.center,
          children: bodyTypeOptions.map((b) => OptionPill(
            label: b, isSelected: _selectedBodyType == b,
            onTap: () => setState(() => _selectedBodyType = b),
          )).toList(),
        ),
        const SizedBox(height: 32),
        _buildDropdown('MEASUREMENT UNIT', Icons.straighten_rounded, _selectedUnit, ['Inches', 'Centimeters'], (v) => setState(() => _selectedUnit = v!)),
      ],
    );
  }

  Widget _buildReviewStep() {
    return Column(
      children: [
        _buildReviewCard('IDENTITY', '${_nameController.text}\n${_phoneController.text}'),
        const SizedBox(height: 16),
        _buildReviewCard('LOCATION', '$_selectedLga, $_selectedState'),
        const SizedBox(height: 16),
        _buildReviewCard('STYLE', '$_selectedOccasion • $_selectedFabric'),
      ],
    );
  }

  Widget _buildReviewCard(String label, String value) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildField(String label, IconData icon, TextEditingController controller, {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: controller, keyboardType: type,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900),
        prefixIcon: Icon(icon, color: AppColors.amber, size: 20),
        filled: true, fillColor: Colors.white.withValues(alpha: 0.03),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppColors.amber)),
      ),
    );
  }

  Widget _buildDropdown(String label, IconData icon, String? value, List<String> items, Function(String?) onChanged, {bool enabled = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(18)),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          initialValue: value, items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white, fontSize: 14)))).toList(),
          onChanged: enabled ? onChanged : null,
          decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900), prefixIcon: Icon(icon, color: AppColors.amber, size: 20), border: InputBorder.none),
          dropdownColor: AppColors.darkNavy, icon: const Icon(Icons.expand_more_rounded, color: Colors.white24),
        ),
      ),
    );
  }
}
