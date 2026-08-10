import 'package:equatable/equatable.dart';

/// Business hours for each day of the week
class BusinessHours extends Equatable {
  final String? mondayOpen;
  final String? mondayClose;
  final String? tuesdayOpen;
  final String? tuesdayClose;
  final String? wednesdayOpen;
  final String? wednesdayClose;
  final String? thursdayOpen;
  final String? thursdayClose;
  final String? fridayOpen;
  final String? fridayClose;
  final String? saturdayOpen;
  final String? saturdayClose;
  final String? sundayOpen;
  final String? sundayClose;

  const BusinessHours({
    this.mondayOpen,
    this.mondayClose,
    this.tuesdayOpen,
    this.tuesdayClose,
    this.wednesdayOpen,
    this.wednesdayClose,
    this.thursdayOpen,
    this.thursdayClose,
    this.fridayOpen,
    this.fridayClose,
    this.saturdayOpen,
    this.saturdayClose,
    this.sundayOpen,
    this.sundayClose,
  });

  /// Check if is open on a given day
  bool get isMondayOpen => mondayOpen != null && mondayOpen!.isNotEmpty;
  bool get isTuesdayOpen => tuesdayOpen != null && tuesdayOpen!.isNotEmpty;
  bool get isWednesdayOpen => wednesdayOpen != null && wednesdayOpen!.isNotEmpty;
  bool get isThursdayOpen => thursdayOpen != null && thursdayOpen!.isNotEmpty;
  bool get isFridayOpen => fridayOpen != null && fridayOpen!.isNotEmpty;
  bool get isSaturdayOpen => saturdayOpen != null && saturdayOpen!.isNotEmpty;
  bool get isSundayOpen => sundayOpen != null && sundayOpen!.isNotEmpty;

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'monday_open': mondayOpen,
      'monday_close': mondayClose,
      'tuesday_open': tuesdayOpen,
      'tuesday_close': tuesdayClose,
      'wednesday_open': wednesdayOpen,
      'wednesday_close': wednesdayClose,
      'thursday_open': thursdayOpen,
      'thursday_close': thursdayClose,
      'friday_open': fridayOpen,
      'friday_close': fridayClose,
      'saturday_open': saturdayOpen,
      'saturday_close': saturdayClose,
      'sunday_open': sundayOpen,
      'sunday_close': sundayClose,
    };
  }

  /// Create from JSON map
  factory BusinessHours.fromJson(Map<String, dynamic> json) {
    return BusinessHours(
      mondayOpen: (json['monday_open'] ?? json['mondayOpen']) as String?,
      mondayClose: (json['monday_close'] ?? json['mondayClose']) as String?,
      tuesdayOpen: (json['tuesday_open'] ?? json['tuesdayOpen']) as String?,
      tuesdayClose: (json['tuesday_close'] ?? json['tuesdayClose']) as String?,
      wednesdayOpen: (json['wednesday_open'] ?? json['wednesdayOpen']) as String?,
      wednesdayClose: (json['wednesday_close'] ?? json['wednesdayClose']) as String?,
      thursdayOpen: (json['thursday_open'] ?? json['thursdayOpen']) as String?,
      thursdayClose: (json['thursday_close'] ?? json['thursdayClose']) as String?,
      fridayOpen: (json['friday_open'] ?? json['fridayOpen']) as String?,
      fridayClose: (json['friday_close'] ?? json['fridayClose']) as String?,
      saturdayOpen: (json['saturday_open'] ?? json['saturdayOpen']) as String?,
      saturdayClose: (json['saturday_close'] ?? json['saturdayClose']) as String?,
      sundayOpen: (json['sunday_open'] ?? json['sundayOpen']) as String?,
      sundayClose: (json['sunday_close'] ?? json['sundayClose']) as String?,
    );
  }

  @override
  List<Object?> get props => [
    mondayOpen,
    mondayClose,
    tuesdayOpen,
    tuesdayClose,
    wednesdayOpen,
    wednesdayClose,
    thursdayOpen,
    thursdayClose,
    fridayOpen,
    fridayClose,
    saturdayOpen,
    saturdayClose,
    sundayOpen,
    sundayClose,
  ];
}

