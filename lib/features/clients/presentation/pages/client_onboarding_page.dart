import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/colors.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../../core/constants/nigeria_lga_data.dart';
import '../../../../core/widgets/onboarding_shell.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

class ClientOnboardingPage extends ConsumerStatefulWidget {
  const ClientOnboardingPage({super.key});

  @override
  ConsumerState<ClientOnboardingPage> createState() =>
      _ClientOnboardingPageState();
}

class _ClientOnboardingPageState extends ConsumerState<ClientOnboardingPage> {
  int _currentStep = 0;
  final int _totalSteps = 4;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _stateFocus = FocusNode();
  final _lgaFocus = FocusNode();
  final _unitFocus = FocusNode();

  String _selectedGender = 'MALE';
  final String _selectedCountry = 'Nigeria';
  String? _selectedState;
  String? _selectedLga;
  List<String> _availableLgas = [];

  // Style preferences are multi-select so clients can pick several
  // occasions and fabrics they like.
  List<String> _selectedOccasions = ['Casual'];
  List<String> _selectedFabrics = ['Cotton'];

  String _selectedBodyType = 'Average';
  String _selectedUnit = 'Inches';

  bool _isLoading = false;

  static const List<String> genderOptions = ['MALE', 'FEMALE'];
  static const List<String> occasionOptions = [
    'Casual',
    'Business',
    'Formal',
    'Traditional',
    'Wedding',
    'Party',
  ];
  static const List<String> bodyTypeOptions = [
    'Slim',
    'Average',
    'Athletic',
    'Curvy',
    'Plus Size',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _addressFocus.dispose();
    _stateFocus.dispose();
    _lgaFocus.dispose();
    _unitFocus.dispose();
    super.dispose();
  }

  bool get _isCurrentStepValid {
    switch (_currentStep) {
      case 0:
        return _nameController.text.isNotEmpty &&
            _phoneController.text.isNotEmpty &&
            _addressController.text.isNotEmpty &&
            _selectedState != null &&
            _selectedLga != null;
      case 1:
        return true; // Style preferences are optional
      case 2:
        return true; // Body type is optional
      default:
        return true;
    }
  }

  void _nextStep() {
    if (!_isCurrentStepValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required fields'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      _finishOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _finishOnboarding() async {
    if (_isLoading) return;
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() => _isLoading = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null || user.id.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session expired. Please log in again.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      final updatedProfile = UserProfile(
        id: user.id,
        email: user.email,
        name: _nameController.text,
        gender: _selectedGender,
        userType: user.userType,
        phone: _phoneController.text,
        address: _addressController.text,
        state: _selectedState ?? '',
        country: _selectedCountry,
        lga: _selectedLga ?? '',
        createdAt: user.createdAt,
        updatedAt: DateTime.now(),
        preferredOccasions: List.of(_selectedOccasions),
        preferredFabrics: List.of(_selectedFabrics),
        bodyType: _selectedBodyType,
        measurementUnit: _selectedUnit,
      );

      final result = await ref.read(updateProfileUsecaseProvider)(
        updatedProfile,
      );

      if (result.isFailure) {
        throw Exception(
          result.getFailureOrNull()?.failure.message ?? 'Profile update failed',
        );
      }

      ref.invalidate(userProfileProvider(user.id));
      await ref.read(userProfileProvider(user.id).future);

      await localStorage.save(StorageKeys.clientOnboardedFor(user.id), true);

      if (mounted) completeOnboarding(context, ref);
    } catch (e) {
      debugPrint('[ONBOARDING] Critical Failure: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not complete setup. Please try again.'),
            backgroundColor: context.colors.statusError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingShell(
      userType: OnboardingUserType.client,
      currentStep: _currentStep,
      totalSteps: _totalSteps,
      title: _getPrompt(),
      isLoading: _isLoading,
      nextLabel: _currentStep == _totalSteps - 1
          ? 'DISCOVER TAILORS'
          : 'CONTINUE',
      onBack: _currentStep > 0 ? _previousStep : null,
      onNext: _nextStep,
      // No fixed height: SizedBox(height: 400) clipped every step at the
      // bottom, hiding the lower half of each form. The scaffold already
      // scrolls, so the step must be free to size itself to its content.
      // Render only the current step rather than a PageView.
      //
      // PageView requires a bounded height. It was pinned to SizedBox(height:
      // 400), which clipped every form; removing that pin left it unbounded
      // inside the scaffold's scroll view, so the page grew without limit and
      // scrolled forever. Swiping was already disabled, so PageView bought
      // nothing.
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: KeyedSubtree(
          key: ValueKey(_currentStep),
          child: _stepFor(_currentStep),
        ),
      ),
    );
  }


  /// Builds the widget for [step].
  Widget _stepFor(int step) => switch (step) {
            0 => _buildPersonalDetailsStep(),
            1 => _buildStylePreferencesStep(),
            2 => _buildBodyTypeStep(),
            3 => _buildReviewStep(),
        _ => _buildReviewStep(),
      };

  String _getPrompt() {
    switch (_currentStep) {
      case 0:
        return 'Tell us about yourself';
      case 1:
        return 'Help us understand your taste';
      case 2:
        return 'What is your body type?';
      case 3:
        return 'Ready for the perfect fit?';
      default:
        return 'Set up your profile';
    }
  }

