import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../../core/widgets/onboarding_scaffold.dart';
import '../../../../theme/colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../clients/domain/entities/client.dart' show InviteStatus;
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/entities/apprenticeship.dart';
import '../providers/apprenticeship_provider.dart';

class ApprenticeInviteAcceptPage extends ConsumerStatefulWidget {
  final String? inviteToken;
  const ApprenticeInviteAcceptPage({super.key, this.inviteToken});

  @override
  ConsumerState<ApprenticeInviteAcceptPage> createState() =>
      _ApprenticeInviteAcceptPageState();
}

class _ApprenticeInviteAcceptPageState
    extends ConsumerState<ApprenticeInviteAcceptPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 5;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _bioController = TextEditingController();

  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _bioFocus = FocusNode();

  String? _selectedState;
  String _selectedGender = 'MALE';
  String _selectedLevel = 'Beginner';
  final List<String> _goals = [];
  bool _agreedToTraining = false;

  bool _isLoading = true;
  String? _tokenError;
  String? _tailorId;
  String? _apprenticeshipId;
  String? _preFilledName;
  String? _preFilledPhone;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _validateToken());
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _addressFocus.dispose();
    _bioFocus.dispose();
    super.dispose();
  }

  Future<void> _validateToken() async {
    final token = widget.inviteToken;
    if (token == null || token.isEmpty) {
      setState(() {
        _isLoading = false;
        _tokenError = 'No invite token provided.';
      });
      return;
    }

    try {
      final result = await ref
          .read(apprenticeshipRepositoryProvider)
          .getApprenticeshipByInviteToken(token);
      result.fold(
        (failure) => setState(() {
          _isLoading = false;
          _tokenError = 'This invite link is no longer valid or has expired.';
        }),
        (apprenticeship) {
          if (apprenticeship == null) {
            setState(() {
              _isLoading = false;
              _tokenError =
                  'This invite link is no longer valid or has expired.';
            });
            return;
          }
          setState(() {
            _isLoading = false;
            _tailorId = apprenticeship.tailorId;
            _apprenticeshipId = apprenticeship.id;
            _preFilledName = apprenticeship.apprenticeName;
            _preFilledPhone = apprenticeship.apprenticePhone;
            if (_preFilledName != null && _preFilledName!.isNotEmpty) {
              _nameController.text = _preFilledName!;
            }
            if (_preFilledPhone != null && _preFilledPhone!.isNotEmpty) {
              _phoneController.text = _preFilledPhone!;
            }
          });
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _tokenError = 'Something went wrong. Please try again.';
      });
    }
  }

  bool get _isStepValid {
    if (_currentStep == 0)
      return _nameController.text.isNotEmpty &&
          _phoneController.text.isNotEmpty;
    if (_currentStep == 1) return _bioController.text.length > 20;
    if (_currentStep == 2) return _selectedLevel.isNotEmpty;
    if (_currentStep == 3) return _goals.isNotEmpty;
    if (_currentStep == 4) return _agreedToTraining;
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
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _finish() async {
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    final user = ref.read(currentUserProvider);
    if (user == null || user.id.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please sign in again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    final profileUpdate = UserProfile(
      id: user.id,
      email: user.email,
      name: _nameController.text,
      userType: 'apprentice',
      phone: _phoneController.text,
      address: _addressController.text,
      state: _selectedState ?? '',
      bio: _bioController.text,
      createdAt: user.createdAt,
      gender: _selectedGender,
    );
    await ref.read(updateProfileUsecaseProvider)(profileUpdate);
    ref.invalidate(userProfileProvider(user.id));
    await ref.read(userProfileProvider(user.id).future);

    if (_apprenticeshipId != null && _tailorId != null) {
      final updatedApprenticeship = Apprenticeship(
        id: _apprenticeshipId!,
        tailorId: _tailorId!,
        apprenticeId: user.id,
        status: ApprenticeshipStatus.awaitingMasterApproval,
        progress: 0.0,
        startDate: DateTime.now(),
        skillIds: _goals,
        inviteToken: widget.inviteToken,
        inviteStatus: InviteStatus.accepted,
        level: _selectedLevel,
      );
      await ref
          .read(apprenticeshipRepositoryProvider)
          .updateApprenticeship(updatedApprenticeship);
    } else {
      const uuid = Uuid();
      final apprenticeship = Apprenticeship(
        id: uuid.v4(),
        tailorId: _tailorId ?? '',
        apprenticeId: user.id,
        status: ApprenticeshipStatus.awaitingMasterApproval,
        progress: 0.0,
        startDate: DateTime.now(),
        skillIds: _goals,
        level: _selectedLevel,
      );
      await ref
          .read(apprenticeshipRepositoryProvider)
          .createApprenticeship(apprenticeship);
    }

    await localStorage.save(StorageKeys.apprenticeOnboardedFor(user.id), true);
    if (mounted) completeOnboarding(context, ref);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.scaffoldBg,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.amber),
        ),
      );
    }

    if (_tokenError != null) {
      return Scaffold(
        backgroundColor: colors.scaffoldBg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.error,
                  size: 64,
                ),
                const SizedBox(height: 24),
                Text(
                  'Invite Not Found',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _tokenError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      if (ref.read(navigationProvider).route != '/main') {
                        ref.setShell('/main');
                      } else {
                        Navigator.maybePop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amber,
                      foregroundColor: AppColors.darkNavy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'GO TO DASHBOARD',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return OnboardingScaffold(
      currentStep: _currentStep,
      totalSteps: _totalSteps,
      title: 'Welcome to Desby OS',
      stepLabel: 'Step ${_currentStep + 1} of $_totalSteps',
      prompt: _getPrompt(),
      nextLabel: _currentStep == _totalSteps - 1 ? 'Get Started' : 'CONTINUE',
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
            _buildPersonalInfoStep(),
            _buildBioStep(),
            _buildExperienceStep(),
            _buildGoalsStep(),
            _buildTermsStep(),
          ],
        ),
      ),
    );
  }

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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.amber),
        ),
      ),
    );
  }
}