/// User profile entity representing the core user data structure
class UserProfile extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? profileImage;
  final String userType; // 'client', 'tailor', 'apprentice', 'fabric_seller'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  // Additional profile fields
  final String? bio;
  final String? address;
  final String? state;
  final String? country;
  final String? lga;

  // Business fields for tailors/fabric sellers
  final String? businessName;
  final String? businessAddress;
  final String? businessPhone;
  final String? businessState; // Business location state (separate from personal state)
  final double? latitude;
  final double? longitude;
  final bool isVerified;

  // Tailor-specific fields
  final List<String>? services;
  final List<String>? availableFabrics;
  final String? workingHours;
  final BusinessHours? workingHoursByDay;
  final String? bodyType;

  // Client-specific fields
  final String? measurementUnit;
  final Map<String, dynamic>? personalMeasurements;
  final List<String>? preferredOccasions;
  final List<String>? preferredFabrics;
  final int loyaltyPoints;

  // Pricing fields for tailors
  final double? baseStitchingPrice;
  final double? materialCost;
  final double? startingPrice;
  final bool hasPricing;

  // Subscription fields
  final String? subscriptionPlanId;
  final DateTime? subscriptionExpiry;

  // discovery UI fields
  final String? preferredFinderStyle; // 'uber' or 'classic'
  final int? distanceMinutes;

  // Measurement status fields
  final bool isMeasurementsVerified;
  final String? verifiedByTailorId;
  final String? fitPreference; // e.g. 'slim', 'standard', 'traditional'

  const UserProfile({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.profileImage,
    required this.userType,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.metadata,
    this.bio,
    this.address,
    this.state,
    this.country,
    this.lga,
    this.businessName,
    this.businessAddress,
    this.businessPhone,
    this.businessState,
    this.latitude,
    this.longitude,
    this.isVerified = false,
    this.services,
    this.availableFabrics,
    this.workingHours,
    this.workingHoursByDay,
    this.bodyType,
    this.measurementUnit,
    this.personalMeasurements,
    this.preferredOccasions,
    this.preferredFabrics,
    this.loyaltyPoints = 0,
    this.baseStitchingPrice,
    this.materialCost,
    this.startingPrice,
    this.hasPricing = false,
    this.subscriptionPlanId,
    this.subscriptionExpiry,
    this.preferredFinderStyle,
    this.distanceMinutes,
    this.isMeasurementsVerified = false,
    this.verifiedByTailorId,
    this.fitPreference,
  });

  /// Create a copy with updated fields
  UserProfile copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? profileImage,
    String? userType,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    Map<String, dynamic>? metadata,
    String? bio,
    String? address,
    String? state,
    String? country,
    String? lga,
    String? businessName,
    String? businessAddress,
    String? businessPhone,
    String? businessState,
    double? latitude,
    double? longitude,
    bool? isVerified,
    List<String>? services,
    List<String>? availableFabrics,
    String? workingHours,
    BusinessHours? workingHoursByDay,
    String? bodyType,
    String? measurementUnit,
    Map<String, dynamic>? personalMeasurements,
    List<String>? preferredOccasions,
    List<String>? preferredFabrics,
    int? loyaltyPoints,
    double? baseStitchingPrice,
    double? materialCost,
    double? startingPrice,
    bool? hasPricing,
    String? subscriptionPlanId,
    DateTime? subscriptionExpiry,
    String? preferredFinderStyle,
    int? distanceMinutes,
    bool? isMeasurementsVerified,
    String? verifiedByTailorId,
    String? fitPreference,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      userType: userType ?? this.userType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
      bio: bio ?? this.bio,
      address: address ?? this.address,
      state: state ?? this.state,
      country: country ?? this.country,
      lga: lga ?? this.lga,
      businessName: businessName ?? this.businessName,
      businessAddress: businessAddress ?? this.businessAddress,
      businessPhone: businessPhone ?? this.businessPhone,
      businessState: businessState ?? this.businessState,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isVerified: isVerified ?? this.isVerified,
      services: services ?? this.services,
      availableFabrics: availableFabrics ?? this.availableFabrics,
      workingHours: workingHours ?? this.workingHours,
      workingHoursByDay: workingHoursByDay ?? this.workingHoursByDay,
      bodyType: bodyType ?? this.bodyType,
      measurementUnit: measurementUnit ?? this.measurementUnit,
      personalMeasurements: personalMeasurements ?? this.personalMeasurements,
      preferredOccasions: preferredOccasions ?? this.preferredOccasions,
      preferredFabrics: preferredFabrics ?? this.preferredFabrics,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      baseStitchingPrice: baseStitchingPrice ?? this.baseStitchingPrice,
      materialCost: materialCost ?? this.materialCost,
      startingPrice: startingPrice ?? this.startingPrice,
      hasPricing: hasPricing ?? this.hasPricing,
      subscriptionPlanId: subscriptionPlanId ?? this.subscriptionPlanId,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
      preferredFinderStyle: preferredFinderStyle ?? this.preferredFinderStyle,
      distanceMinutes: distanceMinutes ?? this.distanceMinutes,
      isMeasurementsVerified: isMeasurementsVerified ?? this.isMeasurementsVerified,
      verifiedByTailorId: verifiedByTailorId ?? this.verifiedByTailorId,
      fitPreference: fitPreference ?? this.fitPreference,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'profile_image': profileImage,
      'user_type': userType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_active': isActive,
      'metadata': metadata,
      'bio': bio,
      'address': address,
      'state': state,
      'country': country,
      'lga': lga,
      'business_name': businessName,
      'business_address': businessAddress,
      'business_phone': businessPhone,
      'business_state': businessState,
      'latitude': latitude,
      'longitude': longitude,
      'is_verified': isVerified,
      'services': services,
      'available_fabrics': availableFabrics,
      'working_hours': workingHours,
      'working_hours_by_day': workingHoursByDay?.toJson(),
      'body_type': bodyType,
      'measurement_unit': measurementUnit,
      'personal_measurements': personalMeasurements,
      'preferred_occasions': preferredOccasions,
      'preferred_fabrics': preferredFabrics,
      'loyalty_points': loyaltyPoints,
      'base_stitching_price': baseStitchingPrice,
      'material_cost': materialCost,
      'starting_price': startingPrice,
      'has_pricing': hasPricing,
      'subscription_plan_id': subscriptionPlanId,
      'subscription_expiry': subscriptionExpiry?.toIso8601String(),
      'preferred_finder_style': preferredFinderStyle,
      'distance_minutes': distanceMinutes,
      'is_measurements_verified': isMeasurementsVerified,
      'verified_by_tailor_id': verifiedByTailorId,
      'fit_preference': fitPreference,
    };
  }

  /// Create from JSON map
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String?,
      profileImage: (json['profile_image'] ?? json['profileImage']) as String?,
      userType: (json['user_type'] ?? json['userType'] ?? 'tailor') as String,
      createdAt: DateTime.parse((json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()) as String),
      updatedAt: (json['updated_at'] ?? json['updatedAt']) != null 
          ? DateTime.parse((json['updated_at'] ?? json['updatedAt']) as String) 
          : null,
      isActive: (json['is_active'] ?? json['isActive']) as bool? ?? true,
      metadata: json['metadata'] as Map<String, dynamic>?,
      bio: json['bio'] as String?,
      address: json['address'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      lga: json['lga'] as String?,
      businessName: (json['business_name'] ?? json['businessName']) as String?,
      businessAddress: (json['business_address'] ?? json['businessAddress']) as String?,
      businessPhone: (json['business_phone'] ?? json['businessPhone']) as String?,
      businessState: (json['business_state'] ?? json['businessState']) as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isVerified: (json['is_verified'] ?? json['isVerified']) as bool? ?? false,
      services: (json['services'] as List?)?.cast<String>(),
      availableFabrics: (json['available_fabrics'] ?? json['availableFabrics'] as List?)?.cast<String>(),
      workingHours: (json['working_hours'] ?? json['workingHours']) as String?,
      workingHoursByDay: (json['working_hours_by_day'] ?? json['workingHoursByDay']) != null 
          ? BusinessHours.fromJson((json['working_hours_by_day'] ?? json['workingHoursByDay']) as Map<String, dynamic>) 
          : null,
      bodyType: (json['body_type'] ?? json['bodyType']) as String?,
      measurementUnit: (json['measurement_unit'] ?? json['measurementUnit']) as String?,
      personalMeasurements: (json['personal_measurements'] ?? json['personalMeasurements']) as Map<String, dynamic>?,
      preferredOccasions: (json['preferred_occasions'] ?? json['preferredOccasions'] as List?)?.cast<String>(),
      preferredFabrics: (json['preferred_fabrics'] ?? json['preferredFabrics'] as List?)?.cast<String>(),
      loyaltyPoints: (json['loyalty_points'] ?? json['loyaltyPoints']) as int? ?? 0,
      baseStitchingPrice: (json['base_stitching_price'] ?? json['baseStitchingPrice'] as num?)?.toDouble(),
      materialCost: (json['material_cost'] ?? json['materialCost'] as num?)?.toDouble(),
      startingPrice: (json['starting_price'] ?? json['startingPrice'] as num?)?.toDouble(),
      hasPricing: (json['has_pricing'] ?? json['hasPricing']) as bool? ?? false,
      subscriptionPlanId: (json['subscription_plan_id'] ?? json['subscriptionPlanId']) as String?,
      subscriptionExpiry: (json['subscription_expiry'] ?? json['subscriptionExpiry']) != null 
          ? DateTime.parse((json['subscription_expiry'] ?? json['subscriptionExpiry']) as String) 
          : null,
      preferredFinderStyle: (json['preferred_finder_style'] ?? json['preferredFinderStyle']) as String?,
      distanceMinutes: (json['distance_minutes'] ?? json['distanceMinutes']) as int?,
      isMeasurementsVerified: (json['is_measurements_verified'] ?? json['isMeasurementsVerified']) as bool? ?? false,
      verifiedByTailorId: (json['verified_by_tailor_id'] ?? json['verifiedByTailorId']) as String?,
      fitPreference: (json['fit_preference'] ?? json['fitPreference']) as String?,
    );
  }

  @override
  List<Object?> get props => [
    id, email, name, phone, profileImage, userType, createdAt, updatedAt, 
    isActive, metadata, bio, address, state, country, lga,
    businessName, businessAddress, businessPhone, businessState,
    latitude, longitude, isVerified, services, availableFabrics,
    workingHours, workingHoursByDay, bodyType,
    measurementUnit, personalMeasurements, preferredOccasions, 
    preferredFabrics, loyaltyPoints, baseStitchingPrice, materialCost,
    startingPrice, hasPricing, subscriptionPlanId, subscriptionExpiry,
    preferredFinderStyle, distanceMinutes,
    isMeasurementsVerified, verifiedByTailorId, fitPreference,
  ];
}

