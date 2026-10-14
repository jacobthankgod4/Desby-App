import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/services/flutterwave_service.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../../theme/colors.dart';
import '../../domain/models/plan_registry.dart';

/// A widget that gates access behind a subscription tier.
///
/// If the user's plan is below [requiredTier], an upgrade prompt is shown.
/// If [requiredTier] is 0 (free), the child is always shown.
///
/// Usage:
/// ```dart
/// SubscriptionGate(
///   requiredTier: PlanRegistry.proTier,
///   child: VirtualTryOnPage(),
/// )
/// ```
class SubscriptionGate extends ConsumerWidget {
  /// The minimum tier level required (0=free, 1=pro).
  final int requiredTier;

  /// The user type to check the plan for. If null, reads from current user.
  final String? userType;

  /// The widget to show when access is granted.
  final Widget child;

  /// Optional label shown on the gate (e.g. "AI Body Scan").
  final String? featureLabel;

  const SubscriptionGate({
    super.key,
    required this.requiredTier,
    required this.child,
    this.userType,
    this.featureLabel,
  });

  /// Checks if the user has access to a feature.
  /// Returns true if access is granted, false if blocked.
  /// When blocked, shows an upgrade bottom sheet.
  static Future<bool> checkAccess(
    BuildContext context, {
    required int requiredTier,
    String? featureLabel,
    String? userType,
  }) async {
    if (requiredTier == 0) return true;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;

    final profile = await Supabase.instance.client
        .from('users')
        .select('subscription_plan_id, subscription_expiry')
        .eq('id', user.id)
        .maybeSingle();

    if (profile == null) return false;

    final currentPlanId = profile['subscription_plan_id'] as String?;
    final expiryStr = profile['subscription_expiry'] as String?;

    if (expiryStr != null) {
      final expiry = DateTime.tryParse(expiryStr);
      if (expiry != null && expiry.isBefore(DateTime.now())) {
        if (context.mounted) {
          _showUpgradeSheet(
            context,
            requiredTier: requiredTier,
            featureLabel: featureLabel,
            userType: userType,
          );
        }
        return false;
      }
    }

    final currentPlan = currentPlanId != null
        ? PlanRegistry.getPlanById(currentPlanId)
        : null;
    final currentTier = currentPlan?.tierLevel ?? 0;

    if (currentTier >= requiredTier) return true;

    if (context.mounted) {
      _showUpgradeSheet(
        context,
        requiredTier: requiredTier,
        featureLabel: featureLabel,
        userType: userType,
      );
    }
    return false;
  }

