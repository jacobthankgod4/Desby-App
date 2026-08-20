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
  final String userType;

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

class PlanRegistry {
  static List<SubscriptionPlan> getPlansForUserType(String userType) {
    return _allPlans.where((plan) => plan.userType == userType.toLowerCase()).toList();
  }

  static final List<SubscriptionPlan> _allPlans = [
    // ── TAILOR PLANS ──
    const SubscriptionPlan(
      id: 'tailor_starter',
      name: 'STARTER',
      price: 'FREE',
      amount: 0,
      features: [
        'Shop Profile',
        'Up to 10 Clients',
        'Basic Booking Manager',
        'Manual Measurements',
        'Gallery Portfolio (5 Items)',
        'Basic Dashboard Stats',
        'Direct Client Messaging',
        'Order Tracking',
      ],
      userType: 'tailor',
    ),
    const SubscriptionPlan(
      id: 'tailor_premium',
      name: 'PREMIUM',
      price: '₦2,500/mo',
      amount: 2500,
      isElite: true,
      buttonLabel: 'GO PREMIUM',
      features: [
        'EVERYTHING IN STARTER PLUS:',
        'Unlimited Client Profiles',
        'Priority in Search & Discovery',
        'Verified Premium Badge',
        'Advanced Analytics & Insights',
        'AI Business Forecasting',
        'Revenue Reports & PDF Export',
        'Custom Digital Receipts',
        'Apprentice Management (2 Seats)',
        'Inventory Management System',
        'Unlimited Gallery Items',
        'Custom Dispatch & Logistics',
        'Priority Support',
      ],
      userType: 'tailor',
    ),

    // ── CLIENT PLANS ──
    const SubscriptionPlan(
      id: 'client_starter',
      name: 'STARTER',
      price: 'FREE',
      amount: 0,
      features: [
        'Browse Tailors',
        'Book Appointments',
        'Order Tracking',
        'Direct Messaging',
        'Manual Measurement Entry',
        '1 Active Order',
      ],
      userType: 'client',
    ),
    const SubscriptionPlan(
      id: 'client_premium',
      name: 'PREMIUM',
      price: '₦2,500/mo',
      amount: 2500,
      isElite: true,
      buttonLabel: 'GO PREMIUM',
      features: [
        'EVERYTHING IN STARTER PLUS:',
        'AI Body Scanning',
        'Virtual Try-On',
        'Digital Closet',
        'Advanced Measurement Profiles',
        'Multiple Active Orders',
        'Priority Booking & Support',
        'Design Gallery Access',
        'Order History & Reorder',
      ],
      userType: 'client',
    ),

    // ── APPRENTICE PLANS ──
    const SubscriptionPlan(
      id: 'apprentice_starter',
      name: 'STARTER',
      price: 'FREE',
      amount: 0,
      features: [
        'Connect with 1 Mentor',
        'Basic Learning Modules',
        'Track Progress',
        'Submit Tasks',
        'Mentor Directory Access',
      ],
      userType: 'apprentice',
    ),
    const SubscriptionPlan(
      id: 'apprentice_premium',
      name: 'PREMIUM',
      price: '₦2,500/mo',
      amount: 2500,
      isElite: true,
      buttonLabel: 'GO PREMIUM',
      features: [
        'EVERYTHING IN STARTER PLUS:',
        'Multiple Mentors',
        'Advanced Training Modules',
        'AI Pattern Assistance',
        'Secure Video Lessons',
        'Certificate of Completion',
        'Priority Task Review',
        'Portfolio Showcase',
      ],
      userType: 'apprentice',
    ),

    // ── FABRIC SELLER PLANS ──
    const SubscriptionPlan(
      id: 'seller_starter',
      name: 'STARTER',
      price: 'FREE',
      amount: 0,
      features: [
        'Shop Listing',
        'Up to 15 Fabric Items',
        'Basic Inventory Sync',
        'Browse Marketplace',
        'Direct Buyer Messaging',
      ],
      userType: 'fabric_seller',
    ),
    const SubscriptionPlan(
      id: 'seller_premium',
      name: 'PREMIUM',
      price: '₦2,500/mo',
      amount: 2500,
      isElite: true,
      buttonLabel: 'VERIFY & UPGRADE',
      features: [
        'EVERYTHING IN STARTER PLUS:',
        'Verified Seller Badge',
        'Unlimited Fabric Listings',
        'Buyer Lead Generation',
        'Featured Shop Placement',
        'Wholesale Pricing Tiers',
        'Advanced Sales Analytics',
        'Priority Support',
        'Merchant Wallet & Payouts',
      ],
      userType: 'fabric_seller',
    ),
  ];
}
