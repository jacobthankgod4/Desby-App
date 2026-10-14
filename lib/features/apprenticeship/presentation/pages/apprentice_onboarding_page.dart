import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/nigeria_lga_data.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../../core/widgets/onboarding_shell.dart';
import '../../../../theme/colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../designs/presentation/providers/design_provider.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../tailor/presentation/providers/tailor_finder_provider.dart';
import '../../domain/entities/apprenticeship.dart';
import '../providers/apprenticeship_provider.dart';

class ApprenticeOnboardingPage extends ConsumerStatefulWidget {
  final String? preSelectedMasterId;
  const ApprenticeOnboardingPage({super.key, this.preSelectedMasterId});

  @override
  ConsumerState<ApprenticeOnboardingPage> createState() =>
      _ApprenticeOnboardingPageState();
}

class _ApprenticeOnboardingPageState
    extends ConsumerState<ApprenticeOnboardingPage> {
  int _currentStep = 0;
  final int _totalSteps = 6;

  // Personal Details
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  // WEB STABILITY: Explicit Focus Nodes
  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _bioFocus = FocusNode();
  final _stateFocus = FocusNode();

  String? _selectedState;
  String _selectedGender = 'MALE';

  // Apprenticeship Details
  final _bioController = TextEditingController();
  final _searchController = TextEditingController();
  String _selectedLevel = 'Beginner';
  final List<String> _goals = [];
  bool _agreedToTraining = false;
  UserProfile? _selectedMaster;
  String _searchQuery = '';
  bool _isLoading = false;

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
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    _searchController.dispose();

    // Dispose focus nodes
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _addressFocus.dispose();
    _bioFocus.dispose();
    _stateFocus.dispose();
    super.dispose();
  }

  bool get _isStepValid {
    if (_currentStep == 0)
      return _nameController.text.isNotEmpty &&
          _phoneController.text.isNotEmpty &&
          _selectedState != null;
    if (_currentStep == 1) return _bioController.text.length > 20;
    if (_currentStep == 2) return _selectedLevel.isNotEmpty;
    if (_currentStep == 3) return _goals.isNotEmpty;
    if (_currentStep == 4)
      return widget.preSelectedMasterId != null || _selectedMaster != null;
    if (_currentStep == 5) return _agreedToTraining;
    return true;
  }

  void _nextStep() {
    if (!_isStepValid) {
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
      _finish();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _finish() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      // WEB STABILITY: Force terminal unfocus
      FocusScope.of(context).unfocus();
      FocusManager.instance.primaryFocus?.unfocus();

      final user = ref.read(currentUserProvider);
      if (user == null || user.id.isEmpty) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your session expired. Please sign in again.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        return;
      }

      final profileUpdate = UserProfile(
        id: user.id,
        email: user.email,
        name: _nameController.text,
        userType: user.userType,
        phone: _phoneController.text,
        address: _addressController.text,
        state: _selectedState ?? '',
        country: 'Nigeria',
        lga: '',
        bio: _bioController.text,
        createdAt: user.createdAt,
        gender: _selectedGender,
        updatedAt: DateTime.now(),
      );
      final profileResult = await ref.read(updateProfileUsecaseProvider)(
        profileUpdate,
      );

      // Check if profile save failed
      bool saveSucceeded = false;
      profileResult.fold((failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not save profile: ${failure.message}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }, (_) => saveSucceeded = true);

      if (!saveSucceeded) return;

      // Refresh cached profile so the dashboard sees the updated data
      ref.invalidate(userProfileProvider(user.id));
      await ref.read(userProfileProvider(user.id).future);

      final isInvited = widget.preSelectedMasterId != null;
      final masterId = widget.preSelectedMasterId ?? _selectedMaster?.id;
      if (masterId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please choose a tailor to learn from.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }
      final apprenticeship = Apprenticeship(
        id: const Uuid().v4(),
        tailorId: masterId,
        apprenticeId: user.id,
        status: isInvited
            ? ApprenticeshipStatus.active
            : ApprenticeshipStatus.awaitingMasterApproval,
        progress: 0.0,
        startDate: DateTime.now(),
        skillIds: _goals,
        level: _selectedLevel,
      );

      final result = await ref
          .read(apprenticeshipRepositoryProvider)
          .createApprenticeship(apprenticeship);

      // Only mark onboarding complete if apprenticeship creation succeeded
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
      await localStorage.save(StorageKeys.apprenticeOnboardedFor(user.id), true);

      if (mounted) {
        completeOnboarding(context, ref);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Something went wrong: $e'),
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
      userType: OnboardingUserType.apprentice,
      currentStep: _currentStep,
      totalSteps: _totalSteps,
      title: _getPrompt(),
      isLoading: _isLoading,
      nextLabel: _currentStep == _totalSteps - 1
          ? (widget.preSelectedMasterId != null
                ? 'GET STARTED'
                : 'SUBMIT APPLICATION')
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
            0 => _buildPersonalInfoStep(),
            1 => _buildBioStep(),
            2 => _buildExperienceStep(),
            3 => _buildGoalsStep(),
            4 => _buildMasterSearchStep(),
            5 => _buildTermsStep(),
        _ => _buildTermsStep(),
      };

  String _getPrompt() {
    switch (_currentStep) {
      case 0:
        return 'Tell us about yourself';
      case 1:
        return 'Share your story';
      case 2:
        return 'What is your experience level?';
      case 3:
        return 'What do you want to learn?';
      case 4:
        return 'Choose a tailor to learn from';
      case 5:
        return 'Your commitment';
      default:
        return 'Set up your profile';
    }
  }

  Widget _buildPersonalInfoStep() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          Row(
            children: ['MALE', 'FEMALE']
                .map(
                  (g) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: OptionPill(
                        label: g,
                        isSelected: _selectedGender == g,
                        onTap: () => setState(() => _selectedGender = g),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
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
          _buildField(
            'RESIDENTIAL ADDRESS',
            Icons.location_on_rounded,
            _addressController,
            focusNode: _addressFocus,
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            'STATE',
            Icons.map_rounded,
            _selectedState,
            NigeriaLgaData.states,
            (v) => setState(() => _selectedState = v),
            focusNode: _stateFocus,
          ),
        ],
      ),
    );
  }

  Widget _buildBioStep() {
    final colors = context.colors;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          TextField(
            controller: _bioController,
            focusNode: _bioFocus,
            maxLines: 5,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              hintText: 'Share your background and vision...',
              hintStyle: TextStyle(color: colors.textMuted),
              filled: true,
              fillColor: colors.inputFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Text(
            '${_bioController.text.length}/20 characters minimum',
            style: TextStyle(
              color: _bioController.text.length > 20
                  ? Colors.greenAccent
                  : colors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceStep() {
    final levels = ['Beginner', 'Intermediate', 'Advanced'];
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: levels
            .map(
              (l) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OptionPill(
                  label: l,
                  isSelected: _selectedLevel == l,
                  onTap: () => setState(() => _selectedLevel = l),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildGoalsStep() {
    final goalsList = [
      'Suit Making',
      'Pattern Drafting',
      'Hand Stitching',
      'Agbada & Traditional Wear',
      'Ankara & Wax Print',
      'Bridal & Evening Wear',
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: goalsList
          .map(
            (g) => OptionPill(
              label: g,
              isSelected: _goals.contains(g),
              onTap: () => setState(
                () => _goals.contains(g) ? _goals.remove(g) : _goals.add(g),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildMasterSearchStep() {
    final colors = context.colors;
    if (widget.preSelectedMasterId != null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.successGreen.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.successGreen.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_user_rounded,
                color: AppColors.successGreen,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                'Tailor Connected',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              labelText: 'Search tailors by name',
              labelStyle: TextStyle(
                color: colors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.amber,
                size: 20,
              ),
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
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          const SizedBox(height: 16),
          if (_searchQuery.length >= 2)
            _buildTailorSearchResults()
          else
            _buildAllTailorsGrid(),
          if (_selectedMaster != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.successGreen.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.successGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Learning from ${_selectedMaster!.name}',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showTailorProfile(_selectedMaster!),
                    child: Text(
                      'View Profile',
                      style: TextStyle(
                        color: AppColors.amber,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTailorSearchResults() {
    return Consumer(
      builder: (context, ref, _) {
        final colors = context.colors;
        final tailorsAsync = ref.watch(tailorsProvider(_searchQuery));
        return tailorsAsync.when(
          data: (tailors) {
            if (tailors.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text(
                  'No tailors found. Try a different name.',
                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                ),
              );
            }
            return _buildTailorList(tailors);
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.amber,
                strokeWidth: 2,
              ),
            ),
          ),
          error: (_, __) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              'Could not search tailors. Please try again.',
              style: TextStyle(color: colors.textMuted, fontSize: 12),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAllTailorsGrid() {
    return Consumer(
      builder: (context, ref, _) {
        final colors = context.colors;
        final tailorsAsync = ref.watch(tailorsProvider(''));
        return tailorsAsync.when(
          data: (tailors) {
            if (tailors.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text(
                  'No tailors available yet. Check back soon!',
                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available Tailors',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 12),
                _buildTailorList(tailors),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.amber,
                strokeWidth: 2,
              ),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildTailorList(List<UserProfile> tailors) {
    final colors = context.colors;
    return Column(
      children: tailors.take(20).map((tailor) {
        final isSelected = _selectedMaster?.id == tailor.id;
        return GestureDetector(
          onTap: () => setState(() => _selectedMaster = tailor),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.amber.withValues(alpha: 0.1)
                  : colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppColors.amber.withValues(alpha: 0.5)
                    : colors.cardBorder,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.amber.withValues(alpha: 0.15),
                  child: Text(
                    tailor.name.isNotEmpty ? tailor.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: AppColors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tailor.name,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (tailor.state != null && tailor.state!.isNotEmpty)
                        Text(
                          tailor.state!,
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      if (tailor.bio != null && tailor.bio!.isNotEmpty)
                        Text(
                          tailor.bio!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textHint,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _showTailorProfile(tailor),
                  child: const Text(
                    'View',
                    style: TextStyle(color: AppColors.amber, fontSize: 12),
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.amber,
                    size: 22,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showTailorProfile(UserProfile tailor) {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: colors.bottomSheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.amber.withValues(alpha: 0.15),
                  child: Text(
                    tailor.name.isNotEmpty ? tailor.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: AppColors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  tailor.name,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ),
              if (tailor.state != null && tailor.state!.isNotEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      tailor.state!,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              if (tailor.bio != null && tailor.bio!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'ABOUT',
                  style: TextStyle(
                    color: AppColors.amber,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tailor.bio!,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'DESIGNS',
                style: TextStyle(
                  color: AppColors.amber,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              _buildDesignsGrid(tailor.id),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesignsGrid(String tailorId) {
    return Consumer(
      builder: (context, ref, _) {
        final colors = context.colors;
        final designsAsync = ref.watch(tailorDesignsProvider(tailorId));
        return designsAsync.when(
          data: (designs) {
            if (designs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No designs uploaded yet',
                    style: TextStyle(color: colors.textMuted, fontSize: 13),
                  ),
                ),
              );
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: designs.length.clamp(0, 9),
              itemBuilder: (context, index) {
                final design = designs[index];
                final hasImages = design.imageUrls.isNotEmpty;
                return Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    image: hasImages
                        ? DecorationImage(
                            image: NetworkImage(design.imageUrls.first),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: !hasImages
                      ? Center(
                          child: Icon(
                            Icons.design_services_rounded,
                            color: colors.iconMuted,
                            size: 28,
                          ),
                        )
                      : null,
                );
              },
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.amber,
                strokeWidth: 2,
              ),
            ),
          ),
          error: (_, __) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'Could not load designs',
                style: TextStyle(color: colors.textMuted, fontSize: 12),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTermsStep() {
    final colors = context.colors;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.cardBorder),
          ),
          child: Text(
            'I commit to learning with respect, dedication, and honesty. I will take care of my training, honour my tailor\'s guidance, and put in the work it takes to grow my craft.',
            style: TextStyle(
              color: colors.textSecondary,
              height: 1.8,
              fontStyle: FontStyle.italic,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 40),
        SwitchListTile.adaptive(
          title: Text(
            'I AGREE',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
          value: _agreedToTraining,
          activeThumbColor: AppColors.amber,
          activeTrackColor: AppColors.amber.withValues(alpha: 0.3),
          onChanged: (v) => setState(() => _agreedToTraining = v),
        ),
      ],
    );
  }

  Widget _buildField(
    String label,
    IconData icon,
    TextEditingController controller, {
    TextInputType type = TextInputType.text,
    Function(String)? onChanged,
    FocusNode? focusNode,
  }) {
    final colors = context.colors;
    return TextField(
      controller: controller,
      keyboardType: type,
      onChanged: onChanged,
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
            icon: Icon(Icons.expand_more_rounded, color: colors.iconMuted),
            dropdownColor: colors.dropdownBg,
          ),
        ),
      ),
    );
  }
}
