import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../theme/colors.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/storage/storage_keys.dart';

class VerifyEmailPage extends ConsumerStatefulWidget {
  final String email;

  const VerifyEmailPage({super.key, required this.email});

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> {
  bool _isResending = false;
  int _resendCooldown = 0;

  /// Address the page talks about.
  ///
  /// Reached from two places: the post-signup screen (which passes the email
  /// directly) and the boot-time `#error=...` recovery path (which cannot,
  /// because the fragment carries no arguments). Falling back to the remembered
  /// email keeps "Resend" working on that second path.
  String get _email {
    final direct = widget.email.trim();
    if (direct.isNotEmpty) return direct;

    // Set at signup, so it survives a hard reload of this page. Checked before
    // rememberedEmail because that is only written at login when "remember me"
    // is ticked, so it is absent for most users who have never logged in.
    final pending = localStorage
        .get(StorageKeys.pendingVerificationEmail, defaultValue: '')
        .toString()
        .trim();
    if (pending.isNotEmpty) return pending;

    final remembered = localStorage
        .get(StorageKeys.rememberedEmail, defaultValue: '')
        .toString()
        .trim();
    return remembered;
  }

  void _clearPending() {
    localStorage.delete(StorageKeys.pendingVerificationEmail);
  }

  Future<void> _resendEmail() async {
    if (_resendCooldown > 0 || _isResending) return;

    final address = _email;
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('We could not tell which address to resend to.'),
          backgroundColor: context.colors.statusError,
        ),
      );
      return;
    }

    setState(() => _isResending = true);

    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: address,
        emailRedirectTo: kAppBaseUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification email resent! Check your inbox.'),
            backgroundColor: context.colors.statusSuccess,
          ),
        );
        setState(() {
          _isResending = false;
          _resendCooldown = 60;
        });
        _startCooldown();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not resend the email. Please try again.'),
            backgroundColor: context.colors.statusError,
          ),
        );
        setState(() => _isResending = false);
      }
    }
  }

  void _startCooldown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
        return true;
      }
      return false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        title: const Text(
          'Verify Email',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 2,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.email_outlined,
                  color: AppColors.amber,
                  size: 64,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Check Your Inbox',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'We have sent a verification link to:',
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.email,
                style: const TextStyle(
                  color: AppColors.amber,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Text(
                'Please click the link in the email to confirm your account. Once confirmed, you can return here to sign in.',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 13,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/login', (route) => false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    foregroundColor: AppColors.darkNavy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Go to Sign In',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: _isResending || _resendCooldown > 0
                    ? null
                    : _resendEmail,
                child: Text(
                  _resendCooldown > 0
                      ? 'Resend in ${_resendCooldown}s'
                      : _isResending
                      ? 'Sending...'
                      : 'Resend Email',
                  style: TextStyle(
                    color: _resendCooldown > 0 || _isResending
                        ? colors.textMuted
                        : colors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
