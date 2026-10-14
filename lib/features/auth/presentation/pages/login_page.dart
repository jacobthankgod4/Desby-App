import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/auth_shell.dart';
import '../providers/auth_provider.dart';
import '../../../../core/constants/user_types.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../../core/utils/validators.dart';
import '../../../../theme/colors.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rememberMe = localStorage.get(
        StorageKeys.rememberMe,
        defaultValue: false,
      );

      if (rememberMe) {
        setState(() {
          _rememberMe = true;
          _emailController.text = localStorage.get(
            StorageKeys.rememberedEmail,
            defaultValue: '',
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final emailError = validateEmail(email);
    if (emailError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(emailError)));
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password is required')));
      return;
    }

    await ref
        .read(authStateProvider.notifier)
        .login(email, password, rememberMe: _rememberMe);

    if (mounted) await Future.delayed(const Duration(milliseconds: 150));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.maybeMap(
      loading: (_) => true,
      orElse: () => false,
    );

    ref.listen(authStateProvider, (previous, next) {
      next.maybeMap(
        authenticated: (auth) {
          // Only navigate if we transitioned from loading (i.e., user actually pressed login)
          // Don't navigate on state flickers from _restoreAuthenticatedState
          final wasLoading =
              previous?.maybeMap(loading: (_) => true, orElse: () => false) ??
              false;
          if (!wasLoading) return;

          final userType = auth.authResponse.user.userType;
          final tailorDone = localStorage.get(
            StorageKeys.tailorOnboardingComplete,
            defaultValue: false,
          );
          final apprenticeDone = localStorage.get(
            StorageKeys.apprenticeOnboardingComplete,
            defaultValue: false,
          );
          final clientDone = localStorage.get(
            StorageKeys.clientOnboardingComplete,
            defaultValue: false,
          );
          final fabricSellerDone = localStorage.get(
            StorageKeys.fabricSellerOnboardingComplete,
            defaultValue: false,
          );

          String route;
          if (userType == UserType.tailor.value && !tailorDone) {
            route = '/tailor-onboarding';
          } else if (userType == UserType.apprentice.value && !apprenticeDone) {
            route = '/apprentice-onboarding';
          } else if (userType == UserType.client.value && !clientDone) {
            route = '/client-onboarding';
          } else if (userType == UserType.fabricSeller.value &&
              !fabricSellerDone) {
            route = '/fabric-seller-onboarding';
          } else {
            route = '/main';
          }
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(route, (route) => false);
        },
        error: (error) {
          // Only show error if we were loading (i.e., user actually pressed login)
          final wasLoading =
              previous?.maybeMap(loading: (_) => true, orElse: () => false) ??
              false;
          if (!wasLoading) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                error.message.isEmpty
                    ? 'Something went wrong. Please try again.'
                    : error.message,
              ),
              backgroundColor: colors.statusError,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 8),
            ),
          );
        },
        orElse: () {},
      );
    });

    return AuthShell(
      title: 'Sign In',
      subtitle: 'Welcome back to Desby OS',
      child: _buildForm(isLoading),
    );
  }

  Widget _buildForm(bool isLoading) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const AuthLogo(),
        const SizedBox(height: 32),
        Text(
          'Welcome Back',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Sign in to your Desby account',
          style: TextStyle(fontSize: 14, color: colors.textSecondary),
        ),
        const SizedBox(height: 28),
        _buildLabel('EMAIL'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _emailController,
          enabled: !isLoading,
          style: TextStyle(color: colors.textPrimary, fontSize: 14),
          decoration: _inputDecoration('name@email.com'),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: validateEmail,
        ),
        const SizedBox(height: 16),
        _buildLabel('PASSWORD'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _passwordController,
          enabled: !isLoading,
          obscureText: _obscurePassword,
          style: TextStyle(color: colors.textPrimary, fontSize: 14),
          decoration: _inputDecoration('Enter your password').copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: colors.textMuted,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _handleLogin(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: Checkbox(
                    value: _rememberMe,
                    onChanged: (v) => setState(() => _rememberMe = v ?? false),
                    activeColor: AppColors.amber,
                    side: BorderSide(color: colors.borderDefault),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Remember me',
                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).pushNamed('/forgot-password'),
              child: Text(
                'Forgot password?',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.amber,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amber,
              foregroundColor: colors.textOnAmber,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                        color: colors.textOnAmber,
                      ),
                    )
                : const Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: GestureDetector(
            onTap: () =>
                Navigator.of(context).pushReplacementNamed('/register'),
            child: Text.rich(
              TextSpan(
                text: "Don't have an account? ",
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
                children: [
                  TextSpan(
                    text: 'Sign up',
                    style: TextStyle(
                      color: AppColors.amber,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    final colors = context.colors;
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: colors.textMuted,
        letterSpacing: 0.15,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    final colors = context.colors;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: colors.textHint, fontSize: 14),
      filled: true,
      fillColor: colors.borderSubtle,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.borderDefault),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.borderDefault),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.amber, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }
}
