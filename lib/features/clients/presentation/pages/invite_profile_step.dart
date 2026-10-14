import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desby_app/theme/colors.dart';

import '../providers/invite_provider.dart';

class InviteProfileStep extends ConsumerStatefulWidget {
  const InviteProfileStep({super.key});

  @override
  ConsumerState<InviteProfileStep> createState() => _InviteProfileStepState();
}

class _InviteProfileStepState extends ConsumerState<InviteProfileStep> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  String _selectedGender = 'MALE';
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final client = ref.read(inviteNotifierProvider).client;
      _nameController = TextEditingController(text: client?.name ?? '');
      _phoneController = TextEditingController(text: client?.phone ?? '');
      _emailController = TextEditingController(text: client?.email ?? '');
      _addressController = TextEditingController(text: client?.address ?? '');
      _selectedGender = client?.gender ?? 'MALE';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  bool _isValid() {
    return _nameController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty &&
        _addressController.text.isNotEmpty;
  }

  Future<void> _submit() async {
    if (!_isValid()) return;

    final token = ref.read(inviteNotifierProvider).client?.inviteToken ?? '';
    await ref.read(inviteNotifierProvider.notifier).updateProfile(token, {
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'address': _addressController.text.trim(),
      'gender': _selectedGender,
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final inviteState = ref.watch(inviteNotifierProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'YOUR PROFILE',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us about yourself so your tailor can serve you better.',
            style: TextStyle(color: colors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 32),

          _buildGenderSelector(),
          const SizedBox(height: 24),

          _buildField('FULL NAME *', Icons.person_outline, _nameController),
          const SizedBox(height: 16),

          _buildField(
            'PHONE NUMBER *',
            Icons.phone_outlined,
            _phoneController,
            type: TextInputType.phone,
            isNumberOnly: true,
          ),
          const SizedBox(height: 16),

          _buildField(
            'EMAIL ADDRESS',
            Icons.email_outlined,
            _emailController,
            type: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),

          _buildField(
            'DELIVERY ADDRESS *',
            Icons.location_on_outlined,
            _addressController,
          ),
          const SizedBox(height: 32),

          if (inviteState.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                inviteState.error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isValid() && !inviteState.isLoading ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amber,
                foregroundColor: AppColors.darkNavy,
                disabledBackgroundColor: colors.borderSubtle,
                disabledForegroundColor: colors.textMuted,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: inviteState.isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: colors.textOnAmber,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'CONTINUE',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildGenderSelector() {
    final colors = context.colors;
    return Row(
      children: ['MALE', 'FEMALE'].map((g) {
        final isSelected = _selectedGender == g;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () => setState(() => _selectedGender = g),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.amber : colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected
                      ? null
                      : Border.all(color: colors.borderSubtle),
                ),
                alignment: Alignment.center,
                child: Text(
                  g,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.darkNavy
                        : colors.textSecondary,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildField(
    String label,
    IconData icon,
    TextEditingController controller, {
    TextInputType type = TextInputType.text,
    bool isNumberOnly = false,
  }) {
    final colors = context.colors;
    return TextField(
      controller: controller,
      keyboardType: type,
      inputFormatters: isNumberOnly
          ? [FilteringTextInputFormatter.digitsOnly]
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
    );
  }
}