/// Detailed profile entity with additional statistics
class UserProfileDetails extends UserProfile {
  final double? rating;
  final int? totalJobs;
  final int? completedJobs;

  const UserProfileDetails({
    required super.id,
    required super.email,
    required super.name,
    super.phone,
    super.profileImage,
    required super.userType,
    required super.createdAt,
    super.updatedAt,
    super.isActive,
    super.metadata,
    super.bio,
    super.address,
    super.state,
    super.country,
    super.lga,
    super.businessName,
    super.businessAddress,
    super.businessPhone,
    super.businessState,
    super.latitude,
    super.longitude,
    super.isVerified,
    super.services,
    super.availableFabrics,
    super.workingHours,
    super.workingHoursByDay,
    super.bodyType,
    super.measurementUnit,
    super.personalMeasurements,
    super.preferredOccasions,
    super.preferredFabrics,
    super.loyaltyPoints,
    super.baseStitchingPrice,
    super.materialCost,
    super.startingPrice,
    super.hasPricing,
    super.subscriptionPlanId,
    super.subscriptionExpiry,
    super.preferredFinderStyle,
    super.distanceMinutes,
    super.isMeasurementsVerified,
    super.verifiedByTailorId,
    super.fitPreference,
    this.rating,
    this.totalJobs,
    this.completedJobs,
  });

