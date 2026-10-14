import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../../core/constants/nigeria_lga_data.dart';
import '../../../../core/constants/tailor_data.dart';
import '../../../../core/widgets/onboarding_shell.dart';
import '../../../../config/nigerian_banks.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../theme/colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../verification/presentation/widgets/identity_verification_step.dart';

class TailorOnboardingPage extends ConsumerStatefulWidget {
  const TailorOnboardingPage({super.key});

  @override
  ConsumerState<TailorOnboardingPage> createState() =>
      _TailorOnboardingPageState();
}

class _TailorOnboardingPageState extends ConsumerState<TailorOnboardingPage> {
  int _currentStep = 0;
  final int _totalSteps = 7;

  /// True once each document is on file (pending or verified). Tracked
  /// separately because BOTH are mandatory, so a single flag could not express
  /// "identity done, address not".
  bool _identitySubmitted = false;
  bool _addressSubmitted = false;

  /// Identity AND address proof both submitted.
  bool get _kycComplete => _identitySubmitted && _addressSubmitted;

  /// Serialised step data, so leaving mid-flow does not lose the answers.
  ///
  /// Everything was previously held in local widget state and only written to
  /// the profile on the final submit, so a user who closed the tab part-way
  /// through came back to a blank form and had to start again.
  static const String _draftKey = 'tailor_onboarding_draft';

  /// Builds the widget for the current step.
  Widget _currentStepBuilder() => switch (_currentStep) {
        0 => _buildServicesStep(),
        1 => _buildFabricsStep(),
        2 => _buildBusinessDetailsStep(),
        3 => _buildWorkingHoursStep(),
        4 => _buildBankDetailsStep(),
        5 => _buildVerificationStep(),
        _ => _buildReviewStep(),
      };

  void _saveDraft() {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      localStorage.save('${StorageKeys.onboardingCompleteKey(_draftKey, uid)}', {
        'step': _currentStep,
        'businessName': _businessNameController.text,
        'businessPhone': _businessPhoneController.text,
        'businessAddress': _businessAddressController.text,
        'services': _selectedServices,
        'fabrics': _selectedFabrics,
        'dayOpen': _dayOpen,
        'bankName': _selectedBankName,
        'bankAccount': _bankAccountController.text,
        'bankCode': _selectedBankCode,
        'state': _selectedState,
        'lga': _selectedLga,
        'savedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[ONBOARDING] draft save failed: $e');
    }
  }

