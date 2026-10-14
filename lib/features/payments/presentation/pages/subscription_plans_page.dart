import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/colors.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/services/flutterwave_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/models/plan_registry.dart';
import '../providers/subscription_provider.dart';

class SubscriptionPlansPage extends ConsumerStatefulWidget {
  const SubscriptionPlansPage({super.key});

  @override
  ConsumerState<SubscriptionPlansPage> createState() =>
      _SubscriptionPlansPageState();
}

class _SubscriptionPlansPageState extends ConsumerState<SubscriptionPlansPage>
    with TickerProviderStateMixin {
  final FlutterwaveService _flutterwaveService = FlutterwaveService();
  int _selectedPlanIndex = -1;
  late AnimationController _heroController;
  late AnimationController _glowController;
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();
    _heroController.forward();
  }

  @override
  void dispose() {
    _heroController.dispose();
    _glowController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _handleUpgrade(SubscriptionPlan plan) {
    FocusManager.instance.primaryFocus?.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = ref.read(currentUserProvider);
      final profileAsync = user != null
          ? ref.read(userProfileProvider(user.id))
          : null;
      final currentPlanId = profileAsync?.valueOrNull?.subscriptionPlanId;
      if (currentPlanId == plan.id) return;

      // User is on Premium, tapping Free → downgrade
      if (plan.amount == 0 && currentPlanId != null && currentPlanId.isNotEmpty) {
        _showDowngradeConfirmation(plan, user);
        return;
      }
      // User is already on Free, tapping Free → do nothing
      if (plan.amount == 0) {
        return;
      }
      if (user == null || user.id.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your session expired. Please sign in again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      _showPaymentSheet(plan, user);
    });
  }

  void _showDowngradeConfirmation(SubscriptionPlan plan, dynamic user) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: colors.bottomSheetBg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: colors.borderSubtle,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.surface,
              blurRadius: 40,
            ),
          ],
        ),
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_downward_rounded,
                color: Colors.orangeAccent,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Downgrade to Free?',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You will lose access to premium features at the end of your current billing period. Your data will be saved.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                _processDowngrade(user);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'Downgrade to Free',
                    style: TextStyle(
                      color: colors.textOnAmber,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.borderDefault),
                ),
                child: Center(
                  child: Text(
                    'Keep Premium',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processDowngrade(dynamic user) async {
    if (user == null || !mounted) return;
    try {
      final profile = await ref.read(userProfileProvider(user.id).future);
      if (profile == null) {
        if (mounted) {
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
        subscriptionPlanId: null,
        subscriptionExpiry: null,
      );
      await ref.read(updateProfileUsecaseProvider)(updatedProfile);
      ref.invalidate(userProfileProvider(user.id));
      await ref.read(userProfileProvider(user.id).future);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Downgraded to Free plan'),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downgrade failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showPaymentSheet(SubscriptionPlan plan, dynamic user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _PaymentSheet(
        plan: plan,
        onConfirm: () {
          Navigator.pop(ctx);
          _processPayment(plan, user);
        },
      ),
    );
  }

  void _processPayment(SubscriptionPlan plan, dynamic user) {
    _flutterwaveService.checkout(
      context: context,
      email: user.email,
      fullName: user.name,
      amount: plan.amount.toDouble(),
      orderId:
          'SUB_${user.id.substring(0, 8)}_${DateTime.now().millisecondsSinceEpoch}',
      onSuccess: (txRef) async {
        if (mounted) _showVerifyingOverlay(plan, user, txRef);
      },
      onCancel: () {
        if (!mounted) return;
        final colors = context.colors;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Payment cancelled'),
            backgroundColor: colors.snackbarBg,
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
    SubscriptionPlan plan,
    dynamic user,
    String txRef,
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
          flutterwaveService: _flutterwaveService,
          onVerified: () async {
            final profile = await ref.read(userProfileProvider(user.id).future);
            if (profile == null) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not load profile. Please try again.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
              return;
            }
            final currentExpiry = profile.subscriptionExpiry;
            final newExpiry =
                (currentExpiry != null && currentExpiry.isAfter(DateTime.now()))
                ? currentExpiry.add(const Duration(days: 30))
                : DateTime.now().add(const Duration(days: 30));
            final updatedProfile = profile.copyWith(
              subscriptionPlanId: plan.id,
              subscriptionExpiry: newExpiry,
            );
            await ref.read(updateProfileUsecaseProvider)(updatedProfile);
            ref.invalidate(userProfileProvider(user.id));
            await ref.read(userProfileProvider(user.id).future);
            if (mounted) {
              Navigator.of(context).pop();
              _showSuccessOverlay(plan.name);
            }
          },
          onFailed: () {
            if (mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Payment not confirmed. Please check your email for receipt.',
                  ),
                  backgroundColor: Colors.orangeAccent,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  void _showSuccessOverlay(String planName) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'success',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
      transitionBuilder: (_, anim, _, _) {
        return FadeTransition(
          opacity: anim,
          child: _SuccessOverlay(planName: planName),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final plansAsync = ref.watch(availablePlansProvider);
    final user = ref.watch(currentUserProvider);
    final userType = user?.userType ?? 'tailor';
    final profileAsync = user != null
        ? ref.watch(userProfileProvider(user.id))
        : null;
    final currentPlanId = profileAsync?.valueOrNull?.subscriptionPlanId;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: Stack(
        children: [
          // Ambient glow
          AnimatedBuilder(
            animation: _floatController,
            builder: (_, _) => CustomPaint(
              size: Size(
                MediaQuery.of(context).size.width,
                MediaQuery.of(context).size.height,
              ),
              painter: _AmbientGlowPainter(
                animation: _floatController.value,
                glowAnimation: _glowController.value,
              ),
            ),
          ),
          // Content
          SafeArea(
            child: plansAsync.when(
              data: (plans) => _buildContent(plans, userType, currentPlanId),
              loading: () => const Center(child: _LoadingPulse()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.redAccent,
                      size: 40,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Could not load plans',
                      style: TextStyle(color: colors.textMuted),
                    ),
                    const SizedBox(height: 20),
                    _GlowButton(
                      label: 'Retry',
                      onTap: () => ref.invalidate(availablePlansProvider),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    List<SubscriptionPlan> plans,
    String userType,
    String? currentPlanId,
  ) {
    final colors = context.colors;
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(child: _buildHero(userType)),
        SliverToBoxAdapter(child: _buildPriceHighlight()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _HyperPlanCard(
                  plan: plans[index],
                  index: index,
                  isSelected: _selectedPlanIndex == index,
                  glowAnimation: _glowController,
                  currentPlanId: currentPlanId,
                  onTap: () => setState(() => _selectedPlanIndex = index),
                  onUpgrade: () => _handleUpgrade(plans[index]),
                ),
              ),
              childCount: plans.length,
            ),
          ),
        ),
        SliverToBoxAdapter(child: _buildCompareButton(plans)),
        SliverToBoxAdapter(child: _buildTrust()),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            child: Center(
              child: TextButton(
                onPressed: () => Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/main', (route) => false),
                child: Text(
                  'Maybe later',
                  style: TextStyle(color: colors.textHint, fontSize: 13),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHero(String userType) {
    final colors = context.colors;
    return FadeTransition(
      opacity: CurvedAnimation(parent: _heroController, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: _heroController,
                curve: Curves.easeOutCubic,
              ),
            ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.amber.withValues(alpha: 0.15),
                AppColors.darkNavy,
              ],
            ),
            border: Border.all(color: AppColors.amber.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.amber.withValues(alpha: 0.25),
                      AppColors.amber.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.amber.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _getHeroLabel(userType),
                  style: TextStyle(
                    color: AppColors.amber,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _getHeroTitle(userType),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                height: 1.15,
                letterSpacing: -0.5,
              ),
              ),
              const SizedBox(height: 10),
              Text(
                _getHeroSubtitle(userType),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceHighlight() {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '₦',
            style: TextStyle(
              color: AppColors.amber,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppColors.amber, Color(0xFFFFD700), AppColors.amber],
            ).createShader(bounds),
            child: Text(
              '1,000',
              style: TextStyle(
                color: isDark ? colors.textPrimary : AppColors.darkNavy,
                fontSize: 48,
                fontWeight: FontWeight.w900,
                letterSpacing: -2,
                height: 1,
              ),
            ),
          ),
          Text(
            '/mo',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompareButton(List<SubscriptionPlan> plans) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: GestureDetector(
        onTap: () => _showComparisonSheet(plans),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.borderDefault),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.compare_arrows_rounded,
                color: colors.iconSecondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Compare all features',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrust() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _TrustPill(icon: Icons.lock_outline_rounded, label: 'Secure'),
          const SizedBox(width: 12),
          _TrustPill(
            icon: Icons.replay_circle_filled_rounded,
            label: 'Cancel anytime',
          ),
          const SizedBox(width: 12),
          _TrustPill(icon: Icons.bolt_rounded, label: 'Instant access'),
        ],
      ),
    );
  }

  void _showComparisonSheet(List<SubscriptionPlan> plans) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ComparisonSheet(plans: plans),
    );
  }

  String _getHeroLabel(String u) => switch (u) {
    'tailor' => 'FOR TAILORS',
    'client' => 'FOR CLIENTS',
    'apprentice' => 'FOR APPRENTICES',
    'fabric_seller' => 'FOR SELLERS',
    _ => 'CHOOSE YOUR PLAN',
  };

  String _getHeroTitle(String u) => switch (u) {
    'tailor' => 'Grow your tailoring business with the right tools',
    'client' => 'Get outfits that fit perfectly, every time',
    'apprentice' => 'Learn the craft faster with expert guidance',
    'fabric_seller' => 'Reach more tailors and sell more fabric',
    _ => 'Choose the plan that works for you',
  };

  String _getHeroSubtitle(String u) => switch (u) {
    'tailor' =>
      'Smart tools to manage clients, track orders, and grow your brand — all in one place.',
    'client' =>
      'Scan your body, try outfits virtually, and get clothes that fit like they were made for you.',
    'apprentice' =>
      'Learn from real tailors, track your progress, and earn certificates to build your career.',
    'fabric_seller' =>
      'Get verified, attract more buyers, and manage your shop with powerful tools.',
    _ => 'Start for free and upgrade when you are ready.',
  };
}

// ─── HYPER PLAN CARD ───

class _HyperPlanCard extends StatefulWidget {
  final SubscriptionPlan plan;
  final int index;
  final bool isSelected;
  final AnimationController glowAnimation;
  final String? currentPlanId;
  final VoidCallback onTap;
  final VoidCallback onUpgrade;

  const _HyperPlanCard({
    required this.plan,
    required this.index,
    required this.isSelected,
    required this.glowAnimation,
    this.currentPlanId,
    required this.onTap,
    required this.onUpgrade,
  });

  @override
  State<_HyperPlanCard> createState() => _HyperPlanCardState();
}

class _HyperPlanCardState extends State<_HyperPlanCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final plan = widget.plan;
    final isPremium = plan.amount > 0;
    final isFree = plan.amount == 0;
    final isCurrentPlan = widget.currentPlanId == plan.id;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: widget.glowAnimation,
          builder: (_, _) {
            final glow = widget.glowAnimation.value;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: isDark ? null : colors.surface,
                gradient: isDark
                    ? (isPremium
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.amber.withValues(
                                  alpha: 0.06 + glow * 0.03,
                                ),
                                AppColors.darkNavy,
                                AppColors.amber.withValues(alpha: 0.03),
                              ],
                            )
                          : LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colors.surface,
                                AppColors.darkNavy,
                              ],
                            ))
                    : null,
                border: Border.all(
                  color: isDark
                      ? (isPremium
                            ? AppColors.amber.withValues(
                                alpha: 0.2 + glow * 0.15,
                              )
                            : colors.borderSubtle)
                      : (isPremium
                            ? AppColors.amber.withValues(
                                alpha: 0.4 + glow * 0.2,
                              )
                            : (_isHovered
                                  ? const Color(0xFFCBD5E1)
                                  : const Color(0xFFE2E8F0))),
                  width: isPremium ? 1.5 : 1,
                ),
                boxShadow: isDark
                    ? (isPremium
                          ? [
                              BoxShadow(
                                color: AppColors.amber.withValues(
                                  alpha: 0.08 + glow * 0.06,
                                ),
                                blurRadius: 40,
                                spreadRadius: -4,
                              ),
                            ]
                          : (_isHovered
                    ? [
                        BoxShadow(
                          color: colors.surface,
                          blurRadius: 20,
                        ),
                      ]
                                : null))
                    : [
                        BoxShadow(
                          color: isPremium
                              ? AppColors.amber.withValues(
                                  alpha: 0.12 + glow * 0.08,
                                )
                               : colors.surface,
                          blurRadius: isPremium ? 32 : 16,
                          spreadRadius: -4,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isPremium)
                              Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.amber,
                                      Color(0xFFFFD700),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.amber.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'RECOMMENDED',
                                  style: TextStyle(
                                    color: colors.textOnAmber,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            Text(
                              plan.name,
                              style: TextStyle(
                                color: isPremium
                                    ? AppColors.amber
                                    : colors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (isFree)
                            Text(
                              'FREE',
                              style: TextStyle(
                                color: colors.textMuted,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            )
                          else
                            ShaderMask(
                              shaderCallback: (b) => LinearGradient(
                                colors: [
                                  AppColors.amber,
                                  const Color(0xFFFFD700),
                                ],
                              ).createShader(b),
                              child: Text(
                                plan.price.replaceAll('/mo', ''),
                                style: TextStyle(
                                  color: isDark
                                      ? colors.textPrimary
                                      : AppColors.darkNavy,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          if (!isFree)
                            Text(
                              'per month',
                              style: TextStyle(
                                color: colors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          (isPremium
                                  ? AppColors.amber
                                  : (isDark ? colors.textPrimary : colors.textMuted))
                              .withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Features
                  if (isPremium && plan.premiumFeatures != null) ...[
                    // "Everything in Free ✓" header
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.successGreen,
                                  const Color(0xFF00CC66),
                                ],
                              ),
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              color: colors.textOnAmber,
                              size: 11,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Everything in Free',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Premium section header
                    if (plan.premiumHeader != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          plan.premiumHeader!,
                          style: TextStyle(
                            color: AppColors.amber,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    // Premium features
                    ...plan.premiumFeatures!.map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.amber,
                                      Color(0xFFFFD700),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.amber.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.check_rounded,
                                  color: colors.textOnAmber,
                                  size: 11,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  f,
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ] else
                    ...plan.features.map((f) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: isPremium
                                      ? [
                                          AppColors.amber,
                                          const Color(0xFFFFD700),
                                        ]
                                      : [
                                          AppColors.successGreen,
                                          const Color(0xFF00CC66),
                                        ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        (isPremium
                                                ? AppColors.amber
                                                : AppColors.successGreen)
                                            .withValues(alpha: 0.2),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.check_rounded,
                                color: colors.textOnAmber,
                                size: 11,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                f,
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                  const SizedBox(height: 20),

                  // CTA
                  _buildCTAButton(isPremium, isCurrentPlan, widget.currentPlanId),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCTAButton(bool isPremium, bool isCurrentPlan, String? currentPlanId) {
    final isUserOnPremium = currentPlanId != null &&
        currentPlanId.isNotEmpty &&
        currentPlanId.endsWith('_pro');

    // Case 1: This is the user's current plan
    if (isCurrentPlan) {
      return _GlowButton(
        label: 'Current Plan',
        isPremium: isPremium,
        isEnabled: false,
        onTap: widget.onUpgrade,
      );
    }

    // Case 2: User is on Free, viewing Free (shouldn't happen but safety)
    if (!isPremium && !isUserOnPremium) {
      return _GlowButton(
        label: 'Current Plan',
        isPremium: false,
        isEnabled: false,
        onTap: widget.onUpgrade,
      );
    }

    // Case 3: User is on Free, viewing Premium → upgrade
    if (isPremium && !isUserOnPremium) {
      return _GlowButton(
        label: 'UPGRADE TO PREMIUM',
        isPremium: true,
        isEnabled: true,
        onTap: widget.onUpgrade,
      );
    }

    // Case 4: User is on Premium, viewing Free → downgrade
    if (!isPremium && isUserOnPremium) {
      return _GlowButton(
        label: 'Downgrade to Free',
        isPremium: false,
        isEnabled: true,
        onTap: widget.onUpgrade,
        isDanger: true,
      );
    }

    // Case 5: User is on Premium, viewing Premium (different plan) → switch
    if (isPremium && isUserOnPremium) {
      return _GlowButton(
        label: 'Current Plan',
        isPremium: true,
        isEnabled: false,
        onTap: widget.onUpgrade,
      );
    }

    return const SizedBox.shrink();
  }
}

// ─── GLOW BUTTON ───

class _GlowButton extends StatelessWidget {
  final String label;
  final bool isPremium;
  final bool isEnabled;
  final bool isDanger;
  final VoidCallback onTap;

  const _GlowButton({
    required this.label,
    this.isPremium = false,
    this.isEnabled = true,
    this.isDanger = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isEnabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: isPremium && isEnabled
              ? const LinearGradient(
                  colors: [AppColors.amber, Color(0xFFFFD700)],
                )
              : (isDanger && isEnabled
                    ? const LinearGradient(
                        colors: [Colors.orangeAccent, Color(0xFFFF6B35)],
                      )
                    : (isDark
                          ? LinearGradient(
                              colors: [
                                colors.surface,
                                colors.surface,
                              ],
                            )
                          : null)),
          color: (!isPremium || !isEnabled) && !isDark && !(isDanger && isEnabled)
              ? (isEnabled ? colors.surface : colors.containerFill)
              : null,
          boxShadow: isPremium && isEnabled
              ? [
                  BoxShadow(
                    color: AppColors.amber.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : (isDanger && isEnabled
                    ? [
                        BoxShadow(
                          color: Colors.orangeAccent.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : (!isDark && isEnabled
                    ? [
                        BoxShadow(
                          color: colors.surface,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                          : null)),
          border: isPremium && isEnabled || (isDanger && isEnabled)
              ? null
              : Border.all(
                    color: colors.borderSubtle,
                ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isPremium && isEnabled || (isDanger && isEnabled)
                  ? colors.textOnAmber
                  : (isDark
                        ? (isEnabled ? colors.textPrimary : colors.textMuted)
                        : (isEnabled ? colors.textPrimary : colors.textMuted)),
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── LOADING PULSE ───

class _LoadingPulse extends StatefulWidget {
  const _LoadingPulse();
  @override
  State<_LoadingPulse> createState() => _LoadingPulseState();
}

class _LoadingPulseState extends State<_LoadingPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.amber.withValues(alpha: 0.1 + _c.value * 0.15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.amber.withValues(alpha: 0.4 + _c.value * 0.6),
          ),
        ),
      ),
    );
  }
}

// ─── TRUST PILL ───

class _TrustPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TrustPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.borderSubtle,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colors.iconMuted, size: 12),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── PAYMENT SHEET ───

class _PaymentSheet extends StatelessWidget {
  final SubscriptionPlan plan;
  final VoidCallback onConfirm;
  const _PaymentSheet({required this.plan, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: colors.bottomSheetBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? AppColors.amber.withValues(alpha: 0.15)
              : colors.borderDefault,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.surface,
            blurRadius: 40,
          ),
        ],
      ),
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.amber.withValues(alpha: 0.15),
                  AppColors.amber.withValues(alpha: 0.05),
                ],
              ),
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
            'Upgrade to ${plan.name}',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [AppColors.amber, Color(0xFFFFD700)],
            ).createShader(b),
            child: Text(
              plan.price,
              style: TextStyle(
                color: isDark ? colors.textPrimary : AppColors.darkNavy,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Billed monthly. Cancel anytime.',
            style: TextStyle(color: colors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: onConfirm,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.amber, Color(0xFFFFD700)],
                ),
                borderRadius: BorderRadius.circular(16),
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
                  'Pay with Flutterwave',
                  style: TextStyle(
                    color: colors.textOnAmber,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
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
        ],
      ),
    );
  }
}

// ─── COMPARISON SHEET ───

class _ComparisonSheet extends StatelessWidget {
  final List<SubscriptionPlan> plans;
  const _ComparisonSheet({required this.plans});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final freePlan = plans.firstWhere(
      (p) => p.amount == 0,
      orElse: () => plans.first,
    );
    final proPlan = plans.firstWhere(
      (p) => p.amount > 0,
      orElse: () => plans.last,
    );
    final premiumFeatures = proPlan.premiumFeatures ?? [];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: colors.bottomSheetBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colors.borderSubtle,
        ),
      ),
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
          const SizedBox(height: 20),
          Text(
            'Feature Comparison',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Feature',
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    'FREE',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                      colors: [AppColors.amber, Color(0xFFFFD700)],
                    ).createShader(b),
                    child: Text(
                      'PRO',
                      style: TextStyle(
                        color: isDark ? colors.textPrimary : AppColors.darkNavy,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: colors.divider),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: premiumFeatures.length,
              itemBuilder: (_, i) {
                final feature = premiumFeatures[i];
                final isInFree = freePlan.features.any(
                  (f) => f.toLowerCase() == feature.toLowerCase(),
                );
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: colors.divider)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          feature,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: isInFree
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.successGreen,
                                  size: 16,
                                )
                              : Icon(
                                  Icons.remove_rounded,
                                  color: colors.textHint,
                                  size: 16,
                                ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: const Center(
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.amber,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              final nav = ProviderScope.containerOf(context).read(navigationStackProvider.notifier);
              if (nav.canPop) {
                nav.pop();
              } else {
                nav.set('/main');
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.borderDefault),
              ),
              child: Center(
                child: Text(
                  'Close',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── VERIFYING OVERLAY ───

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

class _VerifyingOverlayState extends State<_VerifyingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  int _attempts = 0;
  static const int _maxAttempts = 30;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _startVerification();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startVerification() async {
    await Future.delayed(const Duration(seconds: 3));
    _pollVerification();
  }

  Future<void> _pollVerification() async {
    if (!mounted || _attempts >= _maxAttempts) {
      if (mounted) widget.onFailed();
      return;
    }

    _attempts++;
    try {
      final verified = await widget.flutterwaveService.verifyTransaction(
        widget.txRef,
      );

      if (!mounted) return;

      if (verified) {
        widget.onVerified();
      } else {
        await Future.delayed(const Duration(seconds: 3));
        _pollVerification();
      }
    } catch (e) {
      debugPrint('[SUB_PLANS] Verify attempt $_attempts failed: $e');
      if (!mounted) return;
      if (_attempts >= _maxAttempts) {
        widget.onFailed();
      } else {
        await Future.delayed(const Duration(seconds: 3));
        _pollVerification();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.scaffoldBg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, _) {
                final v = _pulseController.value;
                return Container(
                  width: 80 + v * 20,
                  height: 80 + v * 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.amber.withValues(alpha: 0.3 - v * 0.2),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.amber.withValues(alpha: 0.15),
                            AppColors.amber.withValues(alpha: 0.05),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: AppColors.amber,
                        size: 28,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 28),
            Text(
              'Verifying Payment',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Confirming your transaction...',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _maxAttempts,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _attempts
                        ? AppColors.amber
                        : colors.surface,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Complete payment in the other tab, then return here.',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => widget.onFailed(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SUCCESS OVERLAY ───

class _SuccessOverlay extends StatefulWidget {
  final String planName;
  const _SuccessOverlay({required this.planName});
  @override
  State<_SuccessOverlay> createState() => _SuccessOverlayState();
}

class _SuccessOverlayState extends State<_SuccessOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted)
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/main', (route) => false);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.scaffoldBg,
      child: Center(
        child: ScaleTransition(
          scale: CurvedAnimation(parent: _c, curve: Curves.elasticOut),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.amber, Color(0xFFFFD700)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.amber.withValues(alpha: 0.4),
                      blurRadius: 40,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: colors.textOnAmber,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome to',
                style: TextStyle(color: colors.textPrimary, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                widget.planName,
                style: TextStyle(
                  color: AppColors.amber,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── AMBIENT GLOW PAINTER ───

class _AmbientGlowPainter extends CustomPainter {
  final double animation;
  final double glowAnimation;
  _AmbientGlowPainter({required this.animation, required this.glowAnimation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);

    paint.color = AppColors.amber.withValues(
      alpha: 0.03 + glowAnimation * 0.02,
    );
    canvas.drawCircle(
      Offset(
        size.width * 0.2 + sin(animation * 2 * pi) * 30,
        size.height * 0.15,
      ),
      120,
      paint,
    );

    paint.color = AppColors.successGreen.withValues(
      alpha: 0.02 + glowAnimation * 0.01,
    );
    canvas.drawCircle(
      Offset(
        size.width * 0.8 + cos(animation * 2 * pi) * 20,
        size.height * 0.85,
      ),
      100,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _AmbientGlowPainter old) => true;
}
