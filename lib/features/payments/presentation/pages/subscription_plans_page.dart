import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/colors.dart';
import '../../../../core/services/flutterwave_service.dart';
import '../../../../core/widgets/animated_entry.dart';
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
    with SingleTickerProviderStateMixin {
  final FlutterwaveService _flutterwaveService = FlutterwaveService();
  int _selectedPlanIndex = -1;
  late AnimationController _heroController;
  late Animation<double> _heroFade;
  late Animation<Offset> _heroSlide;

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _heroFade = CurvedAnimation(parent: _heroController, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _heroController, curve: Curves.easeOutCubic));
    _heroController.forward();
  }

  @override
  void dispose() {
    _heroController.dispose();
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

      _flutterwaveService.checkout(
        context: context,
        email: user.email,
        fullName: user.name,
        amount: plan.amount,
        orderId: 'SUB_${user.id.substring(0, 5)}',
        onSuccess: (txId) async {
          final profile = ref.read(userProfileProvider(user.id)).value;
          if (profile != null) {
            final updatedProfile = profile.copyWith(
              subscriptionPlanId: plan.id,
              subscriptionExpiry: DateTime.now().add(const Duration(days: 30)),
            );
            await ref.read(updateProfileUsecaseProvider)(updatedProfile);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Upgraded to ${plan.name} successfully!'),
                backgroundColor: const Color(0xFF00FF7F),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
            Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
          }
        },
        onCancel: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Payment cancelled'),
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(availablePlansProvider);
    final user = ref.watch(currentUserProvider);
    final userType = user?.userType ?? 'tailor';

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: SafeArea(
        child: plansAsync.when(
          data: (plans) => _buildContent(plans, userType),
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amber)),
          error: (error, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
                ),
                const SizedBox(height: 16),
                Text('Could not load plans', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(availablePlansProvider),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    foregroundColor: AppColors.darkNavy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(List<SubscriptionPlan> plans, String userType) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Hero Section
        SliverToBoxAdapter(child: _buildHero(userType)),

        // Plans Section
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final plan = plans[index];
                return AnimatedEntry(
                  index: index + 2,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _PlanCard(
                      plan: plan,
                      isSelected: _selectedPlanIndex == index,
                      onTap: () => setState(() => _selectedPlanIndex = index),
                      onUpgrade: () => _handleUpgrade(plan),
                    ),
                  ),
                );
              },
              childCount: plans.length,
            ),
          ),
        ),

        // Trust Section
        SliverToBoxAdapter(child: _buildTrustBadges()),

        // Skip
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            child: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false),
                child: Text(
                  'Maybe later',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 13),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHero(String userType) {
    return FadeTransition(
      opacity: _heroFade,
      child: SlideTransition(
        position: _heroSlide,
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          height: 220,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image with blur overlay
              Image.asset(
                'assets/images/tailor-full.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.amber.withValues(alpha: 0.3), AppColors.darkNavy],
                    ),
                  ),
                ),
              ),
              // Dark overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.5),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _getHeroLabel(userType),
                        style: const TextStyle(color: AppColors.amber, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getHeroTitle(userType),
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1.2, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getHeroSubtitle(userType),
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrustBadges() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _TrustBadge(icon: Icons.lock_outline_rounded, label: 'Secure Payment'),
          const SizedBox(width: 24),
          _TrustBadge(icon: Icons.cancel_outlined, label: 'Cancel Anytime'),
          const SizedBox(width: 24),
          _TrustBadge(icon: Icons.support_agent_rounded, label: '24/7 Support'),
        ],
      ),
    );
  }

  String _getHeroLabel(String userType) {
    switch (userType) {
      case 'tailor': return 'FOR TAILORS';
      case 'client': return 'FOR CLIENTS';
      case 'apprentice': return 'FOR APPRENTICES';
      case 'fabric_seller': return 'FOR SELLERS';
      default: return 'PREMIUM';
    }
  }

  String _getHeroTitle(String userType) {
    switch (userType) {
      case 'tailor': return 'Grow your tailoring business';
      case 'client': return 'Premium tailoring experience';
      case 'apprentice': return 'Accelerate your learning';
      case 'fabric_seller': return 'Scale your fabric shop';
      default: return 'Choose your plan';
    }
  }

  String _getHeroSubtitle(String userType) {
    switch (userType) {
      case 'tailor': return 'Unlock powerful tools, analytics, and priority visibility to attract more clients.';
      case 'client': return 'Get priority bookings, exclusive tailors, and premium design features.';
      case 'apprentice': return 'Access advanced courses, mentorship, and certification programs.';
      case 'fabric_seller': return 'Reach more buyers, get verified status, and boost your shop visibility.';
      default: return 'Pick the plan that works best for you.';
    }
  }
}

class _PlanCard extends StatefulWidget {
  final SubscriptionPlan plan;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onUpgrade;

  const _PlanCard({
    required this.plan,
    required this.isSelected,
    required this.onTap,
    required this.onUpgrade,
  });

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final isElite = plan.isElite;
    final isSelected = widget.isSelected;
    final isFree = plan.amount == 0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isElite
                ? AppColors.amber.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.025),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isElite
                  ? AppColors.amber.withValues(alpha: _isHovered ? 0.6 : 0.35)
                  : isSelected
                      ? AppColors.amber.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: _isHovered ? 0.12 : 0.06),
              width: isElite ? 2 : 1,
            ),
            boxShadow: isElite
                ? [
                    BoxShadow(
                      color: AppColors.amber.withValues(alpha: _isHovered ? 0.12 : 0.06),
                      blurRadius: 40,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : _isHovered
                    ? [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 8))]
                    : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isElite)
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [AppColors.amber, Color(0xFFFFD700)]),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'MOST POPULAR',
                              style: TextStyle(color: AppColors.darkNavy, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                            ),
                          ),
                        Text(
                          plan.name,
                          style: TextStyle(
                            color: isElite ? AppColors.amber : Colors.white,
                            fontSize: 22,
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
                      Text(
                        plan.price,
                        style: TextStyle(
                          color: isElite ? AppColors.amber : Colors.white,
                          fontSize: isFree ? 24 : 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (!isFree)
                        Text(
                          '/month',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
              const SizedBox(height: 20),

              // Features
              ...plan.features.map((f) {
                final isSectionHeader = f.contains('PLUS:') || f.contains('EVERYTHING IN');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isSectionHeader)
                        Container(
                          margin: const EdgeInsets.only(top: 1),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: (isElite ? AppColors.amber : const Color(0xFF00FF7F)).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            color: isElite ? AppColors.amber : const Color(0xFF00FF7F),
                            size: 12,
                          ),
                        ),
                      if (!isSectionHeader) const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          f,
                          style: TextStyle(
                            color: isSectionHeader
                                ? (isElite ? AppColors.amber : Colors.white.withValues(alpha: 0.8))
                                : Colors.white.withValues(alpha: 0.55),
                            fontSize: isSectionHeader ? 10 : 13,
                            fontWeight: isSectionHeader ? FontWeight.w900 : FontWeight.w500,
                            letterSpacing: isSectionHeader ? 1 : 0,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              const SizedBox(height: 24),

              // CTA
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 54,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onUpgrade,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isElite
                        ? AppColors.amber
                        : _isHovered
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.white.withValues(alpha: 0.04),
                    foregroundColor: isElite ? AppColors.darkNavy : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isFree ? 'Get Started' : plan.buttonLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 0.5,
                          color: isElite ? AppColors.darkNavy : Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: isElite ? AppColors.darkNavy : Colors.white,
                        size: 16,
                      ),
                    ],
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

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.25), size: 14),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
