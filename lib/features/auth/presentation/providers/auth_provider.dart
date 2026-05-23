import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../../data/models/user_model.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/storage/storage_keys.dart';
import '../state/auth_state.dart';
import '../../domain/entities/auth_response.dart';
import '../../domain/entities/user.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/repositories/firebase_auth_repository.dart';

// Type alias for FirebaseAuth to avoid conflicts
typedef FirebaseAuth = fb.FirebaseAuth;

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
    // Listen to Firebase auth state changes for persistent sessions on web
    final auth = FirebaseAuth.instance;
    _authStateSubscription = auth.authStateChanges().listen((firebaseUser) async {
      if (firebaseUser != null) {
        // User is logged in via Firebase session (including browser refresh)
        await _restoreAuthenticatedState(firebaseUser);
      } else {
        // No Firebase session - check local storage for fallback
        // STABILITY: Don't flip to unauthenticated if we're currently loading
        if (state.maybeMap(loading: (_) => true, orElse: () => false)) return;
        
        await _checkOnboardingAndUser();
      }
    });
  }

  Future<void> _restoreAuthenticatedState(firebaseUser) async {
    try {
      // Get user data from local storage
      final hasOnboarded = localStorage.get(StorageKeys.appFirstLaunch, defaultValue: false);
      if (!hasOnboarded) {
        // Only reset if not in the middle of a transition
        if (!state.maybeMap(loading: (_) => true, orElse: () => false)) {
          state = const AuthState.unauthenticated();
        }
        return;
      }
      
      final cachedUserType = localStorage.get(StorageKeys.userType, defaultValue: 'tailor');
      final currentUserData = localStorage.get(StorageKeys.currentUser, defaultValue: null);
      
      String? email;
      String? name;
      
      if (currentUserData != null && currentUserData is Map) {
        email = currentUserData['email'] as String?;
        name = currentUserData['name'] as String?;
      }
      
      // Update state
      final newState = AuthState.authenticated(
        AuthResponse(
          user: UserModel(
            id: firebaseUser.uid,
            email: email ?? firebaseUser.email ?? '',
            name: name ?? firebaseUser.displayName ?? '',
            userType: cachedUserType,
            createdAt: DateTime.now(),
          ).toEntity(),
          accessToken: firebaseUser.uid,
          refreshToken: 'firebase_session',
          expiresIn: 3600,
        ),
      );

      // STABILITY: Only update if the user isn't already the same (prevent flicker)
      state.maybeMap(
        authenticated: (current) {
          if (current.authResponse.user.id != firebaseUser.uid) {
            state = newState;
          }
        },
        orElse: () => state = newState,
      );
    } catch (e) {
      // On error, try to maintain session - Firebase session may still be valid
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
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
        // If we are authenticated but have no token, stay silent to allow Firebase listener to fire
        // Only flip to unauthenticated if truly logged out
        final auth = FirebaseAuth.instance;
        if (auth.currentUser == null) {
          state = const AuthState.unauthenticated();
        }
        return;
      }

      final cachedUserType = localStorage.get(StorageKeys.userType, defaultValue: 'tailor');

      state = AuthState.authenticated(
        AuthResponse(
          user: UserModel(
            id: accessToken,
            email: '',
            name: '',
            userType: cachedUserType,
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
      (failure) => state = AuthState.error(failure.toString()),
      (authResponse) async {
        await localStorage.save(StorageKeys.appFirstLaunch, true);
        await localStorage.save(StorageKeys.userType, authResponse.user.userType);
        
        await localStorage.save(StorageKeys.rememberMe, rememberMe);
        if (rememberMe) {
          await localStorage.save(StorageKeys.rememberedEmail, email);
          await localStorage.save(StorageKeys.rememberedPassword, password);
        } else {
          await localStorage.delete(StorageKeys.rememberedEmail);
          await localStorage.delete(StorageKeys.rememberedPassword);
        }

        state = AuthState.authenticated(authResponse);
      },
    );
  }

  Future<void> register(String email, String password, String name, String userType) async {
    state = const AuthState.loading();
    final result = await registerUsecase(email, password, name, userType);
    result.fold(
      (failure) => state = AuthState.error(failure.toString()),
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
  return FirebaseAuthRepository(
    localDatasource: ref.watch(authLocalDatasourceProvider),
  );
});
