import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/nigeria_lga_data.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../../core/widgets/onboarding_scaffold.dart';
import '../../../../theme/colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/entities/apprenticeship.dart';
import '../providers/apprenticeship_provider.dart';

class ApprenticeOnboardingPage extends ConsumerStatefulWidget {
  final String? preSelectedMasterId;
  const ApprenticeOnboardingPage({super.key, this.preSelectedMasterId});

  @override
  ConsumerState<ApprenticeOnboardingPage> createState() => _ApprenticeOnboardingPageState();
}

class _ApprenticeOnboardingPageState extends ConsumerState<ApprenticeOnboardingPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 6;

  // Personal Details
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  String? _selectedState;
  String _selectedGender = 'MALE';

  // Apprenticeship Details
  final _bioController = TextEditingController();
  String _selectedLevel = 'Beginner';
  final List<String> _goals = [];
  bool _agreedToTraining = false;
  UserProfile? _selectedMaster;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user != null) _nameController.text = user.name;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  bool get _isStepValid {
    if (_currentStep == 0) return _nameController.text.isNotEmpty && _phoneController.text.isNotEmpty && _selectedState != null;
    if (_currentStep == 1) return _bioController.text.length > 20;
    if (_currentStep == 2) return _selectedLevel.isNotEmpty;
    if (_currentStep == 3) return _goals.isNotEmpty;
    if (_currentStep == 4) return widget.preSelectedMasterId != null || _selectedMaster != null;
    if (_currentStep == 5) return _agreedToTraining;
    return true;
  }

  void _nextStep() {
    if (!_isStepValid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete all required fields'), backgroundColor: Colors.orangeAccent));
      return;
    }
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic);
    } else {
      _finish();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic);
    }
  }

