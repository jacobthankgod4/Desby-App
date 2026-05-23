import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/error/failures.dart';
import '../../domain/models/plan_registry.dart';
import '../../domain/repositories/subscription_repository.dart';

class FirebaseSubscriptionRepository implements SubscriptionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<Result<List<SubscriptionPlan>>> getPlans(String userType) async {
    try {
      final snapshot = await _firestore
          .collection('subscription_plans')
          .where('userType', isEqualTo: userType.toLowerCase())
          .orderBy('amount', descending: false)
          .get();

      final plans = snapshot.docs
          .map((doc) => SubscriptionPlan.fromMap(doc.data()))
          .toList();

      return Success(plans);
    } catch (e) {
      return Failure(UnknownFailure(message: 'Failed to fetch plans: $e'));
    }
  }

  /// Initializer method to seed the database with premium, "mouth-watering" professional plans
  Future<void> seedPlans() async {
    final List<SubscriptionPlan> initialPlans = [
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

      // --- APPRENTICE PLANS ---
      const SubscriptionPlan(
        id: 'apprentice_standard', name: 'ASPIRANT', price: 'FREE', amount: 0,
        features: [
          'Link with 1 Professional Master',
          'Digital Skill Progress Tracker',
          'Basic Pattern Learning Modules',
          'Standard Portfolio Showcase',
          'Community Access',
          'Basic Profile Badge',
          'Job Board Viewing',
          'Resource Library (Limited)',
        ],
        userType: 'apprentice',
      ),
      const SubscriptionPlan(
        id: 'apprentice_premium', name: 'PREMIUM TALENT', price: '₦25,000/mo', amount: 25000,
        isElite: true, features: [
          'EVERYTHING IN ASPIRANT PLUS:',
          'AI-Assisted Pattern Drafting',
          'Connect with Multiple Masters',
          'Priority Internship Placement',
          'Professional Certification Dossier',
          'Advanced Construction Techniques',
          'Exclusive Industry Networking',
          'Early Access to Marketplace Leads',
        ],
        userType: 'apprentice', buttonLabel: 'UPGRADE NOW',
      ),

      // --- SELLER PLANS ---
      const SubscriptionPlan(
        id: 'seller_basic', name: 'STANDARD SUPPLIER', price: 'FREE', amount: 0,
        features: [
          'Live Marketplace Listing',
          'Up to 15 Active Fabric Items',
          'Basic Inventory Sync',
          'Direct Tailor Messaging',
          'Standard Shop Banner',
          'Basic Sales Analytics',
          'Verified Contact Badge',
          'Standard Logistics Support',
        ],
        userType: 'fabric_seller',
      ),
      const SubscriptionPlan(
        id: 'seller_pro', name: 'ELITE DISTRIBUTOR', price: '₦30,000/mo', amount: 30000,
        isElite: true, features: [
          'EVERYTHING IN STANDARD PLUS:',
          'VERIFIED GOLD SUPPLIER BADGE',
          'Unlimited Marketplace Inventory',
          'Direct Procurement RFQ Access',
          'Featured "Top Fabric" Placement',
          'Bulk Order Logistics Manager',
          'Retail vs Wholesale Pricing Engine',
          'Priority Support & Dispute Shield',
        ],
        userType: 'fabric_seller', buttonLabel: 'VERIFY SHOP',
      ),
    ];

    for (final plan in initialPlans) {
      await _firestore.collection('subscription_plans').doc(plan.id).set(plan.toMap());
    }
  }
}
