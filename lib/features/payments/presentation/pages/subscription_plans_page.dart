import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/colors.dart';
import '../../../../core/services/flutterwave_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/models/plan_registry.dart';
import '../providers/subscription_provider.dart';

class SubscriptionPlansPage extends ConsumerStatefulWidget {
  const SubscriptionPlansPage({super.key});

  @override
  ConsumerState<SubscriptionPlansPage> createState() => _SubscriptionPlansPageState();
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
    _heroController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _glowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _floatController = AnimationController(vsync: this, duration: const Duration(milliseconds: 6000))..repeat();
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
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      if (plan.amount == 0) {
        Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
        return;
      }
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      _showPaymentSheet(plan, user);
    });
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
      amount: plan.amount,
      orderId: 'SUB_${user.id.substring(0, 8)}',
      onSuccess: (txId) async {
        final profile = ref.read(userProfileProvider(user.id)).value;
        if (profile != null) {
          final updatedProfile = profile.copyWith(
            subscriptionPlanId: plan.id,
            subscriptionExpiry: DateTime.now().add(const Duration(days: 30)),
          );
          await ref.read(updateProfileUsecaseProvider)(updatedProfile);
          if (!mounted) return;
          _showSuccessOverlay(plan.name);
        }
      },
      onCancel: () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Payment cancelled'),
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
    );
  }

  void _showSuccessOverlay(String planName) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'success',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (_, anim, __, ___) {
        return FadeTransition(
          opacity: anim,
          child: _SuccessOverlay(planName: planName),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(availablePlansProvider);
    final user = ref.watch(currentUserProvider);
    final userType = user?.userType ?? 'tailor';

    return Scaffold(
      backgroundColor: const Color(0xFF060B14),
      body: Stack(
        children: [
          // Ambient glow
          AnimatedBuilder(
            animation: _floatController,
            builder: (_, __) => CustomPaint(
              size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
              painter: _AmbientGlowPainter(
                animation: _floatController.value,
                glowAnimation: _glowController.value,
              ),
            ),
          ),
          // Content
          SafeArea(
            child: plansAsync.when(
              data: (plans) => _buildContent(plans, userType),
              loading: () => const Center(child: _LoadingPulse()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
                    const SizedBox(height: 16),
                    Text('Could not load plans', style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
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

  Widget _buildContent(List<SubscriptionPlan> plans, String userType) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header
        SliverToBoxAdapter(child: _buildHeader()),

        // Hero
        SliverToBoxAdapter(child: _buildHero(userType)),

        // Price highlight
        SliverToBoxAdapter(child: _buildPriceHighlight()),

        // Plans
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
                  onTap: () => setState(() => _selectedPlanIndex = index),
                  onUpgrade: () => _handleUpgrade(plans[index]),
                ),
              ),
              childCount: plans.length,
            ),
          ),
        ),

        // Comparison table button
        SliverToBoxAdapter(child: _buildCompareButton(plans)),

        // Trust
        SliverToBoxAdapter(child: _buildTrust()),

        // Skip
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            child: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false),
                child: Text('Maybe later', style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 13)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white54, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppColors.amber, Color(0xFFFFD700)],
            ).createShader(bounds),
            child: const Text(
              'DESBY',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(String userType) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _heroController, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
            .animate(CurvedAnimation(parent: _heroController, curve: Curves.easeOutCubic)),
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.amber.withValues(alpha: 0.12),
                const Color(0xFF060B14),
              ],
            ),
            border: Border.all(color: AppColors.amber.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.amber.withValues(alpha: 0.2), AppColors.amber.withValues(alpha: 0.05)]),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.amber.withValues(alpha: 0.2)),
                ),
                child: Text(
                  _getHeroLabel(userType),
                  style: const TextStyle(color: AppColors.amber, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _getHeroTitle(userType),
                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, height: 1.15, letterSpacing: -0.5),
              ),
              const SizedBox(height: 10),
              Text(
                _getHeroSubtitle(userType),
                style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceHighlight() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('₦', style: TextStyle(color: AppColors.amber.withValues(alpha: 0.5), fontSize: 20, fontWeight: FontWeight.w900)),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppColors.amber, Color(0xFFFFD700), AppColors.amber],
            ).createShader(bounds),
            child: const Text(
              '2,500',
              style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: -2, height: 1),
            ),
          ),
          Text('/mo', style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildCompareButton(List<SubscriptionPlan> plans) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: GestureDetector(
        onTap: () => _showComparisonSheet(plans),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.compare_arrows_rounded, color: Colors.white.withValues(alpha: 0.3), size: 18),
              const SizedBox(width: 8),
              Text('Compare all features', style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 12, fontWeight: FontWeight.w600)),
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
          _TrustPill(icon: Icons.replay_circle_filled_rounded, label: 'Cancel anytime'),
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
    _ => 'PREMIUM',
  };

  String _getHeroTitle(String u) => switch (u) {
    'tailor' => 'Scale your tailoring business',
    'client' => 'Elevate your style journey',
    'apprentice' => 'Accelerate your craft',
    'fabric_seller' => 'Grow your fabric empire',
    _ => 'Choose your plan',
  };

  String _getHeroSubtitle(String u) => switch (u) {
    'tailor' => 'AI-powered tools, unlimited clients, and priority discovery to grow your brand.',
    'client' => 'Virtual try-on, AI body scanning, and exclusive access to top tailors.',
    'apprentice' => 'Advanced modules, multiple mentors, and certificates to fast-track your career.',
    'fabric_seller' => 'Verified status, buyer leads, and wholesale tools to scale your shop.',
    _ => 'Pick the plan that works best for you.',
  };
}

