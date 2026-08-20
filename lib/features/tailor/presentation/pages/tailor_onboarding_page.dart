import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../../core/constants/nigeria_lga_data.dart';
import '../../../../core/constants/tailor_data.dart';
import '../../../../core/widgets/onboarding_scaffold.dart';
import '../../../../theme/colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

class TailorOnboardingPage extends ConsumerStatefulWidget {
  const TailorOnboardingPage({super.key});

  @override
  ConsumerState<TailorOnboardingPage> createState() => _TailorOnboardingPageState();
}

class _TailorOnboardingPageState extends ConsumerState<TailorOnboardingPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 5;

  // Data State
  final List<String> _selectedServices = [];
  final List<String> _selectedFabrics = [];
  final _businessNameController = TextEditingController();
  final _businessPhoneController = TextEditingController();
  final _businessAddressController = TextEditingController();
  
  // WEB STABILITY: Explicit Focus Nodes
  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _stateFocus = FocusNode();
  final _lgaFocus = FocusNode();

  String? _selectedCountry = 'Nigeria';
  String? _selectedState;
  String? _selectedLga;
  List<String> _availableLgas = [];

  final Map<String, bool> _dayOpen = {
    'monday': true, 'tuesday': true, 'wednesday': true, 'thursday': true, 'friday': true, 'saturday': true, 'sunday': false,
  };
  final Map<String, TimeOfDay> _openTimes = {
    'monday': const TimeOfDay(hour: 9, minute: 0), 'tuesday': const TimeOfDay(hour: 9, minute: 0), 'wednesday': const TimeOfDay(hour: 9, minute: 0), 'thursday': const TimeOfDay(hour: 9, minute: 0), 'friday': const TimeOfDay(hour: 9, minute: 0), 'saturday': const TimeOfDay(hour: 9, minute: 0), 'sunday': const TimeOfDay(hour: 10, minute: 0),
  };
  final Map<String, TimeOfDay> _closeTimes = {
    'monday': const TimeOfDay(hour: 18, minute: 0), 'tuesday': const TimeOfDay(hour: 18, minute: 0), 'wednesday': const TimeOfDay(hour: 18, minute: 0), 'thursday': const TimeOfDay(hour: 18, minute: 0), 'friday': const TimeOfDay(hour: 18, minute: 0), 'saturday': const TimeOfDay(hour: 18, minute: 0), 'sunday': const TimeOfDay(hour: 17, minute: 0),
  };

  bool _isLoading = false;
  String? _expandedServiceId;

  @override
  void dispose() {
    _pageController.dispose();
    _businessNameController.dispose();
    _businessPhoneController.dispose();
    _businessAddressController.dispose();
    
    // Dispose focus nodes
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _addressFocus.dispose();
    _stateFocus.dispose();
    _lgaFocus.dispose();
    super.dispose();
  }

  bool get _isCurrentStepValid {
    switch (_currentStep) {
      case 0: return _selectedServices.isNotEmpty;
      case 1: return _selectedFabrics.isNotEmpty;
      case 2: return _businessNameController.text.isNotEmpty && _businessPhoneController.text.isNotEmpty && _businessAddressController.text.isNotEmpty && _selectedState != null && _selectedLga != null;
      case 3: return _dayOpen.entries.any((e) => e.value);
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
        services: _selectedServices, availableFabrics: _selectedFabrics,
        workingHours: _getHoursSummary(),
        workingHoursByDay: BusinessHours(
          mondayOpen: _dayOpen['monday']! ? _openTimes['monday']!.format(context) : null,
          mondayClose: _dayOpen['monday']! ? _closeTimes['monday']!.format(context) : null,
          tuesdayOpen: _dayOpen['tuesday']! ? _openTimes['tuesday']!.format(context) : null,
          tuesdayClose: _dayOpen['tuesday']! ? _closeTimes['tuesday']!.format(context) : null,
          wednesdayOpen: _dayOpen['wednesday']! ? _openTimes['wednesday']!.format(context) : null,
          wednesdayClose: _dayOpen['wednesday']! ? _closeTimes['wednesday']!.format(context) : null,
          thursdayOpen: _dayOpen['thursday']! ? _openTimes['thursday']!.format(context) : null,
          thursdayClose: _dayOpen['thursday']! ? _closeTimes['thursday']!.format(context) : null,
          fridayOpen: _dayOpen['friday']! ? _openTimes['friday']!.format(context) : null,
          fridayClose: _dayOpen['friday']! ? _closeTimes['friday']!.format(context) : null,
          saturdayOpen: _dayOpen['saturday']! ? _openTimes['saturday']!.format(context) : null,
          saturdayClose: _dayOpen['saturday']! ? _closeTimes['saturday']!.format(context) : null,
          sundayOpen: _dayOpen['sunday']! ? _openTimes['sunday']!.format(context) : null,
          sundayClose: _dayOpen['sunday']! ? _closeTimes['sunday']!.format(context) : null,
        ),
        businessState: _selectedState ?? '', country: _selectedCountry ?? 'Nigeria', lga: _selectedLga ?? '',
        createdAt: user.createdAt, updatedAt: DateTime.now(),
      );

      final result = await ref.read(updateProfileUsecaseProvider)(updatedProfile);
      
      // Only mark onboarding complete if profile save succeeded
      result.fold(
        (failure) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Save failed: ${failure.message}'), backgroundColor: Colors.redAccent),
          );
        },
        (_) async {
          await localStorage.save(StorageKeys.tailorOnboardingComplete, true);
          await Future.delayed(const Duration(milliseconds: 250));
          if (mounted) Navigator.of(context).pushReplacementNamed('/subscription-plans');
        },
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getHoursSummary() {
    final openDays = _dayOpen.entries.where((e) => e.value).map((e) => e.key).toList();
    if (openDays.isEmpty) return 'Closed';
    if (openDays.length == 7) return 'Mon-Sun (Daily)';
    return openDays.map((d) => d.substring(0, 3).toUpperCase()).join(', ');
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
      nextLabel: _currentStep == _totalSteps - 1 ? 'START BUSINESS' : 'CONTINUE',
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
            _buildServicesStep(),
            _buildFabricsStep(),
            _buildBusinessDetailsStep(),
            _buildWorkingHoursStep(),
            _buildReviewStep(),
          ],
        ),
      ),
    );
  }

  String _getPrompt() {
    switch (_currentStep) {
      case 0: return 'What services do you offer?';
      case 1: return 'What fabrics do you master?';
      case 2: return 'Tell us about your business';
      case 3: return 'When are you open for business?';
      case 4: return 'Ready to join the ecosystem?';
      default: return 'Setup your profile';
    }
  }

  Widget _buildServicesStep() {
    final services = TailorServices.detailed;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: services.map((s) => _buildServiceItem(s)).toList(),
      ),
    );
  }

  Widget _buildServiceItem(Map<String, String> s) {
    final id = s['id']!;
    final name = s['name']!;
    final desc = s['description']!;
    final isSelected = _selectedServices.contains(name);
    final isExpanded = _expandedServiceId == id;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isSelected 
            ? AppColors.amber.withValues(alpha: 0.05) 
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected ? AppColors.amber : Colors.white.withValues(alpha: 0.05), 
          width: isSelected ? 2.0 : 1.5,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedServices.remove(name);
                } else {
                  _selectedServices.add(name);
                  _expandedServiceId = id;
                }
              });
            },
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  AnimatedScale(
                    duration: const Duration(milliseconds: 300),
                    scale: isSelected ? 1.05 : 1.0,
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.black26),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            Image.asset('assets/images/tailor.jpg', fit: BoxFit.cover, width: 80, height: 80),
                            Container(color: Colors.black.withValues(alpha: 0.3)),
                            Center(child: Text(name.split(' ').first.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1))),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                        const SizedBox(height: 4),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            isSelected ? 'SERVICE SELECTED' : 'TAP TO SELECT', 
                            key: ValueKey<bool>(isSelected),
                            style: TextStyle(
                              color: isSelected ? AppColors.amber : Colors.white24, 
                              fontSize: 9, 
                              fontWeight: FontWeight.w800, 
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: AnimatedRotation(
                      duration: const Duration(milliseconds: 300),
                      turns: isExpanded ? 0.5 : 0,
                      child: const Icon(Icons.expand_more_rounded, color: Colors.white24),
                    ),
                    onPressed: () => setState(() => _expandedServiceId = isExpanded ? null : id),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.5, fontWeight: FontWeight.w500)),
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 400),
          ),
        ],
      ),
    );
  }

  Widget _buildFabricsStep() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Wrap(
        spacing: 12, runSpacing: 12, alignment: WrapAlignment.center,
        children: FabricTypes.all.map((f) => OptionPill(
          label: f, isSelected: _selectedFabrics.contains(f),
          onTap: () => setState(() => _selectedFabrics.contains(f) ? _selectedFabrics.remove(f) : _selectedFabrics.add(f)),
        )).toList(),
      ),
    );
  }

  Widget _buildBusinessDetailsStep() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildField('BUSINESS NAME', Icons.store_rounded, _businessNameController, focusNode: _nameFocus),
          const SizedBox(height: 16),
          _buildField('PHONE NUMBER', Icons.phone_rounded, _businessPhoneController, type: TextInputType.phone, focusNode: _phoneFocus),
          const SizedBox(height: 16),
          _buildField('SHOP ADDRESS', Icons.location_on_rounded, _businessAddressController, focusNode: _addressFocus),
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

  Widget _buildWorkingHoursStep() {
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: days.map((d) => _buildDayRow(d)).toList(),
      ),
    );
  }

  Widget _buildDayRow(String day) {
    final isOpen = _dayOpen[day] ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Switch.adaptive(value: isOpen, activeTrackColor: AppColors.amber, onChanged: (v) => setState(() => _dayOpen[day] = v)),
          const SizedBox(width: 8),
          Text(day.toUpperCase().substring(0, 3), style: TextStyle(color: isOpen ? Colors.white : Colors.white24, fontWeight: FontWeight.w900, fontSize: 12)),
          const Spacer(),
          if (isOpen) ...[
            _buildTimeChip(day, true),
            const Text(' - ', style: TextStyle(color: Colors.white24)),
            _buildTimeChip(day, false),
          ] else const Text('CLOSED', style: TextStyle(color: Colors.white12, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTimeChip(String day, bool isStart) {
    final time = isStart ? _openTimes[day] : _closeTimes[day];
    if (time == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(context: context, initialTime: time);
        if (picked != null) {
          setState(() {
            if (isStart) {
              _openTimes[day] = picked;
            } else {
              _closeTimes[day] = picked;
            }
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: AppColors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Text(time.format(context), style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.w900, fontSize: 11)),
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
          _buildReviewCard('SERVICES', _selectedServices.join(' • ').toUpperCase()),
          const SizedBox(height: 16),
          _buildReviewCard('SCHEDULE', _getHoursSummary()),
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
