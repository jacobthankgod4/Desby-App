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
      'mondayOpen': mondayOpen,
      'mondayClose': mondayClose,
      'tuesdayOpen': tuesdayOpen,
      'tuesdayClose': tuesdayClose,
      'wednesdayOpen': wednesdayOpen,
      'wednesdayClose': wednesdayClose,
      'thursdayOpen': thursdayOpen,
      'thursdayClose': thursdayClose,
      'fridayOpen': fridayOpen,
      'fridayClose': fridayClose,
      'saturdayOpen': saturdayOpen,
      'saturdayClose': saturdayClose,
      'sundayOpen': sundayOpen,
      'sundayClose': sundayClose,
    };
  }

  /// Create from JSON map
  factory BusinessHours.fromJson(Map<String, dynamic> json) {
    return BusinessHours(
      mondayOpen: json['mondayOpen'] as String?,
      mondayClose: json['mondayClose'] as String?,
      tuesdayOpen: json['tuesdayOpen'] as String?,
      tuesdayClose: json['tuesdayClose'] as String?,
      wednesdayOpen: json['wednesdayOpen'] as String?,
      wednesdayClose: json['wednesdayClose'] as String?,
      thursdayOpen: json['thursdayOpen'] as String?,
      thursdayClose: json['thursdayClose'] as String?,
      fridayOpen: json['fridayOpen'] as String?,
      fridayClose: json['fridayClose'] as String?,
      saturdayOpen: json['saturdayOpen'] as String?,
      saturdayClose: json['saturdayClose'] as String?,
      sundayOpen: json['sundayOpen'] as String?,
      sundayClose: json['sundayClose'] as String?,
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
    );
  }

/// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'profileImage': profileImage,
      'userType': userType,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isActive': isActive,
      'metadata': metadata,
      'bio': bio,
      'address': address,
      'state': state,
      'country': country,
      'lga': lga,
      'businessName': businessName,
      'businessAddress': businessAddress,
      'businessPhone': businessPhone,
      'businessState': businessState,
      'latitude': latitude,
      'longitude': longitude,
      'isVerified': isVerified,
      'services': services,
      'availableFabrics': availableFabrics,
      'workingHours': workingHours,
      'workingHoursByDay': workingHoursByDay?.toJson(),
      'bodyType': bodyType,
      'measurementUnit': measurementUnit,
      'personalMeasurements': personalMeasurements,
      'preferredOccasions': preferredOccasions,
      'preferredFabrics': preferredFabrics,
      'loyaltyPoints': loyaltyPoints,
      'baseStitchingPrice': baseStitchingPrice,
      'materialCost': materialCost,
      'startingPrice': startingPrice,
      'hasPricing': hasPricing,
      'subscriptionPlanId': subscriptionPlanId,
      'subscriptionExpiry': subscriptionExpiry?.toIso8601String(),
    };
  }

/// Create from JSON map
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      profileImage: json['profileImage'] as String?,
      userType: json['userType'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String) 
          : null,
      isActive: json['isActive'] as bool? ?? true,
      metadata: json['metadata'] as Map<String, dynamic>?,
      bio: json['bio'] as String?,
      address: json['address'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      lga: json['lga'] as String?,
      businessName: json['businessName'] as String?,
      businessAddress: json['businessAddress'] as String?,
      businessPhone: json['businessPhone'] as String?,
      businessState: json['businessState'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isVerified: json['isVerified'] as bool? ?? false,
      services: (json['services'] as List?)?.cast<String>(),
      availableFabrics: (json['availableFabrics'] as List?)?.cast<String>(),
      workingHours: json['workingHours'] as String?,
      workingHoursByDay: json['workingHoursByDay'] != null 
          ? BusinessHours.fromJson(json['workingHoursByDay'] as Map<String, dynamic>) 
          : null,
      bodyType: json['bodyType'] as String?,
      measurementUnit: json['measurementUnit'] as String?,
      personalMeasurements: json['personalMeasurements'] as Map<String, dynamic>?,
      preferredOccasions: (json['preferredOccasions'] as List?)?.cast<String>(),
      preferredFabrics: (json['preferredFabrics'] as List?)?.cast<String>(),
      loyaltyPoints: json['loyaltyPoints'] as int? ?? 0,
      baseStitchingPrice: (json['baseStitchingPrice'] as num?)?.toDouble(),
      materialCost: (json['materialCost'] as num?)?.toDouble(),
      startingPrice: (json['startingPrice'] as num?)?.toDouble(),
      hasPricing: json['hasPricing'] as bool? ?? false,
      subscriptionPlanId: json['subscriptionPlanId'] as String?,
      subscriptionExpiry: json['subscriptionExpiry'] != null 
          ? DateTime.parse(json['subscriptionExpiry'] as String) 
          : null,
    );
  }

  /// Check if user is a client
  bool get isClient => userType == 'client';

  /// Check if user is a tailor
  bool get isTailor => userType == 'tailor';

  /// Check if user is an apprentice
  bool get isApprentice => userType == 'apprentice';

  /// Check if user is a fabric seller
  bool get isFabricSeller => userType == 'fabric_seller';

