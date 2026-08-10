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
        // Fallback for demo if DB is empty
        return Success(_getFallbackPlans(userType));
      }

      return Success(plans);
    } catch (e) {
      return Failure(UnknownFailure(message: 'Failed to fetch plans: $e'));
    }
  }

  List<SubscriptionPlan> _getFallbackPlans(String userType) {
     final List<SubscriptionPlan> allPlans = [
      // --- TAILOR PLANS ---
      const SubscriptionPlan(
        id: 'tailor_basic', name: 'ARTISAN', price: 'FREE', amount: 0,
        features: [
          'Professional Shop Profile',
          'Digital Booking Manager',
          'Up to 10 Client Profiles',
          'Standard Delivery Support',
          'Basic Business Analytics',
          'Manual Measurement Entry',
          'Gallery Portfolio (5 Items)',
          'Direct Client Messaging',
        ],
        userType: 'tailor',
      ),
      const SubscriptionPlan(
        id: 'tailor_pro', name: 'PRO MASTER', price: '₦15,000/mo', amount: 15000,
        features: [
          'EVERYTHING IN ARTISAN PLUS:',
          'Unlimited Client Profiles',
          'Verified AMBER Badge',
          'Priority Search Discovery',
          'Advanced Revenue Forecasting',
          'Custom Digital Receipts',
          'Apprentice Management (2 Seats)',
          'Automated Delivery Summoning',
          'Inventory Management System',
        ],
        userType: 'tailor',
      ),
      const SubscriptionPlan(
        id: 'tailor_elite', name: 'ELITE ATELIER', price: '₦45,000/mo', amount: 45000,
        isElite: true, features: [
          'EVERYTHING IN PRO MASTER PLUS:',
          '3D BODY SCANNING INTELLIGENCE',
          'Auto-Measurement Capture (Zero Error)',
          'AI-Powered Design Assistant',
          'Global Fabric Sourcing Leads',
          'Premium White-Label Landing Page',
          'Exclusive "Master Class" Access',
          '24/7 Dedicated Concierge Support',
          'Unlimited Staff & Team Seats',
        ],
        userType: 'tailor', buttonLabel: 'GO ELITE',
      ),
      // Add more as needed...
    ];
    return allPlans.where((p) => p.userType == userType.toLowerCase()).toList();
  }

  Future<void> seedPlans() async {
     // Implementation similar to Firebase if needed
  }
}
