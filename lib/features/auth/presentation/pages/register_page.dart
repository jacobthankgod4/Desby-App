import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../../../core/constants/user_types.dart';
import '../../../../core/utils/validators.dart';

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
  
  // Password strength tracking
  PasswordStrength _passwordStrength = PasswordStrength.empty;
  String _passwordStrengthMessage = '';
  
  // Input formatters for validation
  final _textOnlyFormatter = FilteringTextInputFormatter.deny(RegExp(r'[\d]'));
  
  // Validation helpers
  bool get _isFormValid {
    // Require password to be at least fair strength
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
  
  bool get _passwordsMatch {
    return _passwordController.text == _confirmPasswordController.text;
  }

@override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    
    // Listen for text changes to update validation
    _nameController.addListener(_onTextChanged);
    _emailController.addListener(_onTextChanged);
    _passwordController.addListener(_onTextChanged);
    _confirmPasswordController.addListener(_onTextChanged);
  }
  
void _onTextChanged() {
    // Analyze password strength
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
    // WEB STABILITY: Aggressive focus purge
    FocusManager.instance.primaryFocus?.unfocus();
    
    // Validate email
    final emailError = validateEmail(_emailController.text.trim());
    if (emailError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(emailError)),
      );
      return;
    }

    // Validate password
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

    if (!mounted) return;
    
    // Small delay for web engine synchronization
    await Future.delayed(const Duration(milliseconds: 150));
    
    if (!mounted) return;

// Navigate based on user type after successful registration
    final userType = _userType;
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
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms & Privacy Policy'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Terms of Service',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
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
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
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

    // Listen for errors
    ref.listen(authStateProvider, (previous, next) {
      next.maybeMap(
        error: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.message), backgroundColor: Colors.red),
          );
        },
        orElse: () {},
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset('assets/images/logo.png', height: 80),
            const SizedBox(height: 24),
            Text(
              'Create Account',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Join Desby OS fashion network',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
TextField(
              controller: _nameController,
              enabled: !isLoading,
              inputFormatters: [_textOnlyFormatter],
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              enabled: !isLoading,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: validateEmail,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _userType,
              decoration: const InputDecoration(
                labelText: 'I am a...',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: UserType.values
                  .map((type) => DropdownMenuItem(
                        value: type.value,
                        child: Text(type.displayName),
                      ))
                  .toList(),
              onChanged: isLoading
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _userType = value);
                      }
                    },
            ),
const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              enabled: !isLoading,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: validatePassword,
            ),
            // Password strength indicator
            if (_passwordController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _getPasswordStrengthValue(),
                        backgroundColor: Colors.grey[800],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(getPasswordStrengthColor(_passwordStrength)),
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _passwordStrengthMessage,
                    style: TextStyle(
                      color: Color(getPasswordStrengthColor(_passwordStrength)),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              enabled: !isLoading,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(
                        () => _obscureConfirmPassword = !_obscureConfirmPassword);
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
Checkbox(
                  value: _agreeToTerms,
                  onChanged: (value) {
                    setState(() => _agreeToTerms = value ?? false);
                  },
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _showTermsDialog,
                    child: Text(
                      'I agree to the Terms & Conditions and Privacy Policy',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        decoration: TextDecoration.underline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
const SizedBox(height: 32),
ElevatedButton(
              onPressed: isLoading || !_isFormValid ? null : _handleRegister,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Account'),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account? ',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pushReplacementNamed('/login'),
                  child: Text(
                    'Sign in',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