// ─── HYPER PLAN CARD ───

class _HyperPlanCard extends StatefulWidget {
  final SubscriptionPlan plan;
  final int index;
  final bool isSelected;
  final AnimationController glowAnimation;
  final VoidCallback onTap;
  final VoidCallback onUpgrade;

  const _HyperPlanCard({
    required this.plan,
    required this.index,
    required this.isSelected,
    required this.glowAnimation,
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
    final plan = widget.plan;
    final isPremium = plan.isElite;
    final isFree = plan.amount == 0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: widget.glowAnimation,
          builder: (_, __) {
            final glow = widget.glowAnimation.value;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: isPremium
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.amber.withValues(alpha: 0.06 + glow * 0.03),
                          const Color(0xFF060B14),
                          AppColors.amber.withValues(alpha: 0.03),
                        ],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: _isHovered ? 0.04 : 0.02),
                          const Color(0xFF060B14),
                        ],
                      ),
                border: Border.all(
                  color: isPremium
                      ? AppColors.amber.withValues(alpha: 0.2 + glow * 0.15)
                      : Colors.white.withValues(alpha: _isHovered ? 0.1 : 0.05),
                  width: isPremium ? 1.5 : 1,
                ),
                boxShadow: isPremium
                    ? [
                        BoxShadow(
                          color: AppColors.amber.withValues(alpha: 0.08 + glow * 0.06),
                          blurRadius: 40,
                          spreadRadius: -4,
                        ),
                      ]
                    : _isHovered
                        ? [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20)]
                        : null,
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
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [AppColors.amber, Color(0xFFFFD700)]),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [BoxShadow(color: AppColors.amber.withValues(alpha: 0.3), blurRadius: 8)],
                                ),
                                child: const Text('RECOMMENDED', style: TextStyle(color: AppColors.darkNavy, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                              ),
                            Text(plan.name, style: TextStyle(
                              color: isPremium ? AppColors.amber : Colors.white,
                              fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.3,
                            )),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (isFree)
                            Text('FREE', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 22, fontWeight: FontWeight.w900))
                          else
                            ShaderMask(
                              shaderCallback: (b) => LinearGradient(colors: [AppColors.amber, const Color(0xFFFFD700)]).createShader(b),
                              child: Text(plan.price.replaceAll('/mo', ''), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                            ),
                          if (!isFree)
                            Text('per month', style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 11)),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Container(height: 1, decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Colors.transparent,
                      (isPremium ? AppColors.amber : Colors.white).withValues(alpha: 0.1),
                      Colors.transparent,
                    ]),
                  )),
                  const SizedBox(height: 20),

                  // Features
                  ...plan.features.map((f) {
                    final isHeader = f.contains('PLUS:') || f.contains('EVERYTHING IN');
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isHeader)
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              width: 18, height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: isPremium
                                      ? [AppColors.amber, const Color(0xFFFFD700)]
                                      : [const Color(0xFF00FF7F), const Color(0xFF00CC66)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isPremium ? AppColors.amber : const Color(0xFF00FF7F)).withValues(alpha: 0.2),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.check_rounded, color: AppColors.darkNavy, size: 11),
                            ),
                          if (!isHeader) const SizedBox(width: 12),
                          Expanded(
                            child: Text(f, style: TextStyle(
                              color: isHeader
                                  ? (isPremium ? AppColors.amber : Colors.white.withValues(alpha: 0.7))
                                  : Colors.white.withValues(alpha: 0.5),
                              fontSize: isHeader ? 10 : 13,
                              fontWeight: isHeader ? FontWeight.w900 : FontWeight.w500,
                              letterSpacing: isHeader ? 1 : 0,
                              height: 1.4,
                            )),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 20),

                  // CTA
                  _GlowButton(
                    label: isFree ? 'Get Started Free' : plan.buttonLabel,
                    isPremium: isPremium,
                    onTap: widget.onUpgrade,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── GLOW BUTTON ───

class _GlowButton extends StatelessWidget {
  final String label;
  final bool isPremium;
  final VoidCallback onTap;

  const _GlowButton({required this.label, this.isPremium = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: isPremium
              ? const LinearGradient(colors: [AppColors.amber, Color(0xFFFFD700)])
              : LinearGradient(colors: [
                  Colors.white.withValues(alpha: 0.06),
                  Colors.white.withValues(alpha: 0.02),
                ]),
          boxShadow: isPremium
              ? [BoxShadow(color: AppColors.amber.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6))]
              : null,
          border: isPremium ? null : Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Center(
          child: Text(label, style: TextStyle(
            color: isPremium ? AppColors.darkNavy : Colors.white,
            fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5,
          )),
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

class _LoadingPulseState extends State<_LoadingPulse> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Container(
        width: 40, height: 40,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.25), size: 12),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10, fontWeight: FontWeight.w600)),
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
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 40)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.amber.withValues(alpha: 0.15), AppColors.amber.withValues(alpha: 0.05)]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.workspace_premium_rounded, color: AppColors.amber, size: 32),
          ),
          const SizedBox(height: 20),
          Text('Upgrade to ${plan.name}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(colors: [AppColors.amber, Color(0xFFFFD700)]).createShader(b),
            child: Text(plan.price, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 8),
          Text('Billed monthly. Cancel anytime.', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: onConfirm,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.amber, Color(0xFFFFD700)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppColors.amber.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: const Center(
                child: Text('Pay with Flutterwave', style: TextStyle(color: AppColors.darkNavy, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded, color: Colors.white.withValues(alpha: 0.15), size: 12),
              const SizedBox(width: 4),
              Text('Secured by Flutterwave', style: TextStyle(color: Colors.white.withValues(alpha: 0.15), fontSize: 10)),
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
    final freePlan = plans.firstWhere((p) => p.amount == 0, orElse: () => plans.first);
    final premiumPlan = plans.firstWhere((p) => p.amount > 0, orElse: () => plans.last);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Text('Feature Comparison', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),
          // Header
          Row(children: [
            const Expanded(flex: 3, child: Text('Feature', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1))),
            Expanded(flex: 2, child: Center(child: Text('FREE', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)))),
            Expanded(flex: 2, child: Center(child: ShaderMask(
              shaderCallback: (b) => const LinearGradient(colors: [AppColors.amber, Color(0xFFFFD700)]).createShader(b),
              child: const Text('PRO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ))),
          ]),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: premiumPlan.features.length,
              itemBuilder: (_, i) {
                final feature = premiumPlan.features[i];
                final isHeader = feature.contains('PLUS:') || feature.contains('EVERYTHING IN');
                final isInFree = freePlan.features.any((f) => f.toLowerCase() == feature.toLowerCase());
                if (isHeader) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.03)))),
                  child: Row(children: [
                    Expanded(flex: 3, child: Text(feature, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12))),
                    Expanded(flex: 2, child: Center(
                      child: isInFree
                          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF00FF7F), size: 16)
                          : Icon(Icons.remove_rounded, color: Colors.white.withValues(alpha: 0.1), size: 16),
                    )),
                    Expanded(flex: 2, child: const Center(child: Icon(Icons.check_circle_rounded, color: AppColors.amber, size: 16))),
                  ]),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
              child: Center(child: Text('Close', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13, fontWeight: FontWeight.w600))),
            ),
          ),
        ],
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

