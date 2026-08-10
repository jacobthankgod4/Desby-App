import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/user_profile.dart';

part 'user_profile_model.freezed.dart';
part 'user_profile_model.g.dart';

@freezed
class UserProfileModel with _$UserProfileModel {
  const factory UserProfileModel({
    required String id,
    required String email,
    required String name,
    required String userType,
    String? phone,
    String? profileImage,
    String? bio,
    String? businessName,
    String? businessAddress,
    String? businessPhone,
    @Default(false) bool isVerified,
    // Tailor pricing fields
    double? baseStitchingPrice,
    double? materialCost,
    double? startingPrice,
    @Default(false) bool hasPricing,
    String? preferredFinderStyle,
    int? distanceMinutes,
    @Default(false) bool isMeasurementsVerified,
    String? verifiedByTailorId,
    String? fitPreference,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _UserProfileModel;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) =>
      _$UserProfileModelFromJson(json);
}

extension UserProfileModelX on UserProfileModel {
  UserProfile toEntity() => UserProfile(
    id: id,
    email: email,
    name: name,
    userType: userType,
    phone: phone,
    profileImage: profileImage,
    bio: bio,
    businessName: businessName,
    businessAddress: businessAddress,
    businessPhone: businessPhone,
    isVerified: isVerified,
    baseStitchingPrice: baseStitchingPrice,
    materialCost: materialCost,
    startingPrice: startingPrice,
    hasPricing: hasPricing,
    preferredFinderStyle: preferredFinderStyle,
    distanceMinutes: distanceMinutes,
    isMeasurementsVerified: isMeasurementsVerified,
    verifiedByTailorId: verifiedByTailorId,
    fitPreference: fitPreference,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
