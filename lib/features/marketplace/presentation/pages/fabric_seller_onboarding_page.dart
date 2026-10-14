import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../../core/constants/nigeria_lga_data.dart';

import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/widgets/onboarding_shell.dart';
import '../../../../config/nigerian_banks.dart';
import '../../../../theme/colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/constants/fabric_constants.dart';

class FabricSellerOnboardingPage extends ConsumerStatefulWidget {
  const FabricSellerOnboardingPage({super.key});

  @override
  ConsumerState<FabricSellerOnboardingPage> createState() =>
      _FabricSellerOnboardingPageState();
}

class _FabricSellerOnboardingPageState
    extends ConsumerState<FabricSellerOnboardingPage> {
  int _currentStep = 0;
  final int _totalSteps = 5;

  // Data State
  final _businessNameController = TextEditingController();
  final _businessPhoneController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAccountController = TextEditingController();
  String? _selectedBankCode;
  String? _selectedBankName;

  // WEB STABILITY: Explicit Focus Nodes
  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _stateFocus = FocusNode();
  final _lgaFocus = FocusNode();
  final _yardageFocus = FocusNode();
  final _rangeFocus = FocusNode();

  final String _selectedCountry = 'Nigeria';
  String? _selectedState;
  String? _selectedLga;
  List<String> _availableLgas = [];

  final List<String> _selectedFabricTypes = [];
  static const List<String> availableFabricTypes = kFabricCategoriesWithoutAll;

  final _estimatedYardageController = TextEditingController();
  String _priceRange = 'Mid-Range';
  bool _offersCustomOrders = false;
  bool _offersWholesale = false;

  bool _isLoading = false;

  @override
  void dispose() {
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
      case 0:
        return _businessNameController.text.isNotEmpty &&
            _businessPhoneController.text.isNotEmpty &&
            _businessAddressController.text.isNotEmpty &&
            _selectedState != null &&
            _selectedLga != null;
      case 1:
        return _selectedFabricTypes.isNotEmpty;
      case 2:
        return _estimatedYardageController.text.isNotEmpty;
      case 3:
        return _bankNameController.text.isNotEmpty &&
            _bankAccountController.text.isNotEmpty &&
            _selectedBankCode != null;
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
    // WEB STABILITY: Force terminal unfocus
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() => _isLoading = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null || user.id.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your session expired. Please sign in again.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      final updatedProfile = UserProfile(
        id: user.id,
        email: user.email,
        name: user.name,
        userType: user.userType,
        phone: _businessPhoneController.text.isNotEmpty
            ? _businessPhoneController.text
            : user.phone,
        address: _businessAddressController.text,
        state: _selectedState ?? '',
        businessName: _businessNameController.text,
        businessAddress: _businessAddressController.text,
        businessPhone: _businessPhoneController.text,
        country: _selectedCountry,
        lga: _selectedLga ?? '',
        bankName: _selectedBankName ?? '',
        bankAccountNumber: _bankAccountController.text,
        bankCode: _selectedBankCode,
        createdAt: user.createdAt,
        updatedAt: DateTime.now(),
        metadata: {
          'fabric_types': _selectedFabricTypes,
          'estimated_yardage': _estimatedYardageController.text,
          'price_range': _priceRange,
          'offers_custom_orders': _offersCustomOrders,
          'offers_wholesale': _offersWholesale,
        },
      );

      final result = await ref.read(updateProfileUsecaseProvider)(
        updatedProfile,
      );

      // Refresh cached profile so the dashboard sees the updated data
      ref.invalidate(userProfileProvider(user.id));
      await ref.read(userProfileProvider(user.id).future);

      // Only mark onboarding complete if profile save succeeded
      if (result.isFailure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Could not save profile: ${result.getFailureOrNull()?.failure.message ?? "Unknown error"}',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      // CRITICAL: Save onboarding flag BEFORE any async navigation
      await localStorage.save(StorageKeys.fabricSellerOnboardedFor(user.id), true);

      if (mounted) {
        completeOnboarding(context, ref);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save profile. Please try again.'),
            backgroundColor: Colors.redAccent,
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
      userType: OnboardingUserType.fabricSeller,
      currentStep: _currentStep,
      totalSteps: _totalSteps,
      title: _getPrompt(),
      isLoading: _isLoading,
      nextLabel: _currentStep == _totalSteps - 1 ? 'OPEN STORE' : 'CONTINUE',
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
            0 => _buildBusinessDetailsStep(),
            1 => _buildFabricTypesStep(),
            2 => _buildInventoryDetailsStep(),
            3 => _buildBankDetailsStep(),
            4 => _buildReviewStep(),
        _ => _buildReviewStep(),
      };

  String _getPrompt() {
    switch (_currentStep) {
      case 0:
        return 'Tell us about your business';
      case 1:
        return 'What fabrics do you supply?';
      case 2:
        return 'Inventory & Pricing';
      case 3:
        return 'Add your bank details for payouts';
      case 4:
        return 'Ready to supply tailors?';
      default:
        return 'Set up your profile';
    }
  }

  Widget _buildBusinessDetailsStep() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildField(
            'BUSINESS NAME',
            Icons.store_rounded,
            _businessNameController,
            focusNode: _nameFocus,
          ),
          const SizedBox(height: 16),
          _buildField(
            'BUSINESS PHONE',
            Icons.phone_rounded,
            _businessPhoneController,
            type: TextInputType.phone,
            focusNode: _phoneFocus,
          ),
          const SizedBox(height: 16),
          _buildField(
            'BUSINESS ADDRESS',
            Icons.location_on_rounded,
            _businessAddressController,
            focusNode: _addressFocus,
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
        ],
      ),
    );
  }

  Widget _buildFabricTypesStep() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: availableFabricTypes
            .map(
              (f) => OptionPill(
                label: f,
                isSelected: _selectedFabricTypes.contains(f),
                onTap: () => setState(
                  () => _selectedFabricTypes.contains(f)
                      ? _selectedFabricTypes.remove(f)
                      : _selectedFabricTypes.add(f),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildInventoryDetailsStep() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildField(
            'ESTIMATED MONTHLY YARDAGE',
            Icons.straighten_rounded,
            _estimatedYardageController,
            type: TextInputType.number,
            focusNode: _yardageFocus,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            'PRICE RANGE',
            Icons.local_offer_rounded,
            _priceRange,
            ['Budget', 'Mid-Range', 'Premium', 'Luxury'],
            (v) => setState(() => _priceRange = v!),
            focusNode: _rangeFocus,
          ),
          const SizedBox(height: 24),
          _buildToggleTile(
            'OFFERS CUSTOM ORDERS',
            _offersCustomOrders,
            (v) => setState(() => _offersCustomOrders = v),
          ),
          const SizedBox(height: 12),
          _buildToggleTile(
            'OFFERS WHOLESALE',
            _offersWholesale,
            (v) => setState(() => _offersWholesale = v),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile(String label, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: value
              ? AppColors.amber.withValues(alpha: 0.3)
              : context.colors.borderSubtle,
        ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: value
                  ? context.colors.textPrimary
                  : context.colors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          Switch.adaptive(
            value: value,
            activeThumbColor: AppColors.amber,
            activeTrackColor: AppColors.amber.withValues(alpha: 0.3),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildBankDetailsStep() {
    final colors = context.colors;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How will you receive payments?',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your bank details so tailors can pay you directly after orders.',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          _buildField(
            'ACCOUNT NAME',
            Icons.person_outline_rounded,
            _bankNameController,
            focusNode: _nameFocus,
          ),
          const SizedBox(height: 16),
          _buildField(
            'ACCOUNT NUMBER',
            Icons.numbers_rounded,
            _bankAccountController,
            focusNode: _phoneFocus,
          ),
          const SizedBox(height: 16),
          _buildBankSearchField(colors),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.amber.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.amber,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You can update these details anytime from Settings > Secure Payments.',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankSearchField(DesbyThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SELECT YOUR BANK',
          style: TextStyle(
            color: colors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final bank = await showBankSearchDialog(context);
            if (bank != null) {
              setState(() {
                _selectedBankCode = bank.code;
                _selectedBankName = bank.name;
              });
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: colors.inputFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _selectedBankCode != null
                    ? AppColors.amber
                    : colors.borderSubtle,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_outlined,
                  color: AppColors.amber,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedBankName != null
                        ? _selectedBankName!
                        : 'Tap to search and select your bank',
                    style: TextStyle(
                      color: _selectedBankName != null
                          ? colors.textPrimary
                          : colors.textMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.search_rounded, color: colors.textMuted, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildReviewCard(
            'BUSINESS',
            '${_businessNameController.text}\n${_businessAddressController.text}',
          ),
          const SizedBox(height: 16),
          _buildReviewCard(
            'FABRICS',
            _selectedFabricTypes.join(' \u2022 ').toUpperCase(),
          ),
          const SizedBox(height: 16),
          _buildReviewCard(
            'INVENTORY',
            '$_priceRange \u2022 ${_estimatedYardageController.text} YDS/MO',
          ),
          const SizedBox(height: 16),
          _buildReviewCard(
            'BANK',
            '${_selectedBankName ?? 'Not selected'}\n${_bankAccountController.text}',
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.colors.borderSubtle),
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
              color: context.colors.textSecondary,
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
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      focusNode: focusNode,
      inputFormatters: inputFormatters,
      style: TextStyle(
        color: context.colors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: context.colors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
        prefixIcon: Icon(icon, color: AppColors.amber, size: 20),
        filled: true,
        fillColor: context.colors.inputFill,
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
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: context.colors.dropdownBg,
        splashColor: Colors.transparent,
        highlightColor: AppColors.amber.withValues(alpha: 0.1),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: context.colors.inputFill,
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
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: enabled ? onChanged : null,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                color: context.colors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
              prefixIcon: Icon(icon, color: AppColors.amber, size: 20),
              filled: true,
              fillColor: context.colors.inputFill,
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
            icon: Icon(
              Icons.expand_more_rounded,
              color: context.colors.textMuted,
            ),
            dropdownColor: context.colors.dropdownBg,
          ),
        ),
      ),
    );
  }
}
