import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../theme/colors.dart';
import '../../../../core/utils/async_handler.dart';
import '../../domain/entities/apprenticeship.dart';
import '../../../clients/domain/entities/client.dart' show InviteStatus;
import '../providers/apprenticeship_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/apprentice_invite_share_card.dart';
import '../../../../core/widgets/shell_app_bar.dart';

class UnifiedAddApprenticePage extends ConsumerStatefulWidget {
  const UnifiedAddApprenticePage({super.key});

  @override
  ConsumerState<UnifiedAddApprenticePage> createState() =>
      _UnifiedAddApprenticePageState();
}

class _UnifiedAddApprenticePageState
    extends ConsumerState<UnifiedAddApprenticePage>
    with AsyncHandler {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  Apprenticeship? _createdApprenticeship;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool _isValid() {
    final nameValid = _nameController.text.trim().isNotEmpty;
    final phoneValid =
        _phoneController.text.trim().isNotEmpty &&
        RegExp(r'^[\d]+$').hasMatch(_phoneController.text.trim());
    return nameValid && phoneValid;
  }

  Future<void> _createAndInvite() async {
    if (!_isValid()) return;

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

    final result = await handleAsync(context, () async {
      const uuid = Uuid();
      final apprenticeshipId = uuid.v4();
      final token = uuid.v4();

      final apprenticeship = Apprenticeship(
        id: apprenticeshipId,
        tailorId: user.id,
        apprenticeId: 'pending_$token',
        status: ApprenticeshipStatus.pendingInvite,
        progress: 0.0,
        startDate: DateTime.now(),
        inviteToken: token,
        inviteStatus: InviteStatus.pending,
        apprenticeName: _nameController.text.trim(),
        apprenticePhone: _phoneController.text.trim(),
      );

      final createResult = await ref
          .read(apprenticeshipRepositoryProvider)
          .createApprenticeship(apprenticeship);
      return createResult.fold(
        (failure) => throw Exception(failure.message),
        (created) => created,
      );
    }, successMessage: 'Apprentice added');

    if (result == null || !mounted) return;

    setState(() => _createdApprenticeship = result);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: shellAppBar(context, title: 'ADD APPRENTICE'),
      body: _createdApprenticeship != null
          ? _buildShareView()
          : _buildFormView(),
    );
  }

  Widget _buildFormView() {
    final colors = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'APPRENTICE INFORMATION',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the apprentice\'s name and phone number to send an invite link.',
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 40),
          _buildField(
            'APPRENTICE NAME *',
            Icons.person_outline,
            _nameController,
            isTextOnly: true,
          ),
          _buildField(
            'PHONE NUMBER *',
            Icons.phone_outlined,
            _phoneController,
            type: TextInputType.phone,
            isNumberOnly: true,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton(
              onPressed: _isValid() ? _createAndInvite : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amber,
                foregroundColor: AppColors.darkNavy,
                disabledBackgroundColor: colors.inputFill,
                disabledForegroundColor: colors.textMuted,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ADD & SEND INVITE',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Icon(Icons.arrow_forward_rounded),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareView() {
    final colors = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.successGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.successGreen.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 40,
                color: AppColors.successGreen,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'APPRENTICE ADDED',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '${_createdApprenticeship!.apprenticeName ?? "Apprentice"} has been added. Share the invite link so they can complete their onboarding.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
          ),
          const SizedBox(height: 40),

          ApprenticeInviteShareCard(
            apprenticeship: _createdApprenticeship!,
            onInviteSent: () {},
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton(
              onPressed: () {
                if (ref.read(navigationProvider).route != '/main') {
                  ref.setShell('/main');
                } else {
                  Navigator.maybePop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.surface,
                foregroundColor: colors.textSecondary,
                side: BorderSide(color: colors.cardBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'DONE',
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
              ),
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
    bool isTextOnly = false,
    bool isNumberOnly = false,
  }) {
    final colors = context.colors;
    final textOnlyFormatter = FilteringTextInputFormatter.deny(RegExp(r'[\d]'));

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        keyboardType: type,
        inputFormatters: isNumberOnly
            ? [FilteringTextInputFormatter.digitsOnly]
            : isTextOnly
            ? [textOnlyFormatter]
            : null,
        style: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: colors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
          prefixIcon: Icon(icon, size: 20, color: AppColors.amber),
          filled: true,
          fillColor: colors.inputFill,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors.borderDefault),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.amber, width: 1.5),
          ),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }
}
