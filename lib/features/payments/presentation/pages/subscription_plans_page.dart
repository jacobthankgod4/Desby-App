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

class _SubscriptionPlansPageState extends ConsumerState<SubscriptionPlansPage> {
  final FlutterwaveService _flutterwaveService = FlutterwaveService();
  int _selectedPlanIndex = -1;

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
                const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                const SizedBox(height: 16),
                Text('Could not load plans', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(availablePlansProvider),
                  child: const Text('Retry'),
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
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 18),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getTitle(userType),
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 56),
                  child: Text(
                    _getSubtitle(userType),
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),

        // Plans
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final plan = plans[index];
                return AnimatedEntry(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
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

        // Skip
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
            child: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false),
                child: Text(
                  'Continue with free plan',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getTitle(String userType) {
    switch (userType) {
      case 'tailor': return 'Grow Your Tailoring Business';
      case 'client': return 'Choose Your Plan';
      case 'apprentice': return 'Level Up Your Skills';
      case 'fabric_seller': return 'Expand Your Shop';
      default: return 'Choose Your Plan';
    }
  }

  String _getSubtitle(String userType) {
    switch (userType) {
      case 'tailor': return 'Unlock powerful tools to manage and grow your business';
      case 'client': return 'Access premium features for the best tailoring experience';
      case 'apprentice': return 'Get access to advanced learning and mentorship';
      case 'fabric_seller': return 'Reach more buyers and grow your fabric business';
      default: return 'Pick the plan that works best for you';
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

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isElite
                ? AppColors.amber.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isElite
                  ? AppColors.amber.withValues(alpha: _isHovered ? 0.5 : 0.3)
                  : isSelected
                      ? AppColors.amber.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: _isHovered ? 0.12 : 0.06),
              width: isElite ? 2 : 1,
            ),
            boxShadow: isElite
                ? [BoxShadow(color: AppColors.amber.withValues(alpha: 0.08), blurRadius: 30, offset: const Offset(0, 10))]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isElite)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.amber,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('MOST POPULAR', style: TextStyle(color: AppColors.darkNavy, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                        ),
                      Text(plan.name, style: TextStyle(
                        color: isElite ? AppColors.amber : Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      )),
                    ],
                  ),
                  Text(plan.price, style: TextStyle(
                    color: isElite ? AppColors.amber : Colors.white,
                    fontSize: plan.price == 'FREE' ? 22 : 18,
                    fontWeight: FontWeight.w900,
                  )),
                ],
              ),
              const SizedBox(height: 20),
              Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
              const SizedBox(height: 20),

              // Features
              ...plan.features.map((f) {
                final isSectionHeader = f.contains('PLUS:') || f.contains('EVERYTHING IN');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isSectionHeader)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: (isElite ? AppColors.amber : const Color(0xFF00FF7F)).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.check_rounded, color: isElite ? AppColors.amber : const Color(0xFF00FF7F), size: 12),
                        ),
                      if (!isSectionHeader) const SizedBox(width: 12),
                      Expanded(
                        child: Text(f, style: TextStyle(
                          color: isSectionHeader
                              ? (isElite ? AppColors.amber : Colors.white)
                              : Colors.white.withValues(alpha: 0.6),
                          fontSize: isSectionHeader ? 10 : 13,
                          fontWeight: isSectionHeader ? FontWeight.w900 : FontWeight.w500,
                          letterSpacing: isSectionHeader ? 1 : 0,
                          height: 1.4,
                        )),
                      ),
                    ],
                  ),
                );
              }).toList(),

              const SizedBox(height: 20),

              // CTA Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: widget.onUpgrade,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isElite
                        ? AppColors.amber
                        : _isHovered
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.white.withValues(alpha: 0.04),
                    foregroundColor: isElite ? AppColors.darkNavy : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(
                    plan.amount == 0 ? 'Get Started Free' : plan.buttonLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 0.5,
                      color: isElite ? AppColors.darkNavy : Colors.white,
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
