import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../../core/error/failures.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../../data/models/user_model.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/storage/storage_keys.dart';
import '../state/auth_state.dart';
import '../../domain/entities/auth_response.dart';
import '../../domain/entities/user.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/repositories/supabase_auth_repository.dart';

final loginUsecaseProvider = Provider(
  (ref) => LoginUsecase(ref.watch(authRepositoryProvider)),
);
final registerUsecaseProvider = Provider(
  (ref) => RegisterUsecase(ref.watch(authRepositoryProvider)),
);
final logoutUsecaseProvider = Provider(
  (ref) => LogoutUsecase(ref.watch(authRepositoryProvider)),
);
final refreshTokenUsecaseProvider = Provider(
  (ref) => RefreshTokenUsecase(ref.watch(authRepositoryProvider)),
);

final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((
  ref,
) {
  return AuthStateNotifier(
    loginUsecase: ref.watch(loginUsecaseProvider),
    registerUsecase: ref.watch(registerUsecaseProvider),
    logoutUsecase: ref.watch(logoutUsecaseProvider),
    refreshTokenUsecase: ref.watch(refreshTokenUsecaseProvider),
    authRepository: ref.watch(authRepositoryProvider),
  );
});

class AuthStateNotifier extends StateNotifier<AuthState> {
  final LoginUsecase loginUsecase;
  final RegisterUsecase registerUsecase;
  final LogoutUsecase logoutUsecase;
  final RefreshTokenUsecase refreshTokenUsecase;
  final AuthRepository authRepository;
  StreamSubscription? _authStateSubscription;

  AuthStateNotifier({
    required this.loginUsecase,
    required this.registerUsecase,
    required this.logoutUsecase,
    required this.refreshTokenUsecase,
    required this.authRepository,
  }) : super(const AuthState.initial()) {
    // Avoid touching Firebase during widget tests.
    const isFlutterTest = bool.fromEnvironment(
      'FLUTTER_TEST',
      defaultValue: false,
    );
    if (!isFlutterTest) {
      _initAuthStateListener();
    }
  }

  void _initAuthStateListener() {
    // Listen to Supabase auth state changes for persistent sessions
    final auth = sb.Supabase.instance.client.auth;
    _authStateSubscription = auth.onAuthStateChange.listen(
      (data) async {
        try {
          final session = data.session;
          final event = data.event;

          // Token refreshed — update state silently
          if (event == sb.AuthChangeEvent.tokenRefreshed && session != null) {
            await _restoreAuthenticatedState(session.user, session);
            return;
          }

          // Signed out — go to unauthenticated
          if (event == sb.AuthChangeEvent.signedOut) {
            state = const AuthState.unauthenticated();
            return;
          }

          // Password events — ignore, don't change state
          if (event == sb.AuthChangeEvent.passwordRecovery ||
              event == sb.AuthChangeEvent.mfaChallengeVerified) {
            return;
          }

          if (session != null) {
            // User is logged in via Supabase session
            await _restoreAuthenticatedState(session.user, session);
          } else {
            // No session in event
            if (state.maybeMap(loading: (_) => true, orElse: () => false))
              return;

            final currentSession =
                sb.Supabase.instance.client.auth.currentSession;
            if (currentSession != null) {
              await _restoreAuthenticatedState(
                currentSession.user,
                currentSession,
              );
            } else {
              // No session at all — go to login
              state = const AuthState.unauthenticated();
            }
          }
        } catch (e) {
          debugPrint(
            '[AUTH] onAuthStateChange listener error (suppressed): $e',
          );
        }
      },
      onError: (error) {
        // Suppress GoTrue internal polling errors (e.g. from failed resend calls)
        debugPrint(
          '[AUTH] onAuthStateChange stream error (suppressed): $error',
        );
      },
    );
  }

