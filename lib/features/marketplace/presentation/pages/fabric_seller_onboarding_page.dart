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

class FabricSellerOnboardingPage extends ConsumerStatefulWidget {
  const FabricSellerOnboardingPage({super.key});

  @override
  ConsumerState<FabricSellerOnboardingPage> createState() => _FabricSellerOnboardingPageState();
}

class _FabricSellerOnboardingPageState extends ConsumerState<FabricSellerOnboardingPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Data State
  final _businessNameController = TextEditingController();
  final _businessPhoneController = TextEditingController();
  final _businessAddressController = TextEditingController();
  
  // WEB STABILITY: Explicit Focus Nodes
  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _stateFocus = FocusNode();
  final _lgaFocus = FocusNode();
  final _yardageFocus = FocusNode();
  final _rangeFocus = FocusNode();

  String? _selectedCountry = 'Nigeria';
  String? _selectedState;
  String? _selectedLga;
  List<String> _availableLgas = [];

  final List<String> _selectedFabricTypes = [];
  static const List<String> availableFabricTypes = ['Cotton', 'Silk', 'Linen', 'Wool', 'Chiffon', 'Satin', 'Ankara', 'Lace', 'Damask', 'Crepe'];

  final _estimatedYardageController = TextEditingController();
  String _priceRange = 'Mid-Range';
  bool _offersCustomOrders = false;
  bool _offersWholesale = false;

  bool _isLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    _businessNameController.dispose();
    _businessPhoneController.dispose();
    _businessAddressController.dispose();
    _estimatedYardageController.dispose();
    
    // Dispose focus nodes
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _addressFocus.dispose();
    _stateFocus.dispose();
    _lgaFocus.dispose();
    _yardageFocus.dispose();
    _rangeFocus.dispose();
    super.dispose();
  }

  bool get _isCurrentStepValid {
    switch (_currentStep) {
      case 0: return _businessNameController.text.isNotEmpty && _businessPhoneController.text.isNotEmpty && _selectedState != null && _selectedLga != null;
      case 1: return _selectedFabricTypes.isNotEmpty;
      case 2: return _estimatedYardageController.text.isNotEmpty;
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
    // WEB STABILITY: Force terminal unfocus
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() => _isLoading = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final updatedProfile = UserProfile(
        id: user.id, email: user.email, name: user.name, userType: user.userType,
        phone: _businessPhoneController.text, address: _businessAddressController.text,
        state: _selectedState ?? '', businessName: _businessNameController.text,
        businessAddress: _businessAddressController.text, businessPhone: _businessPhoneController.text,
        country: _selectedCountry ?? 'Nigeria', lga: _selectedLga ?? '',
        createdAt: user.createdAt, updatedAt: DateTime.now(),
      );

      await ref.read(updateProfileUsecaseProvider)(updatedProfile);
      await localStorage.save(StorageKeys.fabricSellerOnboardingComplete, true);
      
      // Delay navigation slightly to let DOM state settle after unfocus
      await Future.delayed(const Duration(milliseconds: 250));
      
      if (mounted) Navigator.of(context).pushReplacementNamed('/subscription-plans');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save profile. Please try again.'), backgroundColor: Colors.redAccent));
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
      nextLabel: _currentStep == _totalSteps - 1 ? 'OPEN STORE' : 'CONTINUE',
      onBack: _currentStep > 0 ? _previousStep : null,
      onNext: _nextStep,
      content: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 400, maxHeight: 600),
        child: PageView(
          controller: _pageController,
          onPageChanged: (i) {
            FocusScope.of(context).unfocus();
            setState(() => _currentStep = i);
          },
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildBusinessDetailsStep(),
            _buildFabricTypesStep(),
            _buildInventoryDetailsStep(),
            _buildReviewStep(),
          ],
        ),
      ),
    );
  }

  String _getPrompt() {
    switch (_currentStep) {
      case 0: return 'Tell us about your business';
      case 1: return 'What fabrics do you supply?';
      case 2: return 'Inventory & Pricing';
      case 3: return 'Ready to supply tailors?';
      default: return 'Setup your profile';
    }
  }

  Widget _buildBusinessDetailsStep() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildField('BUSINESS NAME', Icons.store_rounded, _businessNameController, focusNode: _nameFocus),
          const SizedBox(height: 16),
          _buildField('BUSINESS PHONE', Icons.phone_rounded, _businessPhoneController, type: TextInputType.phone, focusNode: _phoneFocus),
          const SizedBox(height: 16),
          _buildField('BUSINESS ADDRESS', Icons.location_on_rounded, _businessAddressController, focusNode: _addressFocus),
          const SizedBox(height: 16),
          _buildDropdown('STATE', Icons.map_rounded, _selectedState, NigeriaLgaData.states, (v) {
            setState(() { _selectedState = v; _selectedLga = null; _availableLgas = v != null ? NigeriaLgaData.getLgasForState(v) : []; });
          }, focusNode: _stateFocus),
          const SizedBox(height: 16),
          _buildDropdown('LGA', Icons.location_city_rounded, _selectedLga, _availableLgas, (v) => setState(() => _selectedLga = v), enabled: _selectedState != null, focusNode: _lgaFocus),
        ],
      ),
    );
  }

  Widget _buildFabricTypesStep() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Wrap(
        spacing: 12, runSpacing: 12, alignment: WrapAlignment.center,
        children: availableFabricTypes.map((f) => OptionPill(
          label: f, isSelected: _selectedFabricTypes.contains(f),
          onTap: () => setState(() => _selectedFabricTypes.contains(f) ? _selectedFabricTypes.remove(f) : _selectedFabricTypes.add(f)),
        )).toList(),
      ),
    );
  }

  Widget _buildInventoryDetailsStep() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildField('ESTIMATED MONTHLY YARDAGE', Icons.straighten_rounded, _estimatedYardageController, type: TextInputType.number, focusNode: _yardageFocus),
          const SizedBox(height: 16),
          _buildDropdown('PRICE RANGE', Icons.local_offer_rounded, _priceRange, ['Budget', 'Mid-Range', 'Premium', 'Luxury'], (v) => setState(() => _priceRange = v!), focusNode: _rangeFocus),
          const SizedBox(height: 24),
          _buildToggleTile('OFFERS CUSTOM ORDERS', _offersCustomOrders, (v) => setState(() => _offersCustomOrders = v)),
          const SizedBox(height: 12),
          _buildToggleTile('OFFERS WHOLESALE', _offersWholesale, (v) => setState(() => _offersWholesale = v)),
        ],
      ),
    );
  }

  Widget _buildToggleTile(String label, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(18), border: Border.all(color: value ? AppColors.amber.withValues(alpha: 0.3) : Colors.white10)),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: value ? Colors.white : Colors.white38, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const Spacer(),
          Switch.adaptive(value: value, activeTrackColor: AppColors.amber, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildReviewCard('BUSINESS', '${_businessNameController.text}\n${_businessAddressController.text}'),
          const SizedBox(height: 16),
          _buildReviewCard('FABRICS', _selectedFabricTypes.join(' • ').toUpperCase()),
          const SizedBox(height: 16),
          _buildReviewCard('INVENTORY', '$_priceRange • ${_estimatedYardageController.text} YDS/MO'),
        ],
      ),
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

  Widget _buildField(String label, IconData icon, TextEditingController controller, {TextInputType type = TextInputType.text, FocusNode? focusNode}) {
    return TextField(
      controller: controller, 
      keyboardType: type,
      focusNode: focusNode,
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

  Widget _buildDropdown(String label, IconData icon, String? value, List<String> items, Function(String?) onChanged, {bool enabled = true, FocusNode? focusNode}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(18)),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          initialValue: value, 
          focusNode: focusNode,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white, fontSize: 14)))).toList(),
          onChanged: enabled ? onChanged : null,
          decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900), prefixIcon: Icon(icon, color: AppColors.amber, size: 20), border: InputBorder.none),
          dropdownColor: AppColors.darkNavy, icon: const Icon(Icons.expand_more_rounded, color: Colors.white24),
        ),
      ),
    );
  }
}
