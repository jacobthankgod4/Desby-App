import '../../domain/entities/user.dart';

/// Simplified UserModel for Supabase storage - avoids freezed code generation issues
class UserModel {
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
  final Map<String, dynamic>? servicePricing;
  final String? pricingTier;

  UserModel({
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'user_type': userType,
    'created_at': createdAt.toIso8601String(),
    'phone': phone,
    'profile_image': profileImage,
    'bio': bio,
    'is_verified': isVerified,
    'service_pricing': servicePricing,
    'pricing_tier': pricingTier,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      userType: (json['user_type'] ?? json['userType']) as String? ?? '',
      createdAt: (json['created_at'] ?? json['createdAt']) is String
              ? DateTime.parse((json['created_at'] ?? json['createdAt']) as String)
              : DateTime.now(),
      phone: json['phone'] as String?,
      profileImage: (json['profile_image'] ?? json['profileImage']) as String?,
      bio: json['bio'] as String?,
      isVerified: (json['is_verified'] ?? json['isVerified']) as bool? ?? false,
      servicePricing: (json['service_pricing'] ?? json['servicePricing']) as Map<String, dynamic>?,
      pricingTier: (json['pricing_tier'] ?? json['pricingTier']) as String?,
    );
  }

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      name: user.name,
      userType: user.userType,
      createdAt: user.createdAt,
      phone: user.phone,
      profileImage: user.profileImage,
      bio: user.bio,
      isVerified: user.isVerified,
      servicePricing: user.servicePricing?.toMap(),
      pricingTier: user.pricingTier,
    );
  }

  User toEntity() {
    return User(
      id: id,
      email: email,
      name: name,
      userType: userType,
      createdAt: createdAt,
      phone: phone,
      profileImage: profileImage,
      bio: bio,
      isVerified: isVerified,
      servicePricing: servicePricing != null
          ? ServicePricing.fromMap(servicePricing!)
          : null,
      pricingTier: pricingTier,
    );
  }
}
