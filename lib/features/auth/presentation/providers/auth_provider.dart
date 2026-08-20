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

final loginUsecaseProvider = Provider((ref) => LoginUsecase(ref.watch(authRepositoryProvider)));
final registerUsecaseProvider = Provider((ref) => RegisterUsecase(ref.watch(authRepositoryProvider)));
final logoutUsecaseProvider = Provider((ref) => LogoutUsecase(ref.watch(authRepositoryProvider)));
final refreshTokenUsecaseProvider = Provider((ref) => RefreshTokenUsecase(ref.watch(authRepositoryProvider)));

final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
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
    const isFlutterTest = bool.fromEnvironment('FLUTTER_TEST', defaultValue: false);
    if (!isFlutterTest) {
      _initAuthStateListener();
    }
  }

  void _initAuthStateListener() {
    // Listen to Supabase auth state changes for persistent sessions
    final auth = sb.Supabase.instance.client.auth;
    _authStateSubscription = auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      final event = data.event;

      if (session != null) {
        // User is logged in via Supabase session
        await _restoreAuthenticatedState(session.user, session);
      } else if (event == sb.AuthChangeEvent.signedOut) {
        // Explicit logout
        await _checkOnboardingAndUser();
      } else {
        // No Supabase session - check local storage for fallback
        if (state.maybeMap(loading: (_) => true, orElse: () => false)) return;
        
        await _checkOnboardingAndUser();
      }
    });
  }

  Future<void> _restoreAuthenticatedState(sb.User sbUser, sb.Session? session) async {
    try {
      // Get user data from local storage
      final hasOnboarded = localStorage.get(StorageKeys.appFirstLaunch, defaultValue: false);
      if (!hasOnboarded) {
        if (!state.maybeMap(loading: (_) => true, orElse: () => false)) {
          state = const AuthState.unauthenticated();
        }
        return;
      }
      
      // EXPERT FIX: Prefer current_user metadata from local storage if available
      final currentUserData = localStorage.get(StorageKeys.currentUser, defaultValue: null);
      String userType = 'tailor';
      String? email;
      String? name;
      
      if (currentUserData != null && currentUserData is Map) {
        userType = (currentUserData['user_type'] ?? currentUserData['userType']) as String? ?? 'tailor';
        email = currentUserData['email'] as String?;
        name = currentUserData['name'] as String?;
      } else {
        // Fallback to separate userType key
        userType = localStorage.get(StorageKeys.userType, defaultValue: 'tailor');
      }
      
      // EXPERT SYNC: If userType is still tailor, attempt a hard fetch from Supabase
      // to resolve the "everyone is a tailor" routing bug.
      if (userType == 'tailor') {
         try {
           final profileResponse = await sb.Supabase.instance.client
               .from('users')
               .select('user_type')
               .eq('id', sbUser.id)
               .maybeSingle();
           
           if (profileResponse != null && profileResponse['user_type'] != null) {
             userType = profileResponse['user_type'] as String;
             // Update local cache immediately
             await localStorage.save(StorageKeys.userType, userType);
             if (currentUserData != null && currentUserData is Map) {
                final updatedMap = Map<String, dynamic>.from(currentUserData);
                updatedMap['user_type'] = userType;
                await localStorage.save(StorageKeys.currentUser, updatedMap);
             }
           }
         } catch (e) {
           debugPrint('[AUTH] Emergency Profile Fetch Failed: $e');
         }
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

      state.maybeMap(
        authenticated: (current) {
          if (current.authResponse.user.id != sbUser.id || 
              current.authResponse.user.userType != userType) {
            state = newState;
          }
        },
        orElse: () => state = newState,
      );
    } catch (e) {
      final auth = sb.Supabase.instance.client.auth;
      if (auth.currentSession == null) {
        state = const AuthState.unauthenticated();
      }
    }
  }

  Future<void> _checkOnboardingAndUser() async {
    try {
      final hasOnboarded = localStorage.get(StorageKeys.appFirstLaunch, defaultValue: false);
      
      if (!hasOnboarded) {
        state = const AuthState.unauthenticated();
        return;
      }

      final accessTokenResult = await authRepository.getAccessToken();
      final accessToken = accessTokenResult.getOrNull();

      if (accessToken == null) {
        final auth = sb.Supabase.instance.client.auth;
        if (auth.currentSession == null) {
          state = const AuthState.unauthenticated();
        }
        return;
      }

      // Get actual user ID from Supabase session instead of using token
      final auth = sb.Supabase.instance.client.auth;
      final sbUser = auth.currentUser;
      final userId = sbUser?.id ?? '';

      // Get userType from correct source
      final currentUserData = localStorage.get(StorageKeys.currentUser, defaultValue: null);
      String userType = 'tailor';
      String? email;
      String? name;
      if (currentUserData != null && currentUserData is Map) {
         userType = (currentUserData['user_type'] ?? currentUserData['userType']) as String? ?? 'tailor';
         email = currentUserData['email'] as String?;
         name = currentUserData['name'] as String?;
      } else {
         userType = localStorage.get(StorageKeys.userType, defaultValue: 'tailor');
      }

      state = AuthState.authenticated(
        AuthResponse(
          user: UserModel(
            id: userId,
            email: email ?? sbUser?.email ?? '',
            name: name ?? sbUser?.userMetadata?['name'] ?? '',
            userType: userType,
            createdAt: DateTime.now(),
          ).toEntity(),
          accessToken: accessToken,
          refreshToken: '',
          expiresIn: 3600,
        ),
      );
    } catch (e) {
      debugPrint('[AuthState] _checkOnboardingAndUser error: $e - maintaining current state');
    }
  }

  Future<void> login(String email, String password, {bool rememberMe = false}) async {
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
        await localStorage.save(StorageKeys.userType, authResponse.user.userType);
        
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

  Future<void> register(String email, String password, String name, String userType) async {
    state = const AuthState.loading();
    final result = await registerUsecase(email, password, name, userType);
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
        await localStorage.save(StorageKeys.userType, authResponse.user.userType);
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
  return authState.maybeMap(
    authenticated: (_) => true,
    orElse: () => false,
  );
});

final authLocalDatasourceProvider = Provider<AuthLocalDatasource>((ref) {
  return AuthLocalDatasourceImpl(localStorage);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(
    localDatasource: ref.watch(authLocalDatasourceProvider),
  );
});
