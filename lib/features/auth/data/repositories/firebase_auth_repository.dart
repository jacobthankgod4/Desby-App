import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/constants/user_types.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../domain/entities/auth_response.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../models/user_model.dart';

class FirebaseAuthRepository implements AuthRepository {
  final AuthLocalDatasource localDatasource;

  fb.FirebaseAuth get _auth => fb.FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  FirebaseAuthRepository({required this.localDatasource});

  AuthFailure _toAuthFailure(FailureType failure) {
    return failure is AuthFailure
        ? failure
        : AuthFailure(message: failure.message);
  }

  /// Normalizes Firestore Timestamp fields to DateTime for Hive compatibility.
  /// Firestore returns Timestamp objects for fields like createdAt/updatedAt,
  /// but Hive cannot serialize Timestamp without a custom adapter.
  Map<String, dynamic> _normalizeTimestamps(Map<String, dynamic> data) {
    final normalized = <String, dynamic>{};
    
    for (final entry in data.entries) {
      final value = entry.value;
      if (value is Timestamp) {
        // Convert Firestore Timestamp to DateTime for Hive storage
        normalized[entry.key] = value.toDate();
      } else if (value is Map<String, dynamic>) {
        // Recursively normalize nested maps
        normalized[entry.key] = _normalizeTimestamps(value);
      } else if (value is List) {
        // Handle lists that might contain Timestamps
        normalized[entry.key] = value.map((item) {
          if (item is Timestamp) {
            return item.toDate();
          } else if (item is Map<String, dynamic>) {
            return _normalizeTimestamps(item);
          }
          return item;
        }).toList();
      } else {
        normalized[entry.key] = value;
      }
    }
    
    return normalized;
  }

  @override
  Future<Result<AuthResponse>> login(String email, String password) async {
    try {
      debugPrint('[AUTH] Attempting login for $email');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('[AUTH] Firebase Auth success: ${credential.user!.uid}');

      final userDoc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      if (!userDoc.exists) {
        debugPrint(
          '[AUTH] ERROR: User profile document missing in Firestore for uid=${credential.user!.uid}',
        );
        return const Failure(
          AuthFailure(
            message:
                'User profile not found in database. Ensure you created users/{uid} and Firestore rules allow read.',
          ),
        );
      }

      final userData = userDoc.data();
      if (userData == null) {
        debugPrint(
          '[AUTH] ERROR: User document exists but has null data for uid=${credential.user!.uid}',
        );
        return const Failure(
          AuthFailure(
            message:
                'User profile data is missing. Please re-register or contact support.',
          ),
        );
      }

      // Helpful schema validation: log keys for debugging
      debugPrint('[AUTH] User doc keys: ${userData.keys.toList()}');

      final user = UserModel.fromJson(userData).toEntity();

      // Persist locally - normalize timestamps first for Hive compatibility
      final normalizedData = _normalizeTimestamps(userData);
      final storage = (localDatasource as AuthLocalDatasourceImpl).storage;
      await storage.save(StorageKeys.currentUser, normalizedData);
      await localDatasource.saveTokens(
        credential.user!.uid,
        'firebase_session',
      );

      return Success(
        AuthResponse(
          user: user,
          accessToken: credential.user!.uid,
          refreshToken: 'firebase_session',
          expiresIn: 3600,
        ),
      );
    } catch (e) {
      debugPrint('[AUTH] login() catch: ${e.runtimeType}: ${e.toString()}');
      debugPrint(
        '[AUTH] login() catch safe: ${ErrorHandler.safeExceptionString(e)}',
      );

      final failure = ErrorHandler.mapExceptionToFailure(e);
      return Failure(_toAuthFailure(failure));
    }
  }

