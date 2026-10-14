import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';

class SubscriptionPlan {
  final String id;
  final String name;
  final String price;
  final int amount;
  final List<String> features;
  final String? premiumHeader;
  final List<String>? premiumFeatures;
  final Color accentColor;
  final String buttonLabel;
  final String userType;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.amount,
    required this.features,
    this.premiumHeader,
    this.premiumFeatures,
    this.accentColor = AppColors.amber,
    this.buttonLabel = 'GET STARTED',
    required this.userType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'amount': amount,
      'features': features,
      'premium_header': premiumHeader,
      'premium_features': premiumFeatures,
      'accent_color': accentColor.toARGB32(),
      'button_label': buttonLabel,
      'user_type': userType,
    };
  }

  factory SubscriptionPlan.fromMap(Map<String, dynamic> map) {
    return SubscriptionPlan(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      price: map['price'] ?? '',
      amount: (map['amount'] as num? ?? 0).toInt(),
      features: List<String>.from(map['features'] ?? []),
      premiumHeader: map['premium_header'],
      premiumFeatures: map['premium_features'] != null
          ? List<String>.from(map['premium_features'])
          : null,
      accentColor: Color(map['accent_color'] ?? AppColors.amber.toARGB32()),
      buttonLabel: map['button_label'] ?? 'GET STARTED',
      userType: map['user_type'] ?? 'tailor',
    );
  }

  int get tierLevel {
    if (id.endsWith('_starter') || name.toLowerCase() == 'free') return 0;
    if (id.endsWith('_pro')) return 1;
    debugPrint(
      '⚠️ [PLAN_REGISTRY] Unrecognized plan ID: $id, defaulting to free tier',
    );
    return 0;
  }
}

class PlanRegistry {
  static List<SubscriptionPlan> getPlansForUserType(String userType) {
    return _allPlans
        .where((plan) => plan.userType == userType.toLowerCase())
        .toList();
  }

  static SubscriptionPlan? getPlanById(String planId) {
    try {
      return _allPlans.firstWhere((p) => p.id == planId);
    } catch (_) {
      return null;
    }
  }

  static List<SubscriptionPlan> get allPlans => List.unmodifiable(_allPlans);

  static const int freeTier = 0;
  static const int proTier = 1;

