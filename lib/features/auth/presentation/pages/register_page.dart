import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/auth_shell.dart';
import '../providers/auth_provider.dart';
import '../../../../core/constants/user_types.dart';
import '../../../../core/utils/validators.dart';
import '../../../../theme/colors.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  String _userType = UserType.tailor.value;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  PasswordStrength _passwordStrength = PasswordStrength.empty;
  String _passwordStrengthMessage = '';
  final _textOnlyFormatter = FilteringTextInputFormatter.deny(RegExp(r'[\d]'));

  bool get _isFormValid {
    final hasValidPassword = _passwordController.text.isNotEmpty &&
        _passwordStrength != PasswordStrength.empty &&
        _passwordStrength != PasswordStrength.weak;
    return _nameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        hasValidPassword &&
        _confirmPasswordController.text.isNotEmpty &&
        _passwordsMatch &&
        _agreeToTerms;
  }

  bool get _passwordsMatch =>
      _passwordController.text == _confirmPasswordController.text;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    _nameController.addListener(_onTextChanged);
    _emailController.addListener(_onTextChanged);
    _passwordController.addListener(_onTextChanged);
    _confirmPasswordController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    _passwordStrength = analyzePasswordStrength(_passwordController.text);
    _passwordStrengthMessage = getPasswordStrengthMessage(_passwordStrength);
    if (mounted) setState(() {});
  }

  double _getPasswordStrengthValue() {
    switch (_passwordStrength) {
      case PasswordStrength.empty:
        return 0.0;
      case PasswordStrength.weak:
        return 0.2;
      case PasswordStrength.fair:
        return 0.4;
      case PasswordStrength.good:
        return 0.6;
      case PasswordStrength.strong:
        return 0.8;
      case PasswordStrength.excellent:
        return 1.0;
    }
  }

  Future<void> _handleRegister() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final emailError = validateEmail(_emailController.text.trim());
    if (emailError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(emailError)),
      );
      return;
    }

    final passwordError = validatePassword(_passwordController.text);
    if (passwordError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(passwordError)),
      );
      return;
    }

    if (!_passwordsMatch) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to terms & conditions')),
      );
      return;
    }

    final notifier = ref.read(authStateProvider.notifier);
    await notifier.register(
      _emailController.text.trim(),
      _passwordController.text,
      _nameController.text.trim(),
      _userType,
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Terms & Privacy Policy', style: TextStyle(color: Colors.white)),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Terms of Service', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              SizedBox(height: 8),
              Text(
                'By using Desby OS, you agree to:\n\n'
                '1. Provide accurate information\n'
                '2. Maintain account security\n'
                '3. Not misuse the platform\n'
                '4. Respect other users\n\n'
                'Privacy Policy:\n\n'
                'We collect and store your data securely. '
                'Your personal information is used only for '
                'providing our tailoring services. We do NOT '
                'share your data with third parties without consent.',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppColors.amber)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.maybeMap(
      loading: (_) => true,
      orElse: () => false,
    );

    ref.listen(authStateProvider, (previous, next) {
      next.maybeMap(
        authenticated: (auth) {
          final userType = auth.authResponse.user.userType;
          final route = userType == UserType.tailor.value
              ? '/tailor-onboarding'
              : userType == UserType.apprentice.value
                  ? '/apprentice-onboarding'
                  : userType == UserType.client.value
                      ? '/client-onboarding'
                      : userType == UserType.fabricSeller.value
                          ? '/fabric-seller-onboarding'
                          : '/main';
          Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
        },
        unverified: (state) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/verify-email',
            (route) => false,
            arguments: state.email,
          );
        },
        error: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.message), backgroundColor: Colors.red),
          );
        },
        orElse: () {},
      );
    });

    return AuthShell(
      title: 'Sign Up',
      subtitle: 'Join the Desby fashion network',
      child: _buildForm(isLoading),
    );
  }

  Widget _buildForm(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const AuthLogo(),
        const SizedBox(height: 24),
        const Text(
          'Create Account',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Join the Desby OS fashion network',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 24),
        _buildLabel('FULL NAME'),
        const SizedBox(height: 6),
        TextField(
          controller: _nameController,
          enabled: !isLoading,
          inputFormatters: [_textOnlyFormatter],
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: _inputDecoration('Enter your full name'),
        ),
        const SizedBox(height: 14),
        _buildLabel('EMAIL'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _emailController,
          enabled: !isLoading,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: _inputDecoration('name@email.com'),
          keyboardType: TextInputType.emailAddress,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: validateEmail,
        ),
        const SizedBox(height: 14),
        _buildLabel('I AM A...'),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _userType,
              isExpanded: true,
              dropdownColor: const Color(0xFF1A1A1A),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              icon: Icon(Icons.keyboard_arrow_down, color: Colors.white.withOpacity(0.4)),
              items: UserType.values
                  .map((type) => DropdownMenuItem(
                        value: type.value,
                        child: Text(type.displayName),
                      ))
                  .toList(),
              onChanged: isLoading
                  ? null
                  : (value) {
                      if (value != null) setState(() => _userType = value);
                    },
            ),
          ),
        ),
        const SizedBox(height: 14),
        _buildLabel('PASSWORD'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _passwordController,
          enabled: !isLoading,
          obscureText: _obscurePassword,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: _inputDecoration('Create a password').copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Colors.white.withOpacity(0.4),
                size: 20,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: validatePassword,
        ),
        if (_passwordController.text.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: _getPasswordStrengthValue(),
                    backgroundColor: Colors.white.withOpacity(0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(getPasswordStrengthColor(_passwordStrength)),
                    ),
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _passwordStrengthMessage,
                style: TextStyle(
                  color: Color(getPasswordStrengthColor(_passwordStrength)),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        _buildLabel('CONFIRM PASSWORD'),
        const SizedBox(height: 6),
        TextField(
          controller: _confirmPasswordController,
          enabled: !isLoading,
          obscureText: _obscureConfirmPassword,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: _inputDecoration('Confirm your password').copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Colors.white.withOpacity(0.4),
                size: 20,
              ),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: Checkbox(
                value: _agreeToTerms,
                onChanged: (v) => setState(() => _agreeToTerms = v ?? false),
                activeColor: AppColors.amber,
                side: BorderSide(color: Colors.white.withOpacity(0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: _showTermsDialog,
                child: Text.rich(
                  TextSpan(
                    text: 'I agree to the ',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    children: [
                      TextSpan(
                        text: 'Terms & Conditions',
                        style: TextStyle(
                          color: AppColors.amber,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(
                          color: AppColors.amber,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: isLoading || !_isFormValid ? null : _handleRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amber,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pushReplacementNamed('/login'),
            child: Text.rich(
              TextSpan(
                text: 'Already have an account? ',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.5),
                ),
                children: [
                  TextSpan(
                    text: 'Sign in',
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
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: Colors.white.withOpacity(0.4),
        letterSpacing: 0.15,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
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