class _SuccessOverlayState extends State<_SuccessOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..forward();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
    });
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: ScaleTransition(
          scale: CurvedAnimation(parent: _c, curve: Curves.elasticOut),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.amber, Color(0xFFFFD700)]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.amber.withValues(alpha: 0.4), blurRadius: 40)],
                ),
                child: const Icon(Icons.check_rounded, color: AppColors.darkNavy, size: 48),
              ),
              const SizedBox(height: 24),
              const Text('Welcome to', style: TextStyle(color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 4),
              Text(widget.planName, style: const TextStyle(color: AppColors.amber, fontSize: 28, fontWeight: FontWeight.w900)),
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
    final paint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);

    // Top-left glow
    paint.color = AppColors.amber.withValues(alpha: 0.03 + glowAnimation * 0.02);
    canvas.drawCircle(
      Offset(size.width * 0.2 + sin(animation * 2 * pi) * 30, size.height * 0.15),
      120,
      paint,
    );

    // Bottom-right glow
    paint.color = const Color(0xFF00FF7F).withValues(alpha: 0.02 + glowAnimation * 0.01);
    canvas.drawCircle(
      Offset(size.width * 0.8 + cos(animation * 2 * pi) * 20, size.height * 0.85),
      100,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _AmbientGlowPainter old) => true;
}