  @override
  UserProfileDetails copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? profileImage,
    String? userType,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    Map<String, dynamic>? metadata,
    String? bio,
    String? address,
    String? state,
    String? country,
    String? lga,
    String? businessName,
    String? businessAddress,
    String? businessPhone,
    String? businessState,
    double? latitude,
    double? longitude,
    bool? isVerified,
    List<String>? services,
    List<String>? availableFabrics,
    String? workingHours,
    BusinessHours? workingHoursByDay,
    String? bodyType,
    String? measurementUnit,
    Map<String, dynamic>? personalMeasurements,
    List<String>? preferredOccasions,
    List<String>? preferredFabrics,
    int? loyaltyPoints,
    double? baseStitchingPrice,
    double? materialCost,
    double? startingPrice,
    bool? hasPricing,
    String? subscriptionPlanId,
    DateTime? subscriptionExpiry,
    String? preferredFinderStyle,
    int? distanceMinutes,
    bool? isMeasurementsVerified,
    String? verifiedByTailorId,
    String? fitPreference,
    double? rating,
    int? totalJobs,
    int? completedJobs,
  }) {
    return UserProfileDetails(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      userType: userType ?? this.userType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
      bio: bio ?? this.bio,
      address: address ?? this.address,
      state: state ?? this.state,
      country: country ?? this.country,
      lga: lga ?? this.lga,
      businessName: businessName ?? this.businessName,
      businessAddress: businessAddress ?? this.businessAddress,
      businessPhone: businessPhone ?? this.businessPhone,
      businessState: businessState ?? this.businessState,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isVerified: isVerified ?? this.isVerified,
      services: services ?? this.services,
      availableFabrics: availableFabrics ?? this.availableFabrics,
      workingHours: workingHours ?? this.workingHours,
      workingHoursByDay: workingHoursByDay ?? this.workingHoursByDay,
      bodyType: bodyType ?? this.bodyType,
      measurementUnit: measurementUnit ?? this.measurementUnit,
      personalMeasurements: personalMeasurements ?? this.personalMeasurements,
      preferredOccasions: preferredOccasions ?? this.preferredOccasions,
      preferredFabrics: preferredFabrics ?? this.preferredFabrics,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      baseStitchingPrice: baseStitchingPrice ?? this.baseStitchingPrice,
      materialCost: materialCost ?? this.materialCost,
      startingPrice: startingPrice ?? this.startingPrice,
      hasPricing: hasPricing ?? this.hasPricing,
      subscriptionPlanId: subscriptionPlanId ?? this.subscriptionPlanId,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
      preferredFinderStyle: preferredFinderStyle ?? this.preferredFinderStyle,
      distanceMinutes: distanceMinutes ?? this.distanceMinutes,
      isMeasurementsVerified: isMeasurementsVerified ?? this.isMeasurementsVerified,
      verifiedByTailorId: verifiedByTailorId ?? this.verifiedByTailorId,
      fitPreference: fitPreference ?? this.fitPreference,
      rating: rating ?? this.rating,
      totalJobs: totalJobs ?? this.totalJobs,
      completedJobs: completedJobs ?? this.completedJobs,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'rating': rating,
      'total_jobs': totalJobs,
      'completed_jobs': completedJobs,
    };
  }

  factory UserProfileDetails.fromJson(Map<String, dynamic> json) {
    final base = UserProfile.fromJson(json);
    return UserProfileDetails(
      id: base.id,
      email: base.email,
      name: base.name,
      phone: base.phone,
      profileImage: base.profileImage,
      userType: base.userType,
      createdAt: base.createdAt,
      updatedAt: base.updatedAt,
      isActive: base.isActive,
      metadata: base.metadata,
      bio: base.bio,
      address: base.address,
      state: base.state,
      country: base.country,
      lga: base.lga,
      businessName: base.businessName,
      businessAddress: base.businessAddress,
      businessPhone: base.businessPhone,
      businessState: base.businessState,
      latitude: base.latitude,
      longitude: base.longitude,
      isVerified: base.isVerified,
      services: base.services,
      availableFabrics: base.availableFabrics,
      workingHours: base.workingHours,
      workingHoursByDay: base.workingHoursByDay,
      bodyType: base.bodyType,
      measurementUnit: base.measurementUnit,
      personalMeasurements: base.personalMeasurements,
      preferredOccasions: base.preferredOccasions,
      preferredFabrics: base.preferredFabrics,
      loyaltyPoints: base.loyaltyPoints,
      baseStitchingPrice: base.baseStitchingPrice,
      materialCost: base.materialCost,
      startingPrice: base.startingPrice,
      hasPricing: base.hasPricing,
      subscriptionPlanId: base.subscriptionPlanId,
      subscriptionExpiry: base.subscriptionExpiry,
      preferredFinderStyle: base.preferredFinderStyle,
      distanceMinutes: base.distanceMinutes,
      isMeasurementsVerified: base.isMeasurementsVerified,
      verifiedByTailorId: base.verifiedByTailorId,
      fitPreference: base.fitPreference,
      rating: (json['rating'] as num?)?.toDouble(),
      totalJobs: (json['total_jobs'] ?? json['totalJobs']) as int?,
      completedJobs: (json['completed_jobs'] ?? json['completedJobs']) as int?,
    );
  }

  @override
  List<Object?> get props => [
    ...super.props,
    rating,
    totalJobs,
    completedJobs,
  ];
}