  static void _showUpgradeSheet(
    BuildContext context, {
    required int requiredTier,
    String? featureLabel,
    String? userType,
  }) {
    final resolvedUserType = userType ?? 'tailor';
    final planId = '${resolvedUserType}_pro';
    final plan = PlanRegistry.getPlanById(planId);
    const tierName = 'Pro';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _UpgradeBottomSheet(
        requiredTier: requiredTier,
        featureLabel: featureLabel,
        tierName: tierName,
        plan: plan,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (requiredTier == 0) return child;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return child;

    final profileAsync = ref.watch(userProfileProvider(user.id));

    return profileAsync.when(
      data: (profile) {
        if (profile == null) return child;

        final currentPlanId = profile.subscriptionPlanId;
        final expiry = profile.subscriptionExpiry;

        if (expiry != null && expiry.isBefore(DateTime.now())) {
          return _UpgradePrompt(
            requiredTier: requiredTier,
            featureLabel: featureLabel,
            userType:
                userType ??
                user.userMetadata?['user_type'] as String? ??
                'tailor',
          );
        }

        final currentPlan = currentPlanId != null
            ? PlanRegistry.getPlanById(currentPlanId)
            : null;
        final currentTier = currentPlan?.tierLevel ?? 0;

        if (currentTier >= requiredTier) {
          return child;
        }

        return _UpgradePrompt(
          requiredTier: requiredTier,
          featureLabel: featureLabel,
          userType:
              userType ??
              user.userMetadata?['user_type'] as String? ??
              'tailor',
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: AppColors.amber),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _UpgradePrompt extends ConsumerWidget {
  final int requiredTier;
  final String? featureLabel;
  final String userType;

  const _UpgradePrompt({
    required this.requiredTier,
    this.featureLabel,
    required this.userType,
  });

  String get _tierName => 'Pro';

  String get _planId {
    switch (userType) {
      case 'tailor':
        return 'tailor_pro';
      case 'client':
        return 'client_pro';
      case 'apprentice':
        return 'apprentice_pro';
      case 'fabric_seller':
        return 'seller_pro';
      default:
        return 'tailor_pro';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = PlanRegistry.getPlanById(_planId);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.098),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: AppColors.amber,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            featureLabel != null
                ? '$featureLabel requires $_tierName'
                : '$_tierName Feature',
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Upgrade to $_tierName to unlock ${featureLabel != null ? 'this feature' : 'advanced tools'} and get the most out of Desby OS.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colors.textSecondary, fontSize: 14),
          ),
          if (plan != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.colors.borderSubtle),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        plan.name.toUpperCase(),
                        style: TextStyle(
                          color: AppColors.amber,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    plan.price,
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...plan.features
                      .take(5)
                      .map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  f,
                                  style: TextStyle(
                                    color: context.colors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                ref
                    .read(navigationStackProvider.notifier)
                    .push('/subscription-plans');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amber,
                foregroundColor: AppColors.darkNavy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                plan?.buttonLabel ?? 'UPGRADE NOW',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpgradeBottomSheet extends ConsumerWidget {
  final int requiredTier;
  final String? featureLabel;
  final String tierName;
  final SubscriptionPlan? plan;

  const _UpgradeBottomSheet({
    required this.requiredTier,
    this.featureLabel,
    required this.tierName,
    this.plan,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.098),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.amber,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              featureLabel != null
                  ? '$featureLabel requires $tierName'
                  : '$tierName Feature',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Upgrade to $tierName to unlock ${featureLabel != null ? 'this feature' : 'advanced tools'}.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
            if (plan != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surfaceHover,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(
                      plan!.name.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.amber,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      plan!.price,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...plan!.features
                        .take(3)
                        .map(
                          (f) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: AppColors.amber,
                                  size: 14,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    f,
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                _processPayment(context, ref);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.amber, Color(0xFFFFD700)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.amber.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    plan?.buttonLabel ?? 'UPGRADE NOW',
                    style: TextStyle(
                      color: colors.textOnAmber,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  color: colors.textHint,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  'Secured by Flutterwave',
                  style: TextStyle(color: colors.textHint, fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Not now',
                style: TextStyle(color: colors.textMuted, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _processPayment(BuildContext context, WidgetRef ref) {
    if (plan == null) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to upgrade.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final flutterwaveService = FlutterwaveService();

    flutterwaveService.checkout(
      context: context,
      email: user.email ?? '',
      fullName:
          user.userMetadata?['full_name'] as String? ?? user.email ?? 'User',
      amount: plan!.amount.toDouble(),
      orderId:
          'SUB_${user.id.substring(0, 8)}_${DateTime.now().millisecondsSinceEpoch}',
      onSuccess: (txRef) async {
        if (!context.mounted) return;
        _showVerifyingOverlay(context, ref, flutterwaveService, txRef, user);
      },
      onCancel: () {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Payment cancelled'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }

  void _showVerifyingOverlay(
    BuildContext context,
    WidgetRef ref,
    FlutterwaveService service,
    String txRef,
    dynamic user,
  ) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'verifying',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
      transitionBuilder: (_, anim, _, _) => FadeTransition(
        opacity: anim,
        child: _VerifyingOverlay(
          txRef: txRef,
          flutterwaveService: service,
          onVerified: () async {
            final profile = await ref.read(userProfileProvider(user.id).future);
            if (profile == null) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not load profile. Please try again.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
              return;
            }
            final updatedProfile = profile.copyWith(
              subscriptionPlanId: plan!.id,
              subscriptionExpiry: DateTime.now().add(const Duration(days: 30)),
            );
            await ref.read(updateProfileUsecaseProvider)(updatedProfile);
            ref.invalidate(userProfileProvider(user.id));
            await ref.read(userProfileProvider(user.id).future);
            if (context.mounted) {
              Navigator.of(context).pop();
              _showSuccessOverlay(context, plan!.name);
            }
          },
          onFailed: () {
            if (context.mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Payment verification failed. Please try again.',
                  ),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          },
        ),
      ),
    );
  }

  void _showSuccessOverlay(BuildContext context, String planName) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'success',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
      transitionBuilder: (_, anim, _, _) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: _SuccessOverlay(planName: planName),
      ),
    );
  }
}

class _VerifyingOverlay extends StatefulWidget {
  final String txRef;
  final FlutterwaveService flutterwaveService;
  final VoidCallback onVerified;
  final VoidCallback onFailed;

  const _VerifyingOverlay({
    required this.txRef,
    required this.flutterwaveService,
    required this.onVerified,
    required this.onFailed,
  });

  @override
  State<_VerifyingOverlay> createState() => _VerifyingOverlayState();
}

class _VerifyingOverlayState extends State<_VerifyingOverlay> {
  @override
  void initState() {
    super.initState();
    _pollVerification();
  }

  Future<void> _pollVerification() async {
    int attempts = 0;
    const maxAttempts = 30;
    const delay = Duration(seconds: 2);

    while (attempts < maxAttempts) {
      await Future.delayed(delay);
      attempts++;

      try {
        final verified = await widget.flutterwaveService.verifyTransaction(
          widget.txRef,
        );
        if (verified) {
          widget.onVerified();
          return;
        }
      } catch (e) {
        debugPrint('[SUB_GATE] Verify attempt $attempts failed: $e');
      }
    }

    widget.onFailed();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      color: colors.scaffoldBg,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  color: AppColors.amber,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Verifying payment...',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This may take a few moments.',
                style: TextStyle(color: colors.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessOverlay extends StatelessWidget {
  final String planName;
  const _SuccessOverlay({required this.planName});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      color: colors.scaffoldBg,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: context.colors.textPrimary,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Upgrade Successful!',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You are now on the $planName plan.',
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    foregroundColor: AppColors.darkNavy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'CONTINUE',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
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