  @override
  Future<Result<AuthResponse>> register(
    String email,
    String password,
    String name,
    String userType,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = User(
        id: credential.user!.uid,
        email: email,
        name: name,
        userType: userType,
        createdAt: DateTime.now(),
      );

      final userModel = UserModel.fromEntity(user);
      final userData = userModel.toJson();

      await _firestore.collection('users').doc(user.id).set(userData);

      // Persist locally - normalize timestamps first for Hive compatibility
      final normalizedData = _normalizeTimestamps(userData);
      final storage = (localDatasource as AuthLocalDatasourceImpl).storage;
      await storage.save(StorageKeys.currentUser, normalizedData);
      await localDatasource.saveTokens(
        credential.user!.uid,
        'firebase_session',
      );

      return Success(
        AuthResponse(
          user: user,
          accessToken: credential.user!.uid,
          refreshToken: 'firebase_session',
          expiresIn: 3600,
        )
      );
    } catch (e) {
      // Surface the exact Firebase Auth error during web debugging
      // (FirebaseException.code/message are usually the key to diagnosing
      // a 400 on signUp).
      // ignore: avoid_print
      print('[FirebaseAuthRepository.register] exception: $e');
      if (e is fb.FirebaseAuthException) {
        // ignore: avoid_print
        print(
          '[FirebaseAuthRepository.register] firebaseAuthException code=${e.code} message=${e.message}',
        );
      }

      final failure = ErrorHandler.mapExceptionToFailure(e);
      return Failure(_toAuthFailure(failure));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _auth.signOut();
      await localDatasource.clearTokens();

      final storage = (localDatasource as AuthLocalDatasourceImpl).storage;
      await storage.delete(StorageKeys.currentUser);

      return const Success(null);
    } catch (e) {
      final failure = ErrorHandler.mapExceptionToFailure(e);
      return Failure(_toAuthFailure(failure));
    }
  }

  @override
  Future<Result<AuthResponse>> refreshToken(String refreshToken) async {
    // Firebase handles token refresh internally
    return const Failure(
      AuthFailure(message: 'Internal Firebase Refresh'),
    );
  }

  @override
  Future<Result<void>> saveTokens(
    String accessToken,
    String refreshToken,
  ) async {
    await localDatasource.saveTokens(accessToken, refreshToken);
    return const Success(null);
  }

  @override
  Future<Result<String?>> getAccessToken() async {
    final token = localDatasource.getAccessToken();
    return Success(token);
  }

@override
  Future<Result<String?>> getRefreshToken() async {
    final token = localDatasource.getRefreshToken();
    return Success(token);
  }

  @override
  Future<Result<void>> clearTokens() async {
    await localDatasource.clearTokens();
    return const Success(null);
  }

/// Get tailors from Firestore for tailor discovery
  Future<List<Map<String, dynamic>>> getTailors() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: UserType.tailor.value)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        
        // Extract pricing data for display
        final pricing = data['servicePricing'] as Map<String, dynamic>?;
        if (pricing != null) {
          data['startingPrice'] = _calculateStartingPrice(pricing);
          data['hasPricing'] = (data['startingPrice'] as double? ?? 0) > 0;
        } else {
          data['startingPrice'] = 0.0;
          data['hasPricing'] = false;
        }
        
        return data;
      }).toList();
    } catch (e) {
      debugPrint('[FirebaseAuthRepository.getTailors] error: $e');
      return [];
    }
  }

  /// Get a single tailor by ID with full pricing data
  Future<Map<String, dynamic>?> getTailorById(String tailorId) async {
    try {
      final doc = await _firestore.collection('users').doc(tailorId).get();
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      data['id'] = doc.id;
      
      // Extract pricing data
      final pricing = data['servicePricing'] as Map<String, dynamic>?;
      if (pricing != null) {
        data['startingPrice'] = _calculateStartingPrice(pricing);
        data['hasPricing'] = (data['startingPrice'] as double? ?? 0) > 0;
      } else {
        data['startingPrice'] = 0.0;
        data['hasPricing'] = false;
      }
      
      return data;
    } catch (e) {
      debugPrint('[FirebaseAuthRepository.getTailorById] error: $e');
      return null;
    }
  }

  /// Calculate the starting price from pricing map
  double _calculateStartingPrice(Map<String, dynamic> pricing) {
    final stitchingPrice = (pricing['stitchingPrice'] as num?)?.toDouble() ?? 0.0;
    final alterationPrice = (pricing['alterationPrice'] as num?)?.toDouble() ?? 0.0;
    final customPrice = (pricing['customPrice'] as num?)?.toDouble() ?? 0.0;
    
    final prices = [stitchingPrice, alterationPrice, customPrice]
        .where((p) => p > 0)
        .toList();
    
    if (prices.isEmpty) return 0.0;
    return prices.reduce((a, b) => a < b ? a : b);
  }

  /// Update tailor pricing in Firestore
  Future<bool> updateTailorPricing(String tailorId, Map<String, dynamic> pricing) async {
    try {
      await _firestore.collection('users').doc(tailorId).update({
        'servicePricing': pricing,
        'pricingTier': pricing['pricingTier'] ?? 'standard',
      });
      return true;
    } catch (e) {
      debugPrint('[FirebaseAuthRepository.updateTailorPricing] error: $e');
      return false;
    }
  }
}