  Future<void> _restoreAuthenticatedState(
    sb.User sbUser,
    sb.Session? session,
  ) async {
    try {
      // Email is confirmed from here on, so the pending-verification record has
      // served its purpose. Cleared inside the try so a storage failure cannot
      // abort session restoration.
      try {
        await localStorage.delete(StorageKeys.pendingVerificationEmail);
      } catch (_) {
        // best effort
      }
      // CRITICAL: If we're already authenticated with this user, don't override
      // This prevents _restoreAuthenticatedState from overriding login()'s correct state
      final isAlreadyAuthenticated = state.maybeMap(
        authenticated: (current) => current.authResponse.user.id == sbUser.id,
        orElse: () => false,
      );
      if (isAlreadyAuthenticated) return;

      // If we're in loading state (login/register in progress), don't interfere
      if (state.maybeMap(loading: (_) => true, orElse: () => false)) return;

      // Try to get cached user data from local storage
      final currentUserData = localStorage.get(
        StorageKeys.currentUser,
        defaultValue: null,
      );
      String? email;
      String? name;

      if (currentUserData != null && currentUserData is Map) {
        email = currentUserData['email'] as String?;
        name = currentUserData['name'] as String?;
      }

      // Always fetch the real userType from Supabase — never silently default
      String? userType;
      Map<String, dynamic>? profileResponse;
      try {
        profileResponse = await sb.Supabase.instance.client
            .from('users')
            .select('user_type, name, email')
            .eq('id', sbUser.id)
            .maybeSingle();
      } catch (e) {
        // On 401 (JWT clock skew / expired), refresh session and retry once
        final isAuthError =
            e.toString().contains('401') || e.toString().contains('PGRST303');
        if (isAuthError) {
          try {
            await sb.Supabase.instance.client.auth.refreshSession();
            profileResponse = await sb.Supabase.instance.client
                .from('users')
                .select('user_type, name, email')
                .eq('id', sbUser.id)
                .maybeSingle();
          } catch (_) {}
        }
        if (profileResponse == null) {
          debugPrint('[AUTH] Profile fetch failed, using cached userType: $e');
          userType = localStorage.get(StorageKeys.userType, defaultValue: null);
        }
      }

      if (profileResponse != null) {
        if (profileResponse['user_type'] != null) {
          userType = profileResponse['user_type'] as String;
        }
        if (profileResponse['name'] != null &&
            (profileResponse['name'] as String).isNotEmpty) {
          name = profileResponse['name'] as String;
        }
        if (profileResponse['email'] != null &&
            (profileResponse['email'] as String).isNotEmpty) {
          email = profileResponse['email'] as String;
        }
        // Update local cache immediately
        if (userType != null) {
          await localStorage.save(StorageKeys.userType, userType);
        }
        await localStorage.save(StorageKeys.currentUser, {
          'id': sbUser.id,
          'user_type': userType ?? '',
          'email': email ?? sbUser.email ?? '',
          'name': name ?? sbUser.userMetadata?['name'] ?? '',
        });
      }

      // If userType could not be determined from any source, fail explicitly
      if (userType == null || userType.isEmpty) {
        debugPrint(
          '[AUTH] FATAL: Cannot determine userType for ${sbUser.id}. '
          'No profile in DB and no cached value.',
        );
        state = const AuthState.error(
          'Your account has no user type assigned. Please contact support.',
        );
        return;
      }

      // Update state
      final newState = AuthState.authenticated(
        AuthResponse(
          user: UserModel(
            id: sbUser.id,
            email: email ?? sbUser.email ?? '',
            name: name ?? sbUser.userMetadata?['name'] ?? '',
            userType: userType,
            createdAt: DateTime.now(),
          ).toEntity(),
          accessToken: session?.accessToken ?? sbUser.id,
          refreshToken: session?.refreshToken ?? 'supabase_session',
          expiresIn: session?.expiresIn ?? 3600,
        ),
      );

      // Only update if we're not already authenticated with same user
      state.maybeMap(
        authenticated: (current) {
          if (current.authResponse.user.id != sbUser.id ||
              current.authResponse.user.userType != userType) {
            state = newState;
          }
        },
        orElse: () {
          // Don't override loading state (login/register in progress)
          if (!state.maybeMap(loading: (_) => true, orElse: () => false)) {
            state = newState;
          }
        },
      );
    } catch (e) {
      debugPrint('[AUTH] _restoreAuthenticatedState error: $e');
      // If we're still stuck in initial or any non-authenticated state,
      // transition to unauthenticated so the login page shows
      final isCurrentlyAuthenticated = state.maybeMap(
        authenticated: (_) => true,
        orElse: () => false,
      );
      if (!isCurrentlyAuthenticated) {
        state = const AuthState.unauthenticated();
      }
    }
  }

  Future<void> login(
    String email,
    String password, {
    bool rememberMe = false,
  }) async {
    state = const AuthState.loading();
    final result = await loginUsecase(email, password);
    result.fold(
      (failure) {
        debugPrint('[AUTH] Login failure: ${failure.message}');
        state = AuthState.error(failure.message);
      },
      (authResponse) async {
        debugPrint('[AUTH] Login success. User ID: ${authResponse.user.id}');
        await localStorage.save(StorageKeys.appFirstLaunch, true);
        await localStorage.save(
          StorageKeys.userType,
          authResponse.user.userType,
        );
        await localStorage.save(StorageKeys.currentUser, {
          'id': authResponse.user.id,
          'user_type': authResponse.user.userType,
          'email': authResponse.user.email,
          'name': authResponse.user.name,
        });

        await localStorage.saveAuthValue(StorageKeys.rememberMe, rememberMe);
        if (rememberMe) {
          await localStorage.saveAuthValue(StorageKeys.rememberedEmail, email);
        } else {
          await localStorage.deleteAuthValue(StorageKeys.rememberedEmail);
        }

        state = AuthState.authenticated(authResponse);
      },
    );
  }

  Future<void> register(
    String email,
    String password,
    String name,
    String userType,
  ) async {
    state = const AuthState.loading();
    final result = await registerUsecase(email, password, name, userType);
    // Persist the address before branching, so a hard reload of /verify-email
    // can still offer "Resend". The route carries no arguments, so without this
    // the page boots knowing nothing about which address to resend to.
    try {
      await localStorage.save(StorageKeys.pendingVerificationEmail, email);
    } catch (_) {
      // best effort — resend still works while the page stays open
    }

    result.fold(
      (failure) {
        if (failure is VerificationRequiredFailure) {
          state = AuthState.unverified(email);
        } else {
          state = AuthState.error(failure.message);
        }
      },
      (authResponse) async {
        await localStorage.save(StorageKeys.appFirstLaunch, true);
        await localStorage.save(
          StorageKeys.userType,
          authResponse.user.userType,
        );
        await localStorage.save(StorageKeys.currentUser, {
          'id': authResponse.user.id,
          'user_type': authResponse.user.userType,
          'email': authResponse.user.email,
          'name': authResponse.user.name,
        });
        state = AuthState.authenticated(authResponse);
      },
    );
  }

  Future<void> logout() async {
    state = const AuthState.loading();
    await logoutUsecase();
    state = const AuthState.unauthenticated();
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.maybeMap(
    authenticated: (a) => a.authResponse.user,
    orElse: () => null,
  );
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.maybeMap(authenticated: (_) => true, orElse: () => false);
});

final authLocalDatasourceProvider = Provider<AuthLocalDatasource>((ref) {
  return AuthLocalDatasourceImpl(localStorage);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(
    localDatasource: ref.watch(authLocalDatasourceProvider),
  );
});
