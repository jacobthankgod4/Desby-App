import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:desby_app/theme/colors.dart';

import '../providers/invite_provider.dart';
import 'invite_shop_step.dart';
import 'invite_profile_step.dart';
import 'invite_order_step.dart';
import 'invite_measurements_step.dart';
import 'invite_review_step.dart';

class InvitePage extends ConsumerStatefulWidget {
  const InvitePage({super.key});

  @override
  ConsumerState<InvitePage> createState() => _InvitePageState();
}

class _InvitePageState extends ConsumerState<InvitePage> {
  String? _token;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _extractToken();
    }
  }

  void _extractToken() {
    if (kIsWeb) {
      final uri = Uri.base;
      _token = uri.queryParameters['token'];
    } else {
      _token = ModalRoute.of(context)?.settings.arguments as String?;
    }

    if (_token != null) {
      ref.read(inviteNotifierProvider.notifier).loadClientByToken(_token!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inviteState = ref.watch(inviteNotifierProvider);

    if (_token == null) {
      return _buildErrorPage('No invite token provided');
    }

    if (inviteState.isLoading && inviteState.client == null) {
      return _buildLoadingPage();
    }

    if (inviteState.error != null && inviteState.client == null) {
      return _buildErrorPage(inviteState.error!);
    }

    if (inviteState.isCompleted) {
      return _buildCompletedPage();
    }

    return _buildInviteFlow(inviteState);
  }

  Widget _buildLoadingPage() {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.amber),
            const SizedBox(height: 24),
            Text(
              'Loading your profile...',
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPage(String message) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 24),
              Text(
                'INVALID INVITE',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 32),
              Text(
                'Please contact your tailor for a new invite link.',
                style: TextStyle(color: colors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedPage() {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.successGreen, width: 3),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 64,
                  color: AppColors.successGreen,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'ORDER SUBMITTED!',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your order has been submitted successfully. Your tailor will review it and get back to you shortly.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 48),
              if (!kIsWeb)
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    foregroundColor: AppColors.darkNavy,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'CLOSE',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInviteFlow(InviteState inviteState) {
    final steps = [
      const InviteShopStep(),
      const InviteProfileStep(),
      const InviteOrderStep(),
      const InviteMeasurementsStep(),
      const InviteReviewStep(),
    ];

    return PopScope(
      canPop: inviteState.currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ref.read(inviteNotifierProvider.notifier).previousStep();
      },
      child: Scaffold(
        backgroundColor: context.colors.scaffoldBg,
        body: Column(
          children: [
            _buildHeader(inviteState),
            _buildProgressIndicator(inviteState),
            Expanded(
              child: PageView(
                controller: PageController(
                  initialPage: inviteState.currentStep,
                ),
                physics: const NeverScrollableScrollPhysics(),
                children: steps,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(InviteState inviteState) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
      child: Row(
        children: [
          Image.asset(
            'assets/images/logo.png',
            height: 32,
            errorBuilder: (context, error, stackTrace) => Text(
              'DESBY',
              style: TextStyle(
                color: AppColors.amber,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
          ),
          const Spacer(),
          if (inviteState.client?.name != null)
            Text(
              'Welcome, ${inviteState.client!.name}',
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(InviteState inviteState) {
    final colors = context.colors;
    final labels = ['Shop', 'Profile', 'Order', 'Scan', 'Review'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          Row(
            children: List.generate(5, (index) {
              final isActive = index == inviteState.currentStep;
              final isCompleted = index < inviteState.currentStep;
              return Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.successGreen
                        : isActive
                        ? AppColors.amber
                        : colors.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              final isActive = index == inviteState.currentStep;
              return Expanded(
                child: Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isActive ? AppColors.amber : colors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
