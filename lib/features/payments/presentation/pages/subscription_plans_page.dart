import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/colors.dart';
import '../../../../core/widgets/onboarding_scaffold.dart';
import '../../../../core/services/paystack_service.dart';
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
  final PaystackService _paystackService = PaystackService();

  void _handleUpgrade(SubscriptionPlan plan) {
    FocusManager.instance.primaryFocus?.unfocus();
    
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      
      if (plan.amount == 0) {
        Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
      } else {
        final user = ref.read(currentUserProvider);
        if (user == null) return;

        _paystackService.checkout(
          context: context,
          email: user.email,
          amount: plan.amount,
          reference: 'SUB_${user.id.substring(0, 5)}_${DateTime.now().millisecondsSinceEpoch}',
          onSuccess: (refId) async {
            final profile = ref.read(userProfileProvider(user.id)).value;
            if (profile != null) {
              final updatedProfile = profile.copyWith(
                subscriptionPlanId: plan.id,
                subscriptionExpiry: DateTime.now().add(const Duration(days: 30)),
              );
              await ref.read(updateProfileUsecaseProvider)(updatedProfile);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Upgrade to ${plan.name} Successful!'), backgroundColor: Colors.greenAccent),
              );
              Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
            }
          },
          onCancel: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upgrade Cancelled')));
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(availablePlansProvider);

    return OnboardingScaffold(
      currentStep: 0,
      totalSteps: 1,
      title: 'Level Up Your Game',
      stepLabel: 'Professional Tier',
      prompt: 'Select your path to mastery',
      onBack: () => Navigator.pop(context),
      onNext: null,
      nextLabel: 'SKIP FOR NOW',
      content: plansAsync.when(
        data: (plans) {
          return Center(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // RESPONSIVE LAYOUT: Wrap for better multi-platform support
                Wrap(
                  spacing: 16,
                  runSpacing: 24,
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: plans.map((plan) => ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 350,
                      minHeight: 600,
                    ),
                    child: _buildPlanCard(plan),
                  )).toList(),
                ),
                const SizedBox(height: 56),
                TextButton(
                  onPressed: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    Future.delayed(const Duration(milliseconds: 150), () {
                      if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
                    });
                  },
                  child: const Text('STAY ON FREE TIER FOR NOW', 
                    style: TextStyle(color: Colors.white38, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2)),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: Padding(padding: EdgeInsets.all(100), child: CircularProgressIndicator(color: AppColors.amber))),
        error: (error, _) => Center(child: Text('Error: $error', style: const TextStyle(color: Colors.white70))),
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: plan.isElite ? AppColors.amber.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.08),
          width: plan.isElite ? 2.5 : 1,
        ),
        boxShadow: plan.isElite ? [
          BoxShadow(color: AppColors.amber.withValues(alpha: 0.05), blurRadius: 30, offset: const Offset(0, 10))
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (plan.isElite)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.amber, borderRadius: BorderRadius.circular(8)),
              child: const Text('RECOMMENDED', style: TextStyle(color: AppColors.darkNavy, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
            )
          else
            const SizedBox(height: 28),
            
          Text(plan.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(plan.price, style: const TextStyle(color: AppColors.amber, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1)),
          const SizedBox(height: 24),
          const Divider(height: 1, color: Colors.white12),
          const SizedBox(height: 24),
          
          ...plan.features.map((f) {
            final isHeader = f.contains('PLUS:');
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isHeader) const Icon(Icons.check_circle_rounded, color: AppColors.amber, size: 14),
                  if (!isHeader) const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      f, 
                      style: TextStyle(
                        color: isHeader ? AppColors.amber : Colors.white70, 
                        fontSize: isHeader ? 11 : 12, 
                        fontWeight: isHeader ? FontWeight.w900 : FontWeight.w600,
                        height: 1.3,
                        letterSpacing: isHeader ? 0.5 : 0,
                      )
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          
          const Spacer(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () => _handleUpgrade(plan),
              style: ElevatedButton.styleFrom(
                backgroundColor: plan.isElite ? AppColors.amber : Colors.white.withValues(alpha: 0.05),
                foregroundColor: plan.isElite ? AppColors.darkNavy : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              child: Text(plan.buttonLabel, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5)),
            ),
          ),
        ],
      ),
    );
  }
}
