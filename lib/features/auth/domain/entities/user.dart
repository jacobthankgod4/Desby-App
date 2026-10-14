/// Service pricing tiers for tailors
class ServicePricing {
  final double stitchingPrice;
  final double alterationPrice;
  final double customPrice;
  final double materialCost;
  final double expressFee;
  final String currency;

  const ServicePricing({
    this.stitchingPrice = 0.0,
    this.alterationPrice = 0.0,
    this.customPrice = 0.0,
    this.materialCost = 0.0,
    this.expressFee = 0.0,
    this.currency = 'NGN',
  });

  Map<String, dynamic> toMap() => {
    'stitching_price': stitchingPrice,
    'alteration_price': alterationPrice,
    'custom_price': customPrice,
    'material_cost': materialCost,
    'express_fee': expressFee,
    'currency': currency,
  };

  factory ServicePricing.fromMap(Map<String, dynamic> map) {
    return ServicePricing(
      stitchingPrice: (map['stitching_price'] as num?)?.toDouble() ?? 0.0,
      alterationPrice: (map['alteration_price'] as num?)?.toDouble() ?? 0.0,
      customPrice: (map['custom_price'] as num?)?.toDouble() ?? 0.0,
      materialCost: (map['material_cost'] as num?)?.toDouble() ?? 0.0,
      expressFee: (map['express_fee'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'NGN',
    );
  }

  /// Calculate total price based on selected services
  double calculateTotal({
    bool includeStitching = true,
    bool includeAlteration = false,
    bool includeCustom = false,
    bool includeMaterial = true,
    bool includeExpress = false,
  }) {
    double total = 0.0;
    if (includeStitching) total += stitchingPrice;
    if (includeAlteration) total += alterationPrice;
    if (includeCustom) total += customPrice;
    if (includeMaterial) total += materialCost;
    if (includeExpress) total += expressFee;
    return total;
  }

  /// Get the starting/base price (minimum price)
  double get startingPrice {
    final prices = [
      stitchingPrice,
      alterationPrice,
      customPrice,
    ].where((p) => p > 0).toList();
    if (prices.isEmpty) return 0.0;
    return prices.reduce((a, b) => a < b ? a : b);
  }

  ServicePricing copyWith({
    double? stitchingPrice,
    double? alterationPrice,
    double? customPrice,
    double? materialCost,
    double? expressFee,
    String? currency,
  }) {
    return ServicePricing(
      stitchingPrice: stitchingPrice ?? this.stitchingPrice,
      alterationPrice: alterationPrice ?? this.alterationPrice,
      customPrice: customPrice ?? this.customPrice,
      materialCost: materialCost ?? this.materialCost,
      expressFee: expressFee ?? this.expressFee,
      currency: currency ?? this.currency,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServicePricing &&
          other.stitchingPrice == stitchingPrice &&
          other.alterationPrice == alterationPrice &&
          other.customPrice == customPrice &&
          other.materialCost == materialCost &&
          other.expressFee == expressFee &&
          other.currency == currency;

  @override
  int get hashCode => Object.hash(
    stitchingPrice,
    alterationPrice,
    customPrice,
    materialCost,
    expressFee,
    currency,
  );
}

class User {
  final String id;
  final String email;
  final String name;
  final String userType;
  final DateTime createdAt;
  final String? phone;
  final String? profileImage;
  final String? bio;
  final bool isVerified;
  // Pricing fields for tailors
  final ServicePricing? servicePricing;
  final String? pricingTier; // economy, standard, premium

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.userType,
    required this.createdAt,
    this.phone,
    this.profileImage,
    this.bio,
    this.isVerified = false,
    this.servicePricing,
    this.pricingTier,
  });

  /// Get the starting price for display
  double get startingPrice => servicePricing?.startingPrice ?? 0.0;

  /// Check if pricing is configured
  bool get hasPricing =>
      servicePricing != null && (servicePricing?.startingPrice ?? 0) > 0;

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? userType,
    DateTime? createdAt,
    String? phone,
    String? profileImage,
    String? bio,
    bool? isVerified,
    ServicePricing? servicePricing,
    String? pricingTier,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      userType: userType ?? this.userType,
      createdAt: createdAt ?? this.createdAt,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      bio: bio ?? this.bio,
      isVerified: isVerified ?? this.isVerified,
      servicePricing: servicePricing ?? this.servicePricing,
      pricingTier: pricingTier ?? this.pricingTier,
    );
  }

  /// Value equality so Riverpod can tell a genuinely changed user from the same
  /// user rebuilt by a token refresh. Without this, every `tokenRefreshed` event
  /// re-notified every dependent of [currentUserProvider], which re-issued their
  /// REST queries (orders, notifications) on each refresh.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          other.id == id &&
          other.email == email &&
          other.name == name &&
          other.userType == userType &&
          other.createdAt == createdAt &&
          other.phone == phone &&
          other.profileImage == profileImage &&
          other.bio == bio &&
          other.isVerified == isVerified &&
          other.servicePricing == servicePricing &&
          other.pricingTier == pricingTier;

  @override
  int get hashCode => Object.hash(
    id,
    email,
    name,
    userType,
    createdAt,
    phone,
    profileImage,
    bio,
    isVerified,
    servicePricing,
    pricingTier,
  );
}
