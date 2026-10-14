import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/spacing.dart';
import '../../../../theme/typography.dart';

class LoginForm extends StatefulWidget {
  final VoidCallback? onLoginPressed;
  final bool isLoading;
  final String? errorMessage;

  const LoginForm({
    super.key,
    this.onLoginPressed,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late FocusNode emailFocus;
  late FocusNode passwordFocus;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    emailFocus = FocusNode();
    passwordFocus = FocusNode();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
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
              'Welcome Back',
              style: AppTypography.headline3,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'Sign in to your account',
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
              controller: emailController,
              focusNode: emailFocus,
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
              onSubmitted: (_) {
                emailFocus.unfocus();
                FocusScope.of(context).requestFocus(passwordFocus);
              },
            ),
            SizedBox(height: AppSpacing.md),
            TextField(
              controller: passwordController,
              focusNode: passwordFocus,
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
              onSubmitted: (_) {
                if (!widget.isLoading) {
                  _handleLogin();
                }
              },
            ),
            SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: widget.isLoading ? null : _handleLogin,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: widget.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('Sign In', style: AppTypography.button),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogin() {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    widget.onLoginPressed?.call();
  }

  String getEmail() => emailController.text.trim();
  String getPassword() => passwordController.text;
}