  static final List<SubscriptionPlan> _allPlans = [
    // ═══════════════════════════════════════
    // TAILOR PLANS
    // ═══════════════════════════════════════
    const SubscriptionPlan(
      id: 'tailor_starter',
      name: 'Free',
      price: 'FREE',
      amount: 0,
      features: [
        'Unlimited active orders',
        'Find tailors by location and rating',
        'View profiles, designs, and pricing',
        'Chat directly with tailors',
        'Place orders and track progress',
        'Smart pricing for every garment',
        'Manage deliveries and dispatch',
        '5 free AI body scans and virtual try-ons',
        'Save unlimited favourite designs',
        'Get order status notifications',
        'Ask Zoe AI for outfit advice',
        'Refer tailors and earn cash rewards',
      ],
      userType: 'tailor',
    ),
    const SubscriptionPlan(
      id: 'tailor_pro',
      name: 'Premium',
      price: '\u20A61,000/mo',
      amount: 1000,
      buttonLabel: 'UPGRADE TO PREMIUM',
      premiumHeader: 'Everything in Free, plus:',
      premiumFeatures: [
        'Verified tailor badge',
        'Unlimited AI body scans and try-ons',
        'Unlimited AI virtual try-ons for clients',
        'Save client measurements for repeat orders',
        'Daily, weekly, and monthly revenue insights',
        'Unlimited design portfolio',
        'Manage apprentices and training programs',
        'Create a branded tailor storefront',
        'Build your reputation with client reviews',
        'Advanced business management tools',
      ],
      features: [],
      userType: 'tailor',
    ),

    // ═══════════════════════════════════════
    // CLIENT PLANS
    // ═══════════════════════════════════════
    const SubscriptionPlan(
      id: 'client_starter',
      name: 'Free',
      price: 'FREE',
      amount: 0,
      features: [
        'Find tailors by location and rating',
        'View tailor profiles and galleries',
        'Chat directly with any tailor',
        'Place orders and track stitching progress',
        'Smart pricing estimates before ordering',
        'Manage deliveries from one place',
        '5 free AI body scans and virtual try-ons',
        'Save unlimited favourite designs',
        'Get order status notifications',
        'Ask Zoe AI for style advice',
        'Refer friends and earn rewards',
      ],
      userType: 'client',
    ),
    const SubscriptionPlan(
      id: 'client_pro',
      name: 'Premium',
      price: '\u20A61,000/mo',
      amount: 1000,
      buttonLabel: 'UPGRADE TO PREMIUM',
      premiumHeader: 'Everything in Free, plus:',
      premiumFeatures: [
        'Unlimited AI body scans and try-ons',
        '3D body viewer for your measurements',
        'Unlimited saved outfits in digital closet',
        'Multiple measurement profiles',
        'Style preferences for better fits',
        'Full order history with receipts',
        'Priority booking with Pro tailors',
        'Access to exclusive Pro-only designs',
        'Refer friends and earn discount credits',
      ],
      features: [],
      userType: 'client',
    ),

    // ═══════════════════════════════════════
    // APPRENTICE PLANS
    // ═══════════════════════════════════════
    const SubscriptionPlan(
      id: 'apprentice_starter',
      name: 'Free',
      price: 'FREE',
      amount: 0,
      features: [
        'Get matched with a mentor tailor',
        'Access 5 beginner sewing lessons',
        'Track your learning progress',
        'Submit work for mentor review',
        'Ask Zoe AI for learning help',
      ],
      userType: 'apprentice',
    ),
    const SubscriptionPlan(
      id: 'apprentice_pro',
      name: 'Premium',
      price: '\u20A61,000/mo',
      amount: 1000,
      buttonLabel: 'UPGRADE TO PREMIUM',
      premiumHeader: 'Everything in Free, plus:',
      premiumFeatures: [
        'Unlock all HD video lessons',
        'Full curriculum with step-by-step milestones',
        'Submit work with photos and notes',
        'Direct messaging with your mentor',
        'Masterclass courses from top tailors',
        'Earn skill badges at each milestone',
        'Download certificates for completed courses',
        'Growth dashboard showing your progress',
        'Switch to a different mentor anytime',
        'Refer friends and earn rewards',
      ],
      features: [],
      userType: 'apprentice',
    ),

    // ═══════════════════════════════════════
    // FABRIC SELLER PLANS
    // ═══════════════════════════════════════
    const SubscriptionPlan(
      id: 'seller_starter',
      name: 'Free',
      price: 'FREE',
      amount: 0,
      features: [
        'Set up your fabric shop online',
        'List up to 15 fabrics with photos',
        'Keep stock levels accurate',
        'Browse what tailors are looking for',
        'Chat directly with buyers',
        'Receive order requests from tailors',
        'Ask Zoe AI for selling tips',
      ],
      userType: 'fabric_seller',
    ),
    const SubscriptionPlan(
      id: 'seller_pro',
      name: 'Premium',
      price: '\u20A61,000/mo',
      amount: 1000,
      buttonLabel: 'UPGRADE TO PREMIUM',
      premiumHeader: 'Everything in Free, plus:',
      premiumFeatures: [
        'Verified seller badge',
        'Unlimited fabric listings',
        'Bulk and small order pricing',
        'Colour variants with individual stock',
        'Accept payments via Paystack',
        'Save favourite fabrics from marketplace',
        'Low-stock alerts before you run out',
        'Branded storefront with your logo',
        'AI pricing tool for your fabrics',
        'Refer sellers and earn cash rewards',
      ],
      features: [],
      userType: 'fabric_seller',
    ),
  ];
}
