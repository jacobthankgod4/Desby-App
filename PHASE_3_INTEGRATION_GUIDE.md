# Phase 3 Integration Guide

## Quick Start

### 1. Update Main Routes

Add auth routes to your navigation:

```dart
// lib/main.dart
import 'package:desby_app/features/auth/presentation/pages/login_page.dart';
import 'package:desby_app/features/auth/presentation/pages/register_page.dart';
import 'package:desby_app/features/auth/presentation/pages/onboarding_page.dart';

// In MaterialApp routes:
routes: {
  '/login': (context) => const LoginPage(),
  '/register': (context) => const RegisterPage(),
  '/onboarding': (context) => const OnboardingPage(),
  '/home': (context) => const HomePage(), // Your home page
},
```

### 2. Create Auth Guard

Protect routes based on authentication state:

```dart
// lib/features/auth/presentation/widgets/auth_guard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class AuthGuard extends ConsumerWidget {
  final Widget child;
  final String? redirectTo;

  const AuthGuard({
    required this.child,
    this.redirectTo = '/login',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    if (!isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(redirectTo!);
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return child;
  }
}
```

### 3. Update App Initialization

Check authentication on app start:

```dart
// lib/config/providers/app_providers.dart
final appInitializationProvider = FutureProvider((ref) async {
  // Existing initialization...
  
  // Check if user is already logged in
  final authRepository = ref.watch(authRepositoryProvider);
  final accessToken = await authRepository.getAccessToken();
  
  if (accessToken != null) {
    // User is already authenticated
    // You can restore the auth state here
  }
});
```

### 4. Add Token Refresh Logic

Implement automatic token refresh:

```dart
// lib/features/auth/presentation/providers/auth_provider.dart
// Add to AuthStateNotifier:

Future<void> _refreshTokenIfNeeded() async {
  final refreshToken = await authRepository.getRefreshToken();
  if (refreshToken != null) {
    await refreshToken(refreshToken);
  }
}
```

### 5. Update Dio Interceptor

Inject auth token in all requests:

```dart
// lib/core/network/interceptors.dart
class AuthInterceptor extends Interceptor {
  final AuthRepository authRepository;

  AuthInterceptor(this.authRepository);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await authRepository.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
```

### 6. Test the Integration

```bash
# Run all tests
flutter test

# Run auth tests specifically
flutter test test/features/auth/

# Run app
flutter run
```

---

## Usage Examples

### Login

```dart
// In a widget
final authNotifier = ref.read(authStateProvider.notifier);
await authNotifier.login('user@example.com', 'password');
```

### Check Authentication Status

```dart
// In a widget
final isAuthenticated = ref.watch(isAuthenticatedProvider);
final currentUser = ref.watch(currentUserProvider);

if (isAuthenticated) {
  print('User: ${currentUser?.name}');
}
```

### Logout

```dart
// In a widget
final authNotifier = ref.read(authStateProvider.notifier);
await authNotifier.logout();
```

### Listen to Auth State Changes

```dart
// In a widget
ref.listen(authStateProvider, (previous, next) {
  next.maybeMap(
    authenticated: (auth) {
      print('User logged in: ${auth.authResponse.user.name}');
    },
    unauthenticated: (_) {
      print('User logged out');
    },
    error: (error) {
      print('Auth error: ${error.message}');
    },
    orElse: () {},
  );
});
```

---

## API Configuration

Ensure your backend API endpoints match:

```dart
// lib/core/network/api_endpoints.dart
static const String authLogin = '/api/v1/auth/login';
static const String authRegister = '/api/v1/auth/register';
static const String authLogout = '/api/v1/auth/logout';
static const String authRefreshToken = '/api/v1/auth/refresh-token';
```

Expected request/response formats:

### Login Request
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

### Login Response
```json
{
  "user": {
    "id": "123",
    "email": "user@example.com",
    "name": "John Doe",
    "userType": "tailor",
    "createdAt": "2024-05-05T10:00:00Z",
    "phone": "+1234567890",
    "profileImage": "https://...",
    "bio": "Professional tailor",
    "isVerified": true
  },
  "accessToken": "eyJhbGc...",
  "refreshToken": "eyJhbGc...",
  "expiresIn": 3600
}
```

### Register Request
```json
{
  "email": "user@example.com",
  "password": "password123",
  "name": "John Doe",
  "userType": "tailor"
}
```

---

## Troubleshooting

### Issue: Code generation not working

```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Issue: Token not being saved

Check that LocalStorageService is initialized:
```dart
// In main.dart
await ref.read(localStorageProvider).initialize();
```

### Issue: Login fails with 401

Verify:
1. API endpoint is correct
2. Credentials are valid
3. Backend is running
4. Network connectivity is available

### Issue: State not updating in UI

Ensure you're using `ref.watch()` not `ref.read()` for reactive updates:
```dart
// ✅ Correct - reactive
final authState = ref.watch(authStateProvider);

// ❌ Wrong - not reactive
final authState = ref.read(authStateProvider);
```

---

## Next Steps

1. ✅ Phase 3 Complete - Authentication & Authorization
2. ⏳ Phase 4 - State Management Infrastructure (partial)
3. ⏳ Phase 5 - API Client & Networking (complete)
4. ⏳ Phase 6 - User Profile & Onboarding
5. ⏳ Phase 7 - Dashboard & Home

---

## Support

For issues or questions:
1. Check PHASE_3_COMPLETION.md for detailed documentation
2. Review test files for usage examples
3. Check ARCHITECTURE.md for design patterns
4. Review CODING_STANDARDS.md for code style

---

**Ready to integrate Phase 3 into your app!** 🚀