@override
  List<Object?> get props => [
    id,
    email,
    name,
    phone,
    profileImage,
    userType,
    createdAt,
    updatedAt,
    isActive,
    metadata,
    bio,
    address,
    state,
    country,
    lga,
    businessName,
    businessAddress,
    businessPhone,
    businessState,
    latitude,
    longitude,
    isVerified,
    services,
    availableFabrics,
    workingHours,
    workingHoursByDay,
    bodyType,
    measurementUnit,
    personalMeasurements,
    preferredOccasions,
    preferredFabrics,
    loyaltyPoints,
    baseStitchingPrice,
    materialCost,
    startingPrice,
    hasPricing,
    subscriptionPlanId,
    subscriptionExpiry,
  ];

  @override
  bool get stringify => true;
}

/// Extended user profile with additional details
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
      'totalJobs': totalJobs,
      'completedJobs': completedJobs,
    };
  }

factory UserProfileDetails.fromJson(Map<String, dynamic> json) {
    return UserProfileDetails(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      profileImage: json['profileImage'] as String?,
      userType: json['userType'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String) 
          : null,
      isActive: json['isActive'] as bool? ?? true,
      metadata: json['metadata'] as Map<String, dynamic>?,
      bio: json['bio'] as String?,
      address: json['address'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      lga: json['lga'] as String?,
      businessName: json['businessName'] as String?,
      businessAddress: json['businessAddress'] as String?,
      businessPhone: json['businessPhone'] as String?,
      businessState: json['businessState'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isVerified: json['isVerified'] as bool? ?? false,
      services: (json['services'] as List?)?.cast<String>(),
      availableFabrics: (json['availableFabrics'] as List?)?.cast<String>(),
      workingHours: json['workingHours'] as String?,
      workingHoursByDay: json['workingHoursByDay'] != null 
          ? BusinessHours.fromJson(json['workingHoursByDay'] as Map<String, dynamic>) 
          : null,
      bodyType: json['bodyType'] as String?,
      measurementUnit: json['measurementUnit'] as String?,
      personalMeasurements: json['personalMeasurements'] as Map<String, dynamic>?,
      preferredOccasions: (json['preferredOccasions'] as List?)?.cast<String>(),
      preferredFabrics: (json['preferredFabrics'] as List?)?.cast<String>(),
      loyaltyPoints: json['loyaltyPoints'] as int? ?? 0,
      baseStitchingPrice: (json['baseStitchingPrice'] as num?)?.toDouble(),
      materialCost: (json['materialCost'] as num?)?.toDouble(),
      startingPrice: (json['startingPrice'] as num?)?.toDouble(),
      hasPricing: json['hasPricing'] as bool? ?? false,
      subscriptionPlanId: json['subscriptionPlanId'] as String?,
      subscriptionExpiry: json['subscriptionExpiry'] != null 
          ? DateTime.parse(json['subscriptionExpiry'] as String) 
          : null,
      rating: (json['rating'] as num?)?.toDouble(),
      totalJobs: json['totalJobs'] as int?,
      completedJobs: json['completedJobs'] as int?,
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
