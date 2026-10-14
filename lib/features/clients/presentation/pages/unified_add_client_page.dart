import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:desby_app/theme/colors.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/utils/async_handler.dart';
import '../../domain/entities/client.dart';
import '../providers/client_provider.dart';
import '../widgets/invite_share_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/widgets/shell_app_bar.dart';

class UnifiedAddClientPage extends ConsumerStatefulWidget {
  const UnifiedAddClientPage({super.key});

  @override
  ConsumerState<UnifiedAddClientPage> createState() =>
      _UnifiedAddClientPageState();
}

class _UnifiedAddClientPageState extends ConsumerState<UnifiedAddClientPage>
    with AsyncHandler {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  Client? _createdClient;

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

  Future<void> _createClient() async {
    if (!_isValid()) return;

    final user = ref.read(currentUserProvider);
    final result = await handleAsync(context, () async {
      const uuid = Uuid();
      final clientId = uuid.v4();
      final client = Client(
        id: clientId,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: '',
        address: '',
        gender: 'UNISEX',
        createdAt: DateTime.now(),
        inviteStatus: InviteStatus.none,
        tailorId: user?.id,
      );

      final createResult = await ref.read(createClientUsecaseProvider)(client);
      return createResult.fold(
        (failure) => throw Exception(failure.message),
        (created) => created,
      );
    }, successMessage: 'Client created');

    if (result == null || !mounted) return;

    final tokenResult = await ref.read(generateInviteTokenUsecaseProvider)(
      result.id,
    );
    final updatedClient = tokenResult.fold(
      (failure) => result,
      (token) => result.copyWith(
        inviteToken: token,
        inviteStatus: InviteStatus.pending,
      ),
    );

    setState(() => _createdClient = updatedClient);
    ref.invalidate(clientsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: shellAppBar(context, title: 'ADD CLIENT'),
      body: _createdClient != null ? _buildShareView() : _buildFormView(),
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
            'CLIENT INFORMATION',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter client name and phone number to send an invite.',
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 40),
          _buildField(
            'CLIENT NAME *',
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
              onPressed: _isValid() ? _createClient : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amber,
                foregroundColor: AppColors.darkNavy,
                disabledBackgroundColor: colors.borderSubtle,
                disabledForegroundColor: colors.textMuted,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'CREATE & SHARE INVITE',
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
              'CLIENT CREATED',
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
              '${_createdClient!.name} has been added. Share the invite link so they can fill in their details.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
          ),
          const SizedBox(height: 40),

          InviteShareCard(
            client: _createdClient!,
            onInviteSent: () {
              ref.invalidate(clientsProvider);
            },
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton(
              onPressed: () {
                ref.invalidate(clientsProvider);
                if (ref.read(navigationProvider).route != '/main') {
                  ref.setShell('/main');
                } else {
                  Navigator.maybePop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.surfaceHover,
                foregroundColor: colors.textSecondary,
                side: BorderSide(color: colors.borderDefault),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
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
