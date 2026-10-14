import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../domain/models/plan_registry.dart';
import '../../domain/repositories/subscription_repository.dart';

class SupabaseSubscriptionRepository implements SubscriptionRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<Result<List<SubscriptionPlan>>> getPlans(String userType) async {
    try {
      final response = await _supabase
          .from('subscription_plans')
          .select()
          .eq('user_type', userType.toLowerCase())
          .order('amount', ascending: true);

      final plans = (response as List)
          .map((data) => SubscriptionPlan.fromMap(data))
          .toList();

      if (plans.isEmpty) {
        return Success(_getFallbackPlans(userType));
      }

      return Success(plans);
    } catch (e) {
      return Success(_getFallbackPlans(userType));
    }
  }

  List<SubscriptionPlan> _getFallbackPlans(String userType) {
    final allPlans = PlanRegistry.getPlansForUserType(userType);
    if (allPlans.isNotEmpty) return allPlans;

    // Ultimate fallback — should never be reached
    return [
      SubscriptionPlan(
        id: '${userType}_starter',
        name: 'STARTER',
        price: 'FREE',
        amount: 0,
        features: ['Basic Access'],
        userType: userType,
      ),
    ];
  }

  Future<void> seedPlans() async {
    try {
      final allPlans = PlanRegistry.allPlans;
      for (final plan in allPlans) {
        await _supabase
            .from('subscription_plans')
            .upsert(plan.toMap(), onConflict: 'id');
      }
    } catch (e) {
      debugPrint('[SubscriptionRepository] Plan seeding failed: $e');
    }
  }
}
