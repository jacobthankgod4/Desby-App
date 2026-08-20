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
    // Seed plans to Supabase if table is empty
    try {
      final response = await _supabase.from('subscription_plans').select().limit(1);
      if ((response as List).isNotEmpty) return;

      final allPlans = [
        // Tailor
        const SubscriptionPlan(id: 'tailor_starter', name: 'STARTER', price: 'FREE', amount: 0,
          features: ['Shop Profile','Up to 10 Clients','Basic Booking Manager','Manual Measurements','Gallery Portfolio (5 Items)','Basic Dashboard Stats','Direct Client Messaging','Order Tracking'],
          userType: 'tailor'),
        const SubscriptionPlan(id: 'tailor_premium', name: 'PREMIUM', price: '₦2,500/mo', amount: 2500, isElite: true, buttonLabel: 'GO PREMIUM',
          features: ['EVERYTHING IN STARTER PLUS:','Unlimited Client Profiles','Priority in Search & Discovery','Verified Premium Badge','Advanced Analytics & Insights','AI Business Forecasting','Revenue Reports & PDF Export','Custom Digital Receipts','Apprentice Management (2 Seats)','Inventory Management System','Unlimited Gallery Items','Custom Dispatch & Logistics','Priority Support'],
          userType: 'tailor'),
        // Client
        const SubscriptionPlan(id: 'client_starter', name: 'STARTER', price: 'FREE', amount: 0,
          features: ['Browse Tailors','Book Appointments','Order Tracking','Direct Messaging','Manual Measurement Entry','1 Active Order'],
          userType: 'client'),
        const SubscriptionPlan(id: 'client_premium', name: 'PREMIUM', price: '₦2,500/mo', amount: 2500, isElite: true, buttonLabel: 'GO PREMIUM',
          features: ['EVERYTHING IN STARTER PLUS:','AI Body Scanning','Virtual Try-On','Digital Closet','Advanced Measurement Profiles','Multiple Active Orders','Priority Booking & Support','Design Gallery Access','Order History & Reorder'],
          userType: 'client'),
        // Apprentice
        const SubscriptionPlan(id: 'apprentice_starter', name: 'STARTER', price: 'FREE', amount: 0,
          features: ['Connect with 1 Mentor','Basic Learning Modules','Track Progress','Submit Tasks','Mentor Directory Access'],
          userType: 'apprentice'),
        const SubscriptionPlan(id: 'apprentice_premium', name: 'PREMIUM', price: '₦2,500/mo', amount: 2500, isElite: true, buttonLabel: 'GO PREMIUM',
          features: ['EVERYTHING IN STARTER PLUS:','Multiple Mentors','Advanced Training Modules','AI Pattern Assistance','Secure Video Lessons','Certificate of Completion','Priority Task Review','Portfolio Showcase'],
          userType: 'apprentice'),
        // Fabric Seller
        const SubscriptionPlan(id: 'seller_starter', name: 'STARTER', price: 'FREE', amount: 0,
          features: ['Shop Listing','Up to 15 Fabric Items','Basic Inventory Sync','Browse Marketplace','Direct Buyer Messaging'],
          userType: 'fabric_seller'),
        const SubscriptionPlan(id: 'seller_premium', name: 'PREMIUM', price: '₦2,500/mo', amount: 2500, isElite: true, buttonLabel: 'VERIFY & UPGRADE',
          features: ['EVERYTHING IN STARTER PLUS:','Verified Seller Badge','Unlimited Fabric Listings','Buyer Lead Generation','Featured Shop Placement','Wholesale Pricing Tiers','Advanced Sales Analytics','Priority Support','Merchant Wallet & Payouts'],
          userType: 'fabric_seller'),
      ];

      for (final plan in allPlans) {
        await _supabase.from('subscription_plans').upsert(plan.toMap());
      }
    } catch (_) {
      // Silently fail — fallback plans will be used
    }
  }
}
