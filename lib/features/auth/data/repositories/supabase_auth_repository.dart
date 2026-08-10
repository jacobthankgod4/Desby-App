import 'package:supabase_flutter/supabase_flutter.dart' as sb;
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

class SupabaseAuthRepository implements AuthRepository {
  final AuthLocalDatasource localDatasource;
  final sb.SupabaseClient _supabase = sb.Supabase.instance.client;

  SupabaseAuthRepository({required this.localDatasource});

  AuthFailure _toAuthFailure(FailureType failure) {
    return failure is AuthFailure
        ? failure
        : AuthFailure(message: failure.message);
  }

  @override
  Future<Result<AuthResponse>> login(String email, String password) async {
    try {
      debugPrint('[AUTH] Attempting Supabase login for $email');
      
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      ).timeout(const Duration(seconds: 20));

      final sbUser = response.user;
      if (sbUser == null) {
        return const Failure(AuthFailure(message: 'Login failed: User is null'));
      }

      Map<String, dynamic> userData;
      try {
        userData = await _supabase
            .from('users')
            .select()
            .eq('id', sbUser.id)
            .single();
      } catch (e) {
        debugPrint('[AUTH] Profile missing (PGRST116 fallback). Creating default profile for ${sbUser.id}');
        // Fallback: Create profile if missing but Auth succeeded
        userData = {
          'id': sbUser.id,
          'email': sbUser.email ?? email,
          'name': sbUser.userMetadata?['name'] ?? email.split('@').first,
          'user_type': 'tailor', // Default fallback
          'created_at': DateTime.now().toIso8601String(),
        };
        
        try {
          await _supabase.from('users').upsert(userData);
        } catch (dbError) {
          debugPrint('[AUTH] ⚠️ RLS/Policy Block during self-healing: $dbError');
          debugPrint('[AUTH] Proceeding with Local-Only state to allow app entry.');
        }
      }

      final user = UserModel.fromJson(userData).toEntity();

      // Persist locally
      final storage = (localDatasource as AuthLocalDatasourceImpl).storage;
      await storage.save(StorageKeys.currentUser, userData);
      await localDatasource.saveTokens(
        sbUser.id,
        response.session?.refreshToken ?? 'supabase_session',
      );

      return Success(
        AuthResponse(
          user: user,
          accessToken: response.session?.accessToken ?? sbUser.id,
          refreshToken: response.session?.refreshToken ?? 'supabase_session',
          expiresIn: response.session?.expiresIn ?? 3600,
        ),
      );
    } catch (e) {
      debugPrint('[AUTH] Supabase login() error: $e');
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
      debugPrint('[AUTH] Attempting Supabase registration for $email');
      
      // 1. Auth Signup
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'user_type': userType},
      ).timeout(const Duration(seconds: 25));

      final sbUser = response.user;
      if (sbUser == null) {
        return const Failure(AuthFailure(message: 'Registration failed: User is null'));
      }

      // 2. Prepare Profile Record
      final user = User(
        id: sbUser.id,
        email: email,
        name: name,
        userType: userType,
        createdAt: DateTime.now(),
      );

      final userData = UserModel.fromEntity(user).toJson();
      
      // 3. Persist Profile to PostgreSQL
      try {
        await _supabase.from('users').upsert(userData);
      } catch (e) {
        debugPrint('[AUTH] ⚠️ RLS/Policy Block during self-healing: $e');
        debugPrint('[AUTH] Proceeding with Local-Only state to allow app entry.');
        // We continue because Auth was successful, we just couldn't sync the profile to DB
      }

      // 4. Handle confirmation requirement
      if (response.session == null) {
        return const Failure(VerificationRequiredFailure(message: 'Please check your email to confirm your account.'));
      }

      // Persist locally
      final storage = (localDatasource as AuthLocalDatasourceImpl).storage;
      await storage.save(StorageKeys.currentUser, userData);
      await localDatasource.saveTokens(
        sbUser.id,
        response.session?.refreshToken ?? 'supabase_session',
      );

      return Success(
        AuthResponse(
          user: user,
          accessToken: response.session?.accessToken ?? sbUser.id,
          refreshToken: response.session?.refreshToken ?? 'supabase_session',
          expiresIn: response.session?.expiresIn ?? 3600,
        )
      );
    } catch (e) {
      debugPrint('[AUTH] Supabase register() error: $e');
      final failure = ErrorHandler.mapExceptionToFailure(e);
      return Failure(_toAuthFailure(failure));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _supabase.auth.signOut();
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
    try {
      final response = await _supabase.auth.refreshSession(refreshToken);
      final sbUser = response.user;
      
      if (sbUser == null) {
        return const Failure(AuthFailure(message: 'Token refresh failed'));
      }

      final userDataResponse = await _supabase
          .from('users')
          .select()
          .eq('id', sbUser.id)
          .single();

      final user = UserModel.fromJson(userDataResponse).toEntity();

      return Success(
        AuthResponse(
          user: user,
          accessToken: response.session?.accessToken ?? sbUser.id,
          refreshToken: response.session?.refreshToken ?? '',
          expiresIn: response.session?.expiresIn ?? 3600,
        ),
      );
    } catch (e) {
      final failure = ErrorHandler.mapExceptionToFailure(e);
      return Failure(_toAuthFailure(failure));
    }
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
}
