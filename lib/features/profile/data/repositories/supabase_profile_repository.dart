import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/ai_credit_service.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/entities/user_profile.dart';

class SupabaseProfileRepository implements ProfileRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<Result<UserProfile>> getProfile(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        final sbUser = _supabase.auth.currentUser;
        if (sbUser == null)
          return Failure(AuthFailure(message: 'User session expired'));

        if (sbUser.id != userId) {
          return const Failure(
            AuthFailure(message: 'Profile not found'),
          );
        }

        final userType =
            sbUser.userMetadata?['user_type'] as String? ?? 'tailor';

        final defaultProfile = UserProfile(
          id: userId,
          email: sbUser.email ?? '',
          name: sbUser.userMetadata?['name'] as String? ?? 'New User',
          userType: userType,
          createdAt: DateTime.now(),
        );

        try {
          await _supabase.from('users').upsert({
            'id': userId,
            'name': defaultProfile.name,
            'email': defaultProfile.email,
            'user_type': userType,
            'ai_credits': kFreeAiCredits,
            'created_at': DateTime.now().toIso8601String(),
          }, onConflict: 'id');
        } catch (rlsError) {
          // If RLS fails on insert, we return the default profile without persisting
          // to allow the user to see the UI, but log the warning.
          debugPrint('WARNING: Could not persist profile via RLS: $rlsError');
          return Success(defaultProfile);
        }

        return Success(defaultProfile);
      }
      return Success(_mapToEntity(userId, response));
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<UserProfile>>> searchMasters(String query) async {
    try {
      var sbQuery = _supabase.from('users').select().eq('user_type', 'tailor');
      if (query.isNotEmpty) {
        sbQuery = sbQuery.or(
          'name.ilike.%$query%,business_name.ilike.%$query%',
        );
      }

      final response = await sbQuery;

      final results = (response as List)
          .map((data) => _mapToEntity(data['id'], data))
          .toList();

      // Search ranking boost: Pro tailors rank higher
      results.sort((a, b) {
        final aIsPro =
            a.subscriptionPlanId != null &&
            a.subscriptionPlanId!.endsWith('_pro');
        final bIsPro =
            b.subscriptionPlanId != null &&
            b.subscriptionPlanId!.endsWith('_pro');
        if (aIsPro && !bIsPro) return -1;
        if (!aIsPro && bIsPro) return 1;
        return 0;
      });

      return Success(results);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<UserProfile>> updateProfile(UserProfile profile) async {
    try {
      final data = _entityToMap(profile);
      data['id'] = profile.id; // CRITICAL for upsert
      data['updated_at'] = DateTime.now().toIso8601String();

      await _supabase.from('users').upsert(data, onConflict: 'id');
      return Success(profile);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> uploadProfileImage(
    String userId,
    String filePath,
  ) async {
    // On web, callers should use uploadProfileImageBytes instead
    return const Failure(
      AuthFailure(
        message: 'Use uploadProfileImageBytes for cross-platform support',
      ),
    );
  }

  @override
  Future<Result<void>> uploadProfileImageBytes(
    String userId,
    Uint8List bytes,
  ) async {
    try {
      final fileName = 'profile_$userId.png';

      await _supabase.storage
          .from('avatars')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final imageUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);
      await _supabase
          .from('users')
          .update({'profile_image': imageUrl})
          .eq('id', userId);

      return const Success(null);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteProfile(String userId) async {
    try {
      await _supabase.from('users').delete().eq('id', userId);
      return const Success(null);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  UserProfile _mapToEntity(String id, Map<String, dynamic> data) {
    return UserProfile(
      id: id,
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
      userType: (data['user_type'] ?? data['userType'] ?? 'tailor') as String,
      createdAt: _parseDateTime(data['created_at'] ?? data['createdAt']),
      phone: data['phone'] as String?,
      profileImage: (data['profile_image'] ?? data['profileImage']) as String?,
      bio: data['bio'] as String?,
      address: data['address'] as String?,
      state: data['state'] as String?,
      businessName: (data['business_name'] ?? data['businessName']) as String?,
      businessAddress:
          (data['business_address'] ?? data['businessAddress']) as String?,
      businessPhone:
          (data['business_phone'] ?? data['businessPhone']) as String?,
      isVerified: (data['is_verified'] ?? data['isVerified']) as bool? ?? false,
      services: _parseStringList(data['services']),
      availableFabrics: _parseStringList(
        data['available_fabrics'] ?? data['availableFabrics'],
      ),
      workingHours: (data['working_hours'] ?? data['workingHours']) as String?,
      businessState:
          (data['business_state'] ?? data['businessState']) as String?,
      country: data['country'] as String?,
      lga: data['lga'] as String?,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      updatedAt: _parseDateTime(data['updated_at'] ?? data['updatedAt']),
      subscriptionPlanId:
          (data['subscription_plan_id'] ?? data['subscriptionPlanId'])
              as String?,
      subscriptionExpiry: _parseDateTime(
        data['subscription_expiry'] ?? data['subscriptionExpiry'],
      ),
      preferredOccasions: _parseStringList(
        data['preferred_occasions'] ?? data['preferredOccasions'],
      ),
      preferredFabrics: _parseStringList(
        data['preferred_fabrics'] ?? data['preferredFabrics'],
      ),
      bodyType: (data['body_type'] ?? data['bodyType']) as String?,
      measurementUnit:
          (data['measurement_unit'] ?? data['measurementUnit']) as String?,
      loyaltyPoints:
          (data['loyalty_points'] ?? data['loyaltyPoints']) as int? ?? 0,
      personalMeasurements: _parseStringMap(
        data['personal_measurements'] ?? data['personalMeasurements'],
      ),
      baseStitchingPrice:
          (data['base_stitching_price'] ?? data['baseStitchingPrice'] as num?)
              ?.toDouble(),
      materialCost: (data['material_cost'] ?? data['materialCost'] as num?)
          ?.toDouble(),
      startingPrice: (data['starting_price'] ?? data['startingPrice'] as num?)
          ?.toDouble(),
      hasPricing: (data['has_pricing'] ?? data['hasPricing']) as bool? ?? false,
      preferredFinderStyle:
          (data['preferred_finder_style'] ?? data['preferredFinderStyle'])
              as String?,
      distanceMinutes:
          (data['distance_minutes'] ?? data['distanceMinutes']) as int?,
      bankAccountNumber:
          (data['bank_account_number'] ?? data['bankAccountNumber']) as String?,
      bankCode:
          (data['bank_code'] ?? data['bankCode']) as String?,
      bankName:
          (data['bank_name'] ?? data['bankName']) as String?,
    );
  }

  Map<String, String>? _parseStringMap(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v.toString()));
    }
    return null;
  }

  Map<String, dynamic> _entityToMap(UserProfile profile) {
    final map = <String, dynamic>{
      'name': profile.name,
      'email': profile.email,
      'user_type': profile.userType,
      'is_verified': profile.isVerified,
      'has_pricing': profile.hasPricing,
      'loyalty_points': profile.loyaltyPoints,
      // JSONB fields always included (required by DB schema)
      'services': profile.services ?? [],
      'available_fabrics': profile.availableFabrics ?? [],
      'preferred_occasions': profile.preferredOccasions ?? [],
      'preferred_fabrics': profile.preferredFabrics ?? [],
      'personal_measurements': profile.personalMeasurements ?? {},
    };

    // Only include non-null optional fields to avoid overwriting existing data
    if (profile.phone != null) map['phone'] = profile.phone;
    if (profile.profileImage != null)
      map['profile_image'] = profile.profileImage;
    if (profile.bio != null) map['bio'] = profile.bio;
    if (profile.address != null) map['address'] = profile.address;
    if (profile.state != null) map['state'] = profile.state;
    if (profile.businessName != null)
      map['business_name'] = profile.businessName;
    if (profile.businessAddress != null)
      map['business_address'] = profile.businessAddress;
    if (profile.businessPhone != null)
      map['business_phone'] = profile.businessPhone;
    if (profile.workingHours != null)
      map['working_hours'] = profile.workingHours;
    if (profile.businessState != null)
      map['business_state'] = profile.businessState;
    if (profile.country != null) map['country'] = profile.country;
    if (profile.lga != null) map['lga'] = profile.lga;
    if (profile.latitude != null) map['latitude'] = profile.latitude;
    if (profile.longitude != null) map['longitude'] = profile.longitude;
    if (profile.subscriptionPlanId != null)
      map['subscription_plan_id'] = profile.subscriptionPlanId;
    if (profile.subscriptionExpiry != null)
      map['subscription_expiry'] = profile.subscriptionExpiry!
          .toIso8601String();
    if (profile.bodyType != null) map['body_type'] = profile.bodyType;
    if (profile.measurementUnit != null)
      map['measurement_unit'] = profile.measurementUnit;
    if (profile.baseStitchingPrice != null)
      map['base_stitching_price'] = profile.baseStitchingPrice;
    if (profile.materialCost != null)
      map['material_cost'] = profile.materialCost;
    if (profile.startingPrice != null)
      map['starting_price'] = profile.startingPrice;
    if (profile.preferredFinderStyle != null)
      map['preferred_finder_style'] = profile.preferredFinderStyle;
    if (profile.distanceMinutes != null)
      map['distance_minutes'] = profile.distanceMinutes;
    if (profile.bankAccountNumber != null)
      map['bank_account_number'] = profile.bankAccountNumber;
    if (profile.bankCode != null) map['bank_code'] = profile.bankCode;
    if (profile.bankName != null) map['bank_name'] = profile.bankName;

    return map;
  }

  DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    } else if (value is DateTime) {
      return value;
    }
    return DateTime.now();
  }

  List<String>? _parseStringList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return null;
  }
}
