import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';

class SubscriptionPlan {
  final String id;
  final String name;
  final String price;
  final double amount;
  final List<String> features;
  final bool isElite;
  final Color accentColor;
  final String buttonLabel;
  final String userType; // Added to distinguish plans in Firestore

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.amount,
    required this.features,
    this.isElite = false,
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
      'isElite': isElite,
      'accentColor': accentColor.toARGB32(),
      'buttonLabel': buttonLabel,
      'userType': userType,
    };
  }

  factory SubscriptionPlan.fromMap(Map<String, dynamic> map) {
    return SubscriptionPlan(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      price: map['price'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      features: List<String>.from(map['features'] ?? []),
      isElite: map['is_elite'] ?? map['isElite'] ?? false,
      accentColor: Color(map['accent_color'] ?? map['accentColor'] ?? AppColors.amber.toARGB32()),
      buttonLabel: map['button_label'] ?? map['buttonLabel'] ?? 'GET STARTED',
      userType: map['user_type'] ?? map['userType'] ?? 'tailor',
    );
  }
}

// PlanRegistry acts as a local fallback when Firestore plans aren't available
// The source of truth should be from the Repository, but this provides offline support
class PlanRegistry {
  static List<SubscriptionPlan> getPlansForUserType(String userType) {
    final plans = _allPlans.where((plan) => plan.userType == userType.toLowerCase()).toList();
    return plans;
  }

static final List<SubscriptionPlan> _allPlans = [
    // TAILOR PLANS
    const SubscriptionPlan(
      id: 'tailor_basic',
      name: 'STARTER',
      price: 'FREE',
      amount: 0,
      features: [
        'Shop Profile',
        'Manual Measurements',
        'Up to 10 Clients',
        'Basic Booking'
      ],
      userType: 'tailor',
    ),
    const SubscriptionPlan(
      id: 'tailor_pro',
      name: 'PRO',
      price: '₦15,000/mo',
      amount: 15000,
      features: [
        'Unlimited Clients',
        'Analytics',
        'Priority in Search',
        'Digital Receipts'
      ],
      userType: 'tailor',
    ),
    const SubscriptionPlan(
      id: 'tailor_elite',
      name: 'BUSINESS',
      price: '₦45,000/mo',
      amount: 45000,
      features: [
        '3D Body Scanning',
        'Auto Measurements',
        'AI Design Help',
        'Custom App'
      ],
      isElite: true,
      buttonLabel: 'GO BUSINESS',
      userType: 'tailor',
    ),
    // APPRENTICE PLANS
    const SubscriptionPlan(
      id: 'apprentice_standard',
      name: 'STARTER',
      price: 'FREE',
      amount: 0,
      features: [
        'Connect with 1 Mentor',
        'Basic Learning',
        'Track Progress'
      ],
      userType: 'apprentice',
    ),
    const SubscriptionPlan(
      id: 'apprentice_premium',
      name: 'PREMIUM',
      price: '₦25,000/mo',
      amount: 25000,
      features: [
        'Advanced Training',
        'AI Pattern Help',
        'Multiple Mentors',
        'Certificate'
      ],
      isElite: true,
      buttonLabel: 'UPGRADE NOW',
      userType: 'apprentice',
    ),
    // FABRIC SELLER PLANS
    const SubscriptionPlan(
      id: 'seller_basic',
      name: 'STARTER',
      price: 'FREE',
      amount: 0,
      features: [
        'Shop Listing',
        'Up to 15 Items',
        'Inventory Sync'
      ],
      userType: 'fabric_seller',
    ),
    const SubscriptionPlan(
      id: 'seller_pro',
      name: 'BUSINESS',
      price: '₦30,000/mo',
      amount: 30000,
      features: [
        'Verified Badge',
        'Unlimited Items',
        'Buyer Leads',
        'Featured Shop'
      ],
      isElite: true,
      buttonLabel: 'VERIFY SHOP',
      userType: 'fabric_seller',
    ),
    // CLIENT PLANS (free - no subscription needed)
    const SubscriptionPlan(
      id: 'client_basic',
      name: 'FREE',
      price: 'FREE',
      amount: 0,
      features: [
        'Browse Tailors',
        'Book Appointments',
        'Order Tracking',
        'Messaging'
      ],
      userType: 'client',
    ),
  ];
}
