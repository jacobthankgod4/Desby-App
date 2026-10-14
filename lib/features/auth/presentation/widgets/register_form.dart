import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/spacing.dart';
import '../../../../theme/typography.dart';

class RegisterForm extends StatefulWidget {
  final VoidCallback? onRegisterPressed;
  final bool isLoading;
  final String? errorMessage;

  const RegisterForm({
    super.key,
    this.onRegisterPressed,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late TextEditingController nameController;
  String selectedUserType = 'tailor';

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    nameController = TextEditingController();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Create Account',
              style: AppTypography.headline3,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'Join Desby OS today',
              style: AppTypography.body2,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.xl),
            if (widget.errorMessage != null)
              Container(
                padding: EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  widget.errorMessage!,
                  style: AppTypography.body3.copyWith(
                    color: Colors.red.shade700,
                  ),
                ),
              ),
            if (widget.errorMessage != null) SizedBox(height: AppSpacing.md),
            TextField(
              controller: nameController,
              enabled: !widget.isLoading,
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Enter your full name',
                hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
                prefixIcon: Icon(
                  Icons.person_outlined,
                  color: AppColors.amber,
                  size: 20,
                ),
                filled: true,
                fillColor: colors.borderSubtle,
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
                  borderSide: BorderSide(color: AppColors.amber, width: 1.5),
                ),
              ),
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: AppSpacing.md),
            TextField(
              controller: emailController,
              enabled: !widget.isLoading,
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Enter your email',
                hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: AppColors.amber,
                  size: 20,
                ),
                filled: true,
                fillColor: colors.borderSubtle,
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
                  borderSide: BorderSide(color: AppColors.amber, width: 1.5),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: AppSpacing.md),
            TextField(
              controller: passwordController,
              enabled: !widget.isLoading,
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Enter your password',
                hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
                prefixIcon: Icon(
                  Icons.lock_outlined,
                  color: AppColors.amber,
                  size: 20,
                ),
                filled: true,
                fillColor: colors.borderSubtle,
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
                  borderSide: BorderSide(color: AppColors.amber, width: 1.5),
                ),
              ),
              obscureText: true,
              textInputAction: TextInputAction.done,
            ),
            SizedBox(height: AppSpacing.md),
            Text('Account Type', style: AppTypography.body1),
            SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              value: selectedUserType,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'tailor', child: Text('Tailor')),
                DropdownMenuItem(
                  value: 'apprentice',
                  child: Text('Apprentice'),
                ),
                DropdownMenuItem(value: 'customer', child: Text('Customer')),
              ],
              onChanged: widget.isLoading
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => selectedUserType = value);
                      }
                    },
            ),
            SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: widget.isLoading ? null : _handleRegister,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: widget.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('Create Account', style: AppTypography.button),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleRegister() {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    widget.onRegisterPressed?.call();
  }

  String getName() => nameController.text.trim();
  String getEmail() => emailController.text.trim();
  String getPassword() => passwordController.text;
  String getUserType() => selectedUserType;
}