void _finish() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final profileUpdate = UserProfile(
      id: user.id, email: user.email, name: _nameController.text,
      userType: 'apprentice', phone: _phoneController.text,
      address: _addressController.text, state: _selectedState ?? '',
      bio: _bioController.text, createdAt: user.createdAt,
    );
    await ref.read(updateProfileUsecaseProvider)(profileUpdate);

    final isInvited = widget.preSelectedMasterId != null;
    final apprenticeship = Apprenticeship(
      id: 'APP_${DateTime.now().millisecondsSinceEpoch}',
      tailorId: widget.preSelectedMasterId ?? _selectedMaster!.id,
      apprenticeId: user.id,
      status: isInvited ? ApprenticeshipStatus.active : ApprenticeshipStatus.awaitingMasterApproval,
      progress: 0.0,
      startDate: DateTime.now(),
      skillIds: _goals,
    );

    await ref.read(apprenticeshipRepositoryProvider).createApprenticeship(apprenticeship);
    
    // Save onboarding completion status
    await localStorage.save(StorageKeys.apprenticeOnboardingComplete, true);
    
    if (mounted) Navigator.of(context).pushReplacementNamed('/subscription-plans');
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      currentStep: _currentStep,
      totalSteps: _totalSteps,
      title: 'Welcome to Desby OS',
      stepLabel: 'Step ${_currentStep + 1} of $_totalSteps',
      prompt: _getPrompt(),
      nextLabel: _currentStep == _totalSteps - 1 ? (widget.preSelectedMasterId != null ? 'START ACADEMY' : 'APPLY TO ACADEMY') : 'CONTINUE',
      onBack: _currentStep > 0 ? _previousStep : null,
      onNext: _nextStep,
      content: SizedBox(
        height: 500,
        child: PageView(
          controller: _pageController,
          onPageChanged: (i) => setState(() => _currentStep = i),
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildPersonalInfoStep(),
            _buildBioStep(),
            _buildExperienceStep(),
            _buildGoalsStep(),
            _buildMasterSearchStep(),
            _buildTermsStep(),
          ],
        ),
      ),
    );
  }

  String _getPrompt() {
    switch (_currentStep) {
      case 0: return 'Tell us about yourself';
      case 1: return 'About you';
      case 2: return 'What is your skill level?';
      case 3: return 'What are your goals?';
      case 4: return 'Find your master';
      case 5: return 'The apprentice pledge';
      default: return 'Setup your profile';
    }
  }

  Widget _buildPersonalInfoStep() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(children: ['MALE', 'FEMALE'].map((g) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: OptionPill(label: g, isSelected: _selectedGender == g, onTap: () => setState(() => _selectedGender = g))))).toList()),
          const SizedBox(height: 24),
          _buildField('FULL NAME', Icons.person_rounded, _nameController),
          const SizedBox(height: 16),
          _buildField('PHONE NUMBER', Icons.phone_rounded, _phoneController, type: TextInputType.phone),
          const SizedBox(height: 16),
          _buildField('RESIDENTIAL ADDRESS', Icons.location_on_rounded, _addressController),
          const SizedBox(height: 16),
          _buildDropdown('STATE', Icons.map_rounded, _selectedState, NigeriaLgaData.states, (v) => setState(() => _selectedState = v)),
        ],
      ),
    );
  }

  Widget _buildBioStep() {
    return Column(
      children: [
        TextField(
          controller: _bioController, maxLines: 5, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: 'Share your background and vision...',
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true, fillColor: Colors.white.withValues(alpha: 0.03),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Text('${_bioController.text.length}/20 characters minimum', style: TextStyle(color: _bioController.text.length > 20 ? Colors.greenAccent : Colors.white24, fontSize: 10, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildExperienceStep() {
    final levels = ['Beginner', 'Intermediate', 'Advanced'];
    return Column(
      children: levels.map((l) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: OptionPill(label: l, isSelected: _selectedLevel == l, onTap: () => setState(() => _selectedLevel = l)),
      )).toList(),
    );
  }

  Widget _buildGoalsStep() {
    final goalsList = ['Bespoke Suits', 'Pattern Architecture', 'Full Canvasing', 'Traditional Agbada'];
    return Wrap(
      spacing: 12, runSpacing: 12, alignment: WrapAlignment.center,
      children: goalsList.map((g) => OptionPill(
        label: g, isSelected: _goals.contains(g),
        onTap: () => setState(() => _goals.contains(g) ? _goals.remove(g) : _goals.add(g)),
      )).toList(),
    );
  }

  Widget _buildMasterSearchStep() {
    if (widget.preSelectedMasterId != null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: const Color(0xFF00FF7F).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF00FF7F).withValues(alpha: 0.3))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified_user_rounded, color: Color(0xFF00FF7F), size: 48),
              const SizedBox(height: 16),
              const Text('MENTOR CONFIRMED', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildField('SEARCH MASTER', Icons.search_rounded, TextEditingController(text: _searchQuery), onChanged: (v) => setState(() => _searchQuery = v)),
        const SizedBox(height: 24),
        if (_selectedMaster != null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFF00FF7F).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF00FF7F).withValues(alpha: 0.3))),
            child: Row(
              children: [
                const Icon(Icons.verified, color: Color(0xFF00FF7F)),
                const SizedBox(width: 16),
                Text('Linked: ${_selectedMaster!.name}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTermsStep() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
          child: const Text(
            'I pledge to respect the tools of the trade, the integrity of the fabric, and the wisdom of my Master. I acknowledge that true tailoring is an art of patience and precision.',
            style: TextStyle(color: Colors.white70, height: 1.8, fontStyle: FontStyle.italic, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 40),
        SwitchListTile.adaptive(
          title: const Text('I ACCEPT THE PLEDGE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
          value: _agreedToTraining, activeTrackColor: AppColors.amber,
          onChanged: (v) => setState(() => _agreedToTraining = v),
        ),
      ],
    );
  }

  Widget _buildField(String label, IconData icon, TextEditingController controller, {TextInputType type = TextInputType.text, Function(String)? onChanged}) {
    return TextField(
      controller: controller, keyboardType: type, onChanged: onChanged,
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

  Widget _buildDropdown(String label, IconData icon, String? value, List<String> items, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(18)),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          initialValue: value, items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white, fontSize: 14)))).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900), prefixIcon: Icon(icon, color: AppColors.amber, size: 20), border: InputBorder.none),
          dropdownColor: AppColors.darkNavy, icon: const Icon(Icons.expand_more_rounded, color: Colors.white24),
        ),
      ),
    );
  }
}
