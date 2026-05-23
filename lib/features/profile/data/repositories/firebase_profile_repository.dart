import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/entities/user_profile.dart';

class FirebaseProfileRepository implements ProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<Result<UserProfile>> getProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        // Create a default profile for new users if document doesn't exist
        final defaultProfile = UserProfile(
          id: userId,
          email: '',
          name: 'New User',
          userType: 'tailor',
          createdAt: DateTime.now(),
        );
        // Try to create the document
        await _firestore.collection('users').doc(userId).set({
          'name': 'New User',
          'email': '',
          'userType': 'tailor',
          'createdAt': FieldValue.serverTimestamp(),
        });
        return Success(defaultProfile);
      }
      final data = doc.data()!;
      return Success(_mapToEntity(doc.id, data));
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<UserProfile>>> searchMasters(String query) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'tailor')
          .get();
      
      final results = snapshot.docs
          .map((doc) => _mapToEntity(doc.id, doc.data()))
          .where((u) => u.name.toLowerCase().contains(query.toLowerCase()) || (u.businessName?.toLowerCase().contains(query.toLowerCase()) ?? false))
          .toList();
      
      return Success(results);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<UserProfile>> updateProfile(UserProfile profile) async {
    try {
      final data = _entityToMap(profile);
      // Use server timestamp for updatedAt
      data['updatedAt'] = FieldValue.serverTimestamp();
      
      await _firestore.collection('users').doc(profile.id).update(data);
      return Success(profile);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> uploadProfileImage(String userId, String filePath) async {
    // TODO: Implement Firebase Storage upload
    // This would upload to Firebase Storage and update the user's profileImage field
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteProfile(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
      return const Success(null);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  /// Map Firestore document to UserProfile entity with all fields
  UserProfile _mapToEntity(String id, Map<String, dynamic> data) {
    return UserProfile(
      id: id,
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
      userType: data['userType'] as String? ?? 'tailor',
      createdAt: _parseTimestamp(data['createdAt']),
      phone: data['phone'] as String?,
      profileImage: data['profileImage'] as String?,
      bio: data['bio'] as String?,
      address: data['address'] as String?,
      state: data['state'] as String?,
      businessName: data['businessName'] as String?,
      businessAddress: data['businessAddress'] as String?,
      businessPhone: data['businessPhone'] as String?,
      isVerified: data['isVerified'] as bool? ?? false,
      // Additional fields from Firestore
      services: _parseStringList(data['services']),
      availableFabrics: _parseStringList(data['availableFabrics']),
      workingHours: data['workingHours'] as String?,
      businessState: data['businessState'] as String?,
      country: data['country'] as String?,
      lga: data['lga'] as String?,
      longitude: (data['longitude'] as num?)?.toDouble(),
      updatedAt: _parseTimestamp(data['updatedAt']),
      subscriptionPlanId: data['subscriptionPlanId'] as String?,
      subscriptionExpiry: _parseTimestamp(data['subscriptionExpiry']),
      preferredOccasions: _parseStringList(data['preferredOccasions']),
      preferredFabrics: _parseStringList(data['preferredFabrics']),
      bodyType: data['bodyType'] as String?,
      measurementUnit: data['measurementUnit'] as String?,
      loyaltyPoints: data['loyaltyPoints'] as int? ?? 0,
      personalMeasurements: _parseStringMap(data['personalMeasurements']),
    );
  }

  /// Parse a map of strings from Firestore data
  Map<String, String>? _parseStringMap(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v.toString()));
    }
    return null;
  }

  /// Convert UserProfile entity to Firestore map for updating
  Map<String, dynamic> _entityToMap(UserProfile profile) {
    final map = <String, dynamic>{
      'name': profile.name,
      'email': profile.email,
      'userType': profile.userType,
      'phone': profile.phone,
      'profileImage': profile.profileImage,
      'bio': profile.bio,
      'address': profile.address,
      'state': profile.state,
      'businessName': profile.businessName,
      'businessAddress': profile.businessAddress,
      'businessPhone': profile.businessPhone,
      'isVerified': profile.isVerified,
      'services': profile.services,
      'availableFabrics': profile.availableFabrics,
      'workingHours': profile.workingHours,
      'businessState': profile.businessState,
      'country': profile.country,
      'lga': profile.lga,
      'latitude': profile.latitude,
      'longitude': profile.longitude,
      'subscriptionPlanId': profile.subscriptionPlanId,
      'subscriptionExpiry': profile.subscriptionExpiry != null ? Timestamp.fromDate(profile.subscriptionExpiry!) : null,
      'preferredOccasions': profile.preferredOccasions,
      'preferredFabrics': profile.preferredFabrics,
      'bodyType': profile.bodyType,
      'measurementUnit': profile.measurementUnit,
      'loyaltyPoints': profile.loyaltyPoints,
      'personalMeasurements': profile.personalMeasurements,
    };
    // Remove null values
    map.removeWhere((key, value) => value == null);
    return map;
  }

  /// Parse timestamp from various formats: Firestore Timestamp, ISO8601 String, or DateTime
  DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    } else if (value is DateTime) {
      return value;
    }
    return DateTime.now();
  }

  /// Parse a list of strings from Firestore data (handles List<dynamic> or List<String>)
  List<String>? _parseStringList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return null;
  }
}
