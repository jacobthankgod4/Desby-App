import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:flutter/foundation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../domain/entities/auth_response.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../models/user_model.dart';
import '../../../../core/services/ai_credit_service.dart';

/// The Flutter app is served from `/app/`; the bare origin is the marketing
/// site, which ignores Supabase's `?code=` callback. Every auth redirect must
/// therefore target the app path.
const String kAppBaseUrl = 'https://desby.app/app';

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

      final response = await _supabase.auth
          .signInWithPassword(email: email, password: password)
          .timeout(const Duration(seconds: 20));

      final sbUser = response.user;
      if (sbUser == null) {
        return const Failure(
          AuthFailure(message: 'Login failed: User is null'),
        );
      }

      Map<String, dynamic> userData;
      try {
        userData = await _supabase
            .from('users')
            .select()
            .eq('id', sbUser.id)
            .single();
      } catch (e) {
        debugPrint(
          '[AUTH] Profile missing (PGRST116). User ${sbUser.id} has no profile in users table.',
        );
        // Profile is missing — do NOT silently create one with wrong user_type.
        // Throw an error so the user is informed.
        return const Failure(
          AuthFailure(
            message:
                'Your account profile is missing. Please contact support@desby.app to complete registration.',
          ),
        );
      }

      final user = UserModel.fromJson(userData).toEntity();

      // Persist locally
      final storage = (localDatasource as AuthLocalDatasourceImpl).storage;
      await storage.save(StorageKeys.currentUser, userData);
      await localDatasource.saveTokens(
        response.session?.accessToken ?? '',
        response.session?.refreshToken ?? '',
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
      // A wrong password is a routine user mistake, not an app fault, so it is
      // not logged at error level — only unexpected failures are.
      final errorStr = e.toString();
      final isExpectedAuthRejection = errorStr.contains('invalid_credentials') ||
          errorStr.contains('Invalid login credentials') ||
          errorStr.contains('email_not_confirmed') ||
          errorStr.contains('Email not confirmed');

      if (!isExpectedAuthRejection) {
        debugPrint('[AUTH] Supabase login() error: $e');
      }

      // Map Supabase errors to user-friendly messages
      if (errorStr.contains('invalid_credentials') ||
          errorStr.contains('Invalid login credentials')) {
        return const Failure(
          AuthFailure(
            message: 'Incorrect email or password. Please try again.',
          ),
        );
      }
      if (errorStr.contains('email_not_confirmed') ||
          errorStr.contains('Email not confirmed')) {
        return const Failure(
          AuthFailure(
            message:
                'Please confirm your email before signing in. Check your inbox for the verification link.',
          ),
        );
      }
      if (errorStr.contains('too_many_requests')) {
        return const Failure(
          AuthFailure(
            message:
                'Too many login attempts. Please wait a moment and try again.',
          ),
        );
      }

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
      final response = await _supabase.auth
          .signUp(
            email: email,
            password: password,
            emailRedirectTo: kAppBaseUrl,
            data: {'name': name, 'user_type': userType},
          )
          .timeout(const Duration(seconds: 25));

      final sbUser = response.user;
      if (sbUser == null) {
        return const Failure(
          AuthFailure(message: 'Registration failed: User is null'),
        );
      }

      // CRITICAL: Supabase returns identities: [] when email already exists
      // (to prevent email enumeration). Detect this and show correct message.
      final identities = sbUser.identities;
      if (identities == null || identities.isEmpty) {
        debugPrint('[AUTH] Email already exists: $email (identities empty)');
        return const Failure(
          AuthFailure(
            message:
                'An account with this email already exists. Please try logging in instead.',
          ),
        );
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
      userData['ai_credits'] = kFreeAiCredits;

      // 3. Persist Profile to PostgreSQL
      try {
        await _supabase.from('users').upsert(userData);
      } catch (e) {
        debugPrint('[AUTH] RLS/Policy Block during profile sync: $e');
        debugPrint(
          '[AUTH] Proceeding with Local-Only state to allow app entry.',
        );
      }

      // 4. Handle confirmation requirement
      if (response.session == null) {
        return const Failure(
          VerificationRequiredFailure(
            message: 'Please check your email to confirm your account.',
          ),
        );
      }

      // Persist locally
      final storage = (localDatasource as AuthLocalDatasourceImpl).storage;
      await storage.save(StorageKeys.currentUser, userData);
      await localDatasource.saveTokens(
        response.session?.accessToken ?? '',
        response.session?.refreshToken ?? '',
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
      debugPrint('[AUTH] Supabase register() error: $e');

      // Handle email confirmation failure — user was created but email failed
      final errorStr = e.toString();
      if (errorStr.contains('Error sending confirmation email') ||
          errorStr.contains('unexpected_failure')) {
        debugPrint(
          '[AUTH] Email confirmation failed. SMTP may not be configured.',
        );

        // User was created in Supabase auth but email couldn't be sent.
        // Try auto-login — if it works, great. If not, tell them to contact support.
        try {
          final loginResponse = await _supabase.auth
              .signInWithPassword(email: email, password: password)
              .timeout(const Duration(seconds: 25));

          final sbUser = loginResponse.user;
          if (sbUser != null) {
            final user = User(
              id: sbUser.id,
              email: email,
              name: name,
              userType: userType,
              createdAt: DateTime.now(),
            );
            final userData = UserModel.fromEntity(user).toJson();
            userData['ai_credits'] = kFreeAiCredits;

            // Sync profile
            try {
              await _supabase.from('users').upsert(userData);
            } catch (e) {
              debugPrint('[ERROR] upsert user profile: $e');
            }

            // Persist locally
            final storage =
                (localDatasource as AuthLocalDatasourceImpl).storage;
            await storage.save(StorageKeys.currentUser, userData);
            await localDatasource.saveTokens(
              loginResponse.session?.accessToken ?? '',
              loginResponse.session?.refreshToken ?? '',
            );

            return Success(
              AuthResponse(
                user: user,
                accessToken: loginResponse.session?.accessToken ?? sbUser.id,
                refreshToken:
                    loginResponse.session?.refreshToken ?? 'supabase_session',
                expiresIn: loginResponse.session?.expiresIn ?? 3600,
              ),
            );
          }
        } catch (loginError) {
          debugPrint(
            '[AUTH] Auto-login after email failure also failed: $loginError',
          );
        }

        // Both signup email and auto-login failed.
        return const Failure(
          AuthFailure(
            message:
                'We could not send a verification email. Please contact support@desby.app to complete your registration.',
          ),
        );
      }

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
      await localStorage.delete(StorageKeys.rememberedEmail);
      // DO NOT delete onboarding flags — preserves state for returning users.
      // Cross-user contamination on shared devices is accepted as a known limitation.
      await localStorage.delete(StorageKeys.appFirstLaunch);

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