  void _restoreDraft() {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final raw = localStorage.get(
        StorageKeys.onboardingCompleteKey(_draftKey, uid),
        defaultValue: null,
      );
      if (raw is! Map) return;
      final d = Map<String, dynamic>.from(raw);

      _businessNameController.text = '${d['businessName'] ?? ''}';
      _businessPhoneController.text = '${d['businessPhone'] ?? ''}';
      _businessAddressController.text = '${d['businessAddress'] ?? ''}';
      _bankAccountController.text = '${d['bankAccount'] ?? ''}';

      _selectedServices
        ..clear()
        ..addAll((d['services'] as List?)?.map((e) => '$e') ?? []);
      _selectedFabrics
        ..clear()
        ..addAll((d['fabrics'] as List?)?.map((e) => '$e') ?? []);
      final hours = d['dayOpen'];
      if (hours is Map) {
        _dayOpen
          ..clear()
          ..addAll(hours.map((k, v) => MapEntry('$k', v == true)));
      }

      _selectedBankName = d['bankName'] as String?;
      _selectedBankCode = d['bankCode'] as String?;
      _selectedState = d['state'] as String?;
      _selectedLga = d['lga'] as String?;

      final step = (d['step'] as num?)?.toInt() ?? 0;
      // Never restore past the KYC gate: steps 1-5 hold profile answers that are
      // safe to restore, but the final steps must be re-confirmed live.
      if (step > 0 && step < 5) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _currentStep = step.clamp(0, _totalSteps - 1));
          }
        });
      }
    } catch (e) {
      debugPrint('[ONBOARDING] draft restore failed: $e');
    }
  }

  void _clearDraft() {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      localStorage.delete(StorageKeys.onboardingCompleteKey(_draftKey, uid));
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    // Read the real KYC state on load. Without this both flags stayed false on a
    // hard refresh, so a tailor who had already uploaded both documents was
    // asked for them again and the Continue button was blocked.
    _loadKycGate();
    _restoreDraft();
  }

  final List<String> _selectedServices = [];
  final List<String> _selectedFabrics = [];
  final _businessNameController = TextEditingController();
  final _businessPhoneController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAccountController = TextEditingController();
  String? _selectedBankCode;
  String? _selectedBankName;

  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _stateFocus = FocusNode();
  final _lgaFocus = FocusNode();

  final String _selectedCountry = 'Nigeria';
  String? _selectedState;
  String? _selectedLga;
  List<String> _availableLgas = [];

  final Map<String, bool> _dayOpen = {
    'monday': true,
    'tuesday': true,
    'wednesday': true,
    'thursday': true,
    'friday': true,
    'saturday': true,
    'sunday': false,
  };
  final Map<String, TimeOfDay> _openTimes = {
    'monday': const TimeOfDay(hour: 9, minute: 0),
    'tuesday': const TimeOfDay(hour: 9, minute: 0),
    'wednesday': const TimeOfDay(hour: 9, minute: 0),
    'thursday': const TimeOfDay(hour: 9, minute: 0),
    'friday': const TimeOfDay(hour: 9, minute: 0),
    'saturday': const TimeOfDay(hour: 9, minute: 0),
    'sunday': const TimeOfDay(hour: 10, minute: 0),
  };
  final Map<String, TimeOfDay> _closeTimes = {
    'monday': const TimeOfDay(hour: 18, minute: 0),
    'tuesday': const TimeOfDay(hour: 18, minute: 0),
    'wednesday': const TimeOfDay(hour: 18, minute: 0),
    'thursday': const TimeOfDay(hour: 18, minute: 0),
    'friday': const TimeOfDay(hour: 18, minute: 0),
    'saturday': const TimeOfDay(hour: 18, minute: 0),
    'sunday': const TimeOfDay(hour: 17, minute: 0),
  };

  bool _isLoading = false;
  String? _expandedServiceId;

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessPhoneController.dispose();
    _businessAddressController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _addressFocus.dispose();
    _stateFocus.dispose();
    _lgaFocus.dispose();
    super.dispose();
  }

  bool get _isCurrentStepValid {
    switch (_currentStep) {
      case 0:
        return _selectedServices.isNotEmpty;
      case 1:
        return _selectedFabrics.isNotEmpty;
      case 2:
        return _businessNameController.text.isNotEmpty &&
            _businessPhoneController.text.isNotEmpty &&
            _businessAddressController.text.isNotEmpty &&
            _selectedState != null &&
            _selectedLga != null;
      case 3:
        return _dayOpen.entries.any((e) => e.value);
      case 4:
        return _bankNameController.text.isNotEmpty &&
            _bankAccountController.text.isNotEmpty &&
            _selectedBankCode != null;
      case 5:
        // Both documents must be on file: the identity document AND the proof of
        // address. Waiting for *approval* is still not required — approval is
        // what `can_receive_payouts()` gates, not onboarding — but a rejected or
        // expired submission does not count as on file.
        //
        // This previously accepted an identity document alone, so a tailor could
        // complete onboarding with no address proof at all.
        return _kycComplete;
      default:
        return true;
    }
  }

  /// Why Continue is blocked, in the tailor's words rather than a generic
  /// "complete all required fields".
  String? get _kycBlockReason {
    if (_kycComplete) return null;
    final missing = <String>[];
    if (!_identitySubmitted) missing.add('an identity document');
    if (!_addressSubmitted) missing.add('proof of address');
    return 'Please upload ${missing.join(' and ')} to finish';
  }

  void _nextStep() {
    if (!_isCurrentStepValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _currentStep == 5
                ? (_kycBlockReason ?? 'Please complete all required fields')
                : 'Please complete all required fields',
          ),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }
    _saveDraft();
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
    var stage = 'read-user';
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      stage = 'build-profile';

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
        services: _selectedServices,
        availableFabrics: _selectedFabrics,
        workingHours: _getHoursSummary(),
        workingHoursByDay: BusinessHours(
          mondayOpen: _dayOpen['monday']!
              ? _openTimes['monday']!.format(context)
              : null,
          mondayClose: _dayOpen['monday']!
              ? _closeTimes['monday']!.format(context)
              : null,
          tuesdayOpen: _dayOpen['tuesday']!
              ? _openTimes['tuesday']!.format(context)
              : null,
          tuesdayClose: _dayOpen['tuesday']!
              ? _closeTimes['tuesday']!.format(context)
              : null,
          wednesdayOpen: _dayOpen['wednesday']!
              ? _openTimes['wednesday']!.format(context)
              : null,
          wednesdayClose: _dayOpen['wednesday']!
              ? _closeTimes['wednesday']!.format(context)
              : null,
          thursdayOpen: _dayOpen['thursday']!
              ? _openTimes['thursday']!.format(context)
              : null,
          thursdayClose: _dayOpen['thursday']!
              ? _closeTimes['thursday']!.format(context)
              : null,
          fridayOpen: _dayOpen['friday']!
              ? _openTimes['friday']!.format(context)
              : null,
          fridayClose: _dayOpen['friday']!
              ? _closeTimes['friday']!.format(context)
              : null,
          saturdayOpen: _dayOpen['saturday']!
              ? _openTimes['saturday']!.format(context)
              : null,
          saturdayClose: _dayOpen['saturday']!
              ? _closeTimes['saturday']!.format(context)
              : null,
          sundayOpen: _dayOpen['sunday']!
              ? _openTimes['sunday']!.format(context)
              : null,
          sundayClose: _dayOpen['sunday']!
              ? _closeTimes['sunday']!.format(context)
              : null,
        ),
        businessState: _selectedState ?? '',
        country: _selectedCountry,
        lga: _selectedLga ?? '',
        bankName: _selectedBankName ?? '',
        bankAccountNumber: _bankAccountController.text,
        bankCode: _selectedBankCode,
        createdAt: user.createdAt,
        updatedAt: DateTime.now(),
      );

      stage = 'update-profile';
      final result = await ref.read(updateProfileUsecaseProvider)(
        updatedProfile,
      );

      if (result.isFailure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Save failed: ${result.getFailureOrNull()?.failure.message ?? "Unknown error"}',
              ),
              backgroundColor: context.colors.statusError,
            ),
          );
        }
        return;
      }

      // The database is the authority on whether onboarding may complete. It
      // refuses unless an identity document AND a proof of address are both on
      // file, so a tampered local flag or a direct profile write cannot skip the
      // requirement.
      stage = 'kyc-rpc';
      // postgrest >= 2.9 removed `PostgrestResponse.error`; a failed request now
      // THROWS a PostgrestException instead of returning an error field. Reading
      // `.error` here raised `NoSuchMethodError` in release builds (dart2js
      // mangles the missing member to `gdu`). Catch it and treat any throw as a
      // failed KYC completion.
      try {
        await Supabase.instance.client.rpc('complete_tailor_onboarding');
      } catch (kycErr) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        final message = kycErr is PostgrestException
            ? (kycErr.message ?? 'KYC verification is incomplete')
            : 'We could not reach the server to verify your documents.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_kycBlockReason ?? message),
            backgroundColor: context.colors.statusError,
          ),
        );
        return;
      }

      stage = 'invalidate-profile';
      // Refresh cached profile so the dashboard sees the updated data
      ref.invalidate(userProfileProvider(user.id));

      // CRITICAL: Save onboarding flag BEFORE any async navigation
      stage = 'save-flag';
      await localStorage.save(StorageKeys.tailorOnboardedFor(user.id), true);

      stage = 'clear-draft';
      _clearDraft();

      stage = 'complete';
      if (mounted) {
        completeOnboarding(context, ref);
      }
    } catch (e, st) {
      // dart2js mangles missing members in release builds, so the stage tells us
      // which call threw when the runtime only reports `gdu`-style symbols.
      debugPrint('KORRA_ONBOARDING_SAVE_FAILED stage=$stage error=$e');
      debugPrintStack(stackTrace: st, label: 'KORRA_ONBOARDING_SAVE_STACK');
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: context.colors.statusError,
          ),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getHoursSummary() {
    final openDays = _dayOpen.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
    if (openDays.isEmpty) return 'Closed';
    if (openDays.length == 7) return 'Mon-Sun (Daily)';
    return openDays.map((d) => d.substring(0, 3).toUpperCase()).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingShell(
      userType: OnboardingUserType.tailor,
      currentStep: _currentStep,
      totalSteps: _totalSteps,
      title: _getPrompt(),
      isLoading: _isLoading,
      nextLabel: _currentStep == _totalSteps - 1
          ? 'START BUSINESS'
          : 'CONTINUE',
      onBack: _currentStep > 0 ? _previousStep : null,
      onNext: _nextStep,
      // Render only the current step rather than a PageView.
      //
      // PageView needs a bounded height. It was pinned to `SizedBox(height:
      // 400)`, which clipped every form; removing that pin left it with an
      // unbounded height inside the scaffold's scroll view, so the page grew
      // without limit and scrolled forever. Swiping was already disabled with
      // NeverScrollableScrollPhysics, so PageView bought nothing — a direct
      // child sizes to its content and lets the scaffold scroll normally.
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
      child: KeyedSubtree(
        key: ValueKey(_currentStep),
        child: _currentStepBuilder(),
      ),
    ),
    );
  }

  String _getPrompt() {
    switch (_currentStep) {
      case 0:
        return 'What services do you offer?';
      case 1:
        return 'What fabrics do you master?';
      case 2:
        return 'Tell us about your business';
      case 3:
        return 'When are you open for business?';
      case 4:
        return 'Verify who you are';
      case 5:
        return 'Ready to join the ecosystem?';
      default:
        return 'Setup your profile';
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
    final colors = context.colors;
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
            : colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected ? AppColors.amber : colors.borderDefault,
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
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: colors.surface,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            // The photo fills the tile; the label sits on a
                            // translucent scrim so it stays readable over any
                            // image. Previously an opaque scaffoldBg Container
                            // was painted on top of the photo, hiding it
                            // completely — every tile rendered blank.
                            Image.asset(
                              s['image'] ?? 'assets/images/tailor.jpg',
                              fit: BoxFit.cover,
                              width: 80,
                              height: 80,
                              errorBuilder: (context, error, stack) =>
                                  Container(color: colors.surface),
                            ),
                            // Scrim, not a fill: keeps the image visible.
                            Container(color: colors.scaffoldBg.withValues(alpha: 0.55)),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.scaffoldBg.withValues(alpha: 0.72),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  name.split(' ').first.toUpperCase(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
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
                        Text(
                          name.toUpperCase(),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            isSelected ? 'SERVICE SELECTED' : 'TAP TO SELECT',
                            key: ValueKey<bool>(isSelected),
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.amber
                                  : colors.textMuted,
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
                      child: Icon(
                        Icons.expand_more_rounded,
                        color: colors.textMuted,
                      ),
                    ),
                    onPressed: () => setState(
                      () => _expandedServiceId = isExpanded ? null : id,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Text(
                desc,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
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
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: FabricTypes.all
            .map(
              (f) => OptionPill(
                label: f,
                isSelected: _selectedFabrics.contains(f),
                onTap: () => setState(
                  () => _selectedFabrics.contains(f)
                      ? _selectedFabrics.remove(f)
                      : _selectedFabrics.add(f),
                ),
              ),
            )
            .toList(),
      ),
    );
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
            'PHONE NUMBER',
            Icons.phone_rounded,
            _businessPhoneController,
            type: TextInputType.phone,
            focusNode: _phoneFocus,
          ),
          const SizedBox(height: 16),
          _buildField(
            'SHOP ADDRESS',
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

  Widget _buildWorkingHoursStep() {
    final days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(children: days.map((d) => _buildDayRow(d)).toList()),
    );
  }

  Widget _buildDayRow(String day) {
    final colors = context.colors;
    final isOpen = _dayOpen[day] ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Switch.adaptive(
            value: isOpen,
            activeThumbColor: AppColors.amber,
            activeTrackColor: AppColors.amber.withValues(alpha: 0.3),
            onChanged: (v) => setState(() => _dayOpen[day] = v),
          ),
          const SizedBox(width: 8),
          Text(
            day.toUpperCase().substring(0, 3),
            style: TextStyle(
              color: isOpen ? colors.textPrimary : colors.textMuted,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          if (isOpen) ...[
            _buildTimeChip(day, true),
            Text(' - ', style: TextStyle(color: colors.textMuted)),
            _buildTimeChip(day, false),
          ] else
            Text(
              'CLOSED',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeChip(String day, bool isStart) {
    final time = isStart ? _openTimes[day] : _closeTimes[day];
    if (time == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
        );
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
        decoration: BoxDecoration(
          color: AppColors.amber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          time.format(context),
          style: TextStyle(
            color: AppColors.amber,
            fontWeight: FontWeight.w900,
            fontSize: 11,
          ),
        ),
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
            'Add your bank details so clients can pay you directly after order delivery.',
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
            type: TextInputType.number,
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
              color: colors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _selectedBankCode != null
                    ? AppColors.amber
                    : colors.borderDefault,
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

  /// Whether both KYC documents are on file (pending or verified). Re-read when
  /// the step submits, so leaving and returning does not re-prompt.
  Future<void> _loadKycGate() async {
    final status = await ref.read(verificationServiceProvider).fetchStatus();
    if (!mounted) return;
    setState(() {
      _identitySubmitted = status.isIdentitySubmitted;
      _addressSubmitted = status.isAddressSubmitted;
    });
  }

  /// Identity + address verification.
  ///
  /// Both documents are mandatory to *finish* onboarding, though neither needs to
  /// be *approved* — `can_receive_payouts()` decides when money can move. The
  /// step itself says which document is still outstanding rather than leaving the
  /// Continue button silently dead.
  Widget _buildVerificationStep() {
    // No fixed height. The step used to be wrapped in `SizedBox(height: 400)` with
    // its own SingleChildScrollView, which clipped the KYC form: the identity
    // fields, the address fields and the submit button below the fold were
    // unreachable, and the nested scroll fought the page scroll. The onboarding
    // page already scrolls, so the step must be allowed to size itself.
    return IdentityVerificationStep(onChanged: _loadKycGate);
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
            'SERVICES',
            _selectedServices.join(' \u2022 ').toUpperCase(),
          ),
          const SizedBox(height: 16),
          _buildReviewCard('SCHEDULE', _getHoursSummary()),
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
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
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
        fillColor: colors.surface,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.surface,
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
            border: InputBorder.none,
          ),
          dropdownColor: colors.scaffoldBg,
          icon: Icon(Icons.expand_more_rounded, color: colors.textMuted),
        ),
      ),
    );
  }
}