  Widget _buildPersonalDetailsStep() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildField(
            'FULL NAME',
            Icons.person_rounded,
            _nameController,
            focusNode: _nameFocus,
          ),
          const SizedBox(height: 16),
          _buildField(
            'PHONE NUMBER',
            Icons.phone_rounded,
            _phoneController,
            type: TextInputType.phone,
            focusNode: _phoneFocus,
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            'GENDER',
            Icons.face_rounded,
            _selectedGender,
            genderOptions,
            (v) => setState(() => _selectedGender = v!),
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            'STATE',
            Icons.map_rounded,
            _selectedState,
            NigeriaLgaData.states,
            (v) {
              setState(() {
                _selectedState = v;
                _selectedLga = null;
                _availableLgas = v != null
                    ? NigeriaLgaData.getLgasForState(v)
                    : [];
              });
            },
            focusNode: _stateFocus,
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            'LGA',
            Icons.location_city_rounded,
            _selectedLga,
            _availableLgas,
            (v) => setState(() => _selectedLga = v),
            enabled: _selectedState != null,
            focusNode: _lgaFocus,
          ),
          const SizedBox(height: 16),
          _buildField(
            'ADDRESS',
            Icons.home_rounded,
            _addressController,
            focusNode: _addressFocus,
          ),
        ],
      ),
    );
  }

  Widget _buildStylePreferencesStep() {
    final colors = context.colors;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          Text(
            'PREFERRED OCCASION',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: occasionOptions
                .map(
                  (o) => OptionPill(
                    label: o,
                    isSelected: _selectedOccasions.contains(o),
                    onTap: () => setState(() {
                      if (_selectedOccasions.contains(o)) {
                        _selectedOccasions = List.of(
                          _selectedOccasions..remove(o),
                        );
                      } else {
                        _selectedOccasions = [..._selectedOccasions, o];
                      }
                    }),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 32),
          Text(
            'PREFERRED FABRIC',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: ['Cotton', 'Silk', 'Linen', 'Wool', 'Lace']
                .map(
                  (f) => OptionPill(
                    label: f,
                    isSelected: _selectedFabrics.contains(f),
                    onTap: () => setState(() {
                      if (_selectedFabrics.contains(f)) {
                        _selectedFabrics = List.of(_selectedFabrics..remove(f));
                      } else {
                        _selectedFabrics = [..._selectedFabrics, f];
                      }
                    }),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyTypeStep() {
    final colors = context.colors;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          Text(
            'BODY TYPE',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: bodyTypeOptions
                .map(
                  (b) => OptionPill(
                    label: b,
                    isSelected: _selectedBodyType == b,
                    onTap: () => setState(() => _selectedBodyType = b),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 32),
          _buildDropdown(
            'MEASUREMENT UNIT',
            Icons.straighten_rounded,
            _selectedUnit,
            ['Inches', 'Centimeters'],
            (v) => setState(() => _selectedUnit = v!),
            focusNode: _unitFocus,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildReviewCard(
            'IDENTITY',
            '${_nameController.text}\n${_phoneController.text}',
          ),
          const SizedBox(height: 16),
          _buildReviewCard(
            'LOCATION',
            '${_selectedLga ?? "Not set"}, ${_selectedState ?? "Not set"}',
          ),
          const SizedBox(height: 16),
          _buildReviewCard(
            'STYLE',
            '${_selectedOccasions.join(", ")} \u2022 ${_selectedFabrics.join(", ")}',
          ),
          const SizedBox(height: 16),
          _buildReviewCard('BODY', '$_selectedBodyType \u2022 $_selectedUnit'),
        ],
      ),
    );
  }

  Widget _buildReviewCard(String label, String value) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.amber,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    IconData icon,
    TextEditingController controller, {
    TextInputType type = TextInputType.text,
    FocusNode? focusNode,
  }) {
    final colors = context.colors;
    return TextField(
      controller: controller,
      keyboardType: type,
      focusNode: focusNode,
      style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: colors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
        prefixIcon: Icon(icon, color: AppColors.amber, size: 20),
        filled: true,
        fillColor: colors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.amber),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    IconData icon,
    String? value,
    List<String> items,
    Function(String?) onChanged, {
    bool enabled = true,
    FocusNode? focusNode,
  }) {
    final colors = context.colors;
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: colors.scaffoldBg,
        splashColor: Colors.transparent,
        highlightColor: AppColors.amber.withValues(alpha: 0.1),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: colors.inputFill,
          borderRadius: BorderRadius.circular(18),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButtonFormField<String>(
            value: value,
            focusNode: focusNode,
            items: items
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(
                      e,
                      style: TextStyle(color: colors.textPrimary, fontSize: 14),
                    ),
                  ),
                )
                .toList(),
            onChanged: enabled ? onChanged : null,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                color: colors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
              prefixIcon: Icon(icon, color: AppColors.amber, size: 20),
              filled: true,
              fillColor: colors.inputFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: AppColors.amber),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
            icon: Icon(Icons.expand_more_rounded, color: colors.textMuted),
            dropdownColor: colors.scaffoldBg,
          ),
        ),
      ),
    );
  }
}
