# Phase 4: State Management Infrastructure - IMPLEMENTATION GUIDE

**Status**: ✅ COMPLETE  
**Date**: May 5, 2024  
**Files Created**: 4  
**Components**: Session Management, Token Refresh, Activity Tracking, State Sync  

---

## Overview

Phase 4 extends the state management infrastructure with advanced features for session management, automatic token refresh, user activity tracking, and state synchronization across app instances.

---

## Components Implemented

### 1. Session Manager (lib/features/auth/presentation/utils/session_manager.dart)

**Purpose**: Handles session restoration on app restart and session timeout

**Features**:
- Session restoration from stored tokens
- Session timeout tracking (24 hours default)
- Automatic logout on timeout
- Session timer management

**Key Methods**:
```dart
Future<bool> restoreSession(WidgetRef ref)
void _startSessionTimer(WidgetRef ref)
Future<void> _handleSessionTimeout(WidgetRef ref)
void resetSessionTimer(WidgetRef ref)
void dispose()
```

**Usage**:
```dart
final sessionManager = ref.watch(sessionManagerProvider);
final restored = await sessionManager.restoreSession(ref);
```

**Providers**:
- `sessionManagerProvider` - Session manager instance
- `sessionRestorationProvider` - Session restoration future

---

### 2. Token Refresh Interceptor (lib/core/network/token_refresh_interceptor.dart)

**Purpose**: Automatically refreshes access token when it expires (401 response)

**Features**:
- Detects 401 Unauthorized responses
- Prevents multiple simultaneous refresh attempts
- Queues failed requests during refresh
- Retries original request after token refresh
- Automatic logout on refresh failure

**Key Methods**:
```dart
Future<void> onError(DioException err, ErrorInterceptorHandler handler)
Future<bool> _refreshToken()
void _retryFailedRequests()
Future<Response> _retry(RequestOptions requestOptions)
```

**Integration**:
```dart
// Add to Dio interceptors in DioClient
dio.interceptors.add(TokenRefreshInterceptor(ref));
```

**Flow**:
```
401 Response
  ↓
Check if already refreshing
  ↓
Refresh token with refresh token
  ↓
Success → Retry original request
Failure → Logout user
```

---

### 3. User Activity Tracker (lib/features/auth/presentation/widgets/user_activity_tracker.dart)

**Purpose**: Tracks user activity and resets session timeout

**Features**:
- Detects user interactions (tap, pan, mouse)
- Resets session timeout on activity
- Prevents session timeout during active use
- Customizable inactivity timeout

**Usage**:
```dart
UserActivityTracker(
  inactivityTimeout: Duration(minutes: 15),
  child: MaterialApp(
    // Your app
  ),
)
```

**Tracked Events**:
- Tap events
- Pan/drag events
- Mouse hover events

---

### 4. State Synchronization Manager (lib/core/state/state_synchronization.dart)

**Purpose**: Handles synchronization of app state across different instances

**Features**:
- Register state streams for synchronization
- Broadcast state changes to listeners
- Multi-device state sync support
- Centralized state management

**Key Methods**:
```dart
void registerStateStream<T>(String key, Stream<T> stream, Function(T) onStateChange)
void broadcastStateChange<T>(String key, T state)
Stream<T>? getStateStream<T>(String key)
void dispose()
```

**Providers**:
- `stateSynchronizationProvider` - State sync manager
- `authStateSynchronizationProvider` - Auth state sync

**Usage**:
```dart
final syncManager = ref.watch(stateSynchronizationProvider);
syncManager.broadcastStateChange('auth_state', newAuthState);
```

---

## Integration with Main App

### Update main.dart

```dart
import 'package:desby_app/features/auth/presentation/widgets/user_activity_tracker.dart';
import 'package:desby_app/features/auth/presentation/utils/session_manager.dart';

class DesbyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch session restoration
    final sessionRestoration = ref.watch(sessionRestorationProvider);

    return sessionRestoration.when(
      data: (_) {
        return UserActivityTracker(
          child: MaterialApp(
            // Your app configuration
          ),
        );
      },
      loading: () => const LoadingScreen(),
      error: (error, stack) => const ErrorScreen(),
    );
  }
}
```

### Update DioClient

```dart
// In lib/core/network/dio_client.dart
import 'package:desby_app/core/network/token_refresh_interceptor.dart';

class DioClient {
  void _setupInterceptors(WidgetRef ref) {
    dio.interceptors.addAll([
      LoggingInterceptor(),
      AuthInterceptor(),
      TokenRefreshInterceptor(ref),  // Add token refresh interceptor
      ErrorInterceptor(),
      RetryInterceptor(),
    ]);
  }
}
```

---

## State Management Flow

### Session Restoration Flow

```
App Start
  ↓
sessionRestorationProvider triggered
  ↓
SessionManager.restoreSession()
  ↓
Check for stored access token
  ↓
Token found → Start session timer → Return true
Token not found → Return false
  ↓
App routes based on restoration result
```

### Token Refresh Flow

```
API Request
  ↓
Response 401 Unauthorized
  ↓
TokenRefreshInterceptor.onError()
  ↓
Check if already refreshing
  ↓
Refresh token with refresh token
  ↓
Success → Retry original request → Return response
Failure → Logout user → Return error
```

### User Activity Flow

```
User Interaction (tap, pan, mouse)
  ↓
UserActivityTracker detects event
  ↓
SessionManager.resetSessionTimer()
  ↓
Cancel existing timer
  ↓
Start new 24-hour timer
```

### State Synchronization Flow

```
State Change (e.g., auth state)
  ↓
authStateSynchronizationProvider watches change
  ↓
StateSynchronizationManager.broadcastStateChange()
  ↓
All registered listeners notified
  ↓
State synced across app instances
```

---

## Riverpod Providers

### New Providers

```dart
// Session Management
sessionManagerProvider → SessionManager
sessionRestorationProvider → FutureProvider<bool>

// State Synchronization
stateSynchronizationProvider → StateSynchronizationManager
authStateSynchronizationProvider → AuthState
```

### Provider Dependencies

```
sessionRestorationProvider
  ↓
sessionManagerProvider
  ↓
authRepositoryProvider
  ↓
authStateProvider

authStateSynchronizationProvider
  ↓
stateSynchronizationProvider
  ↓
authStateProvider
```

---

## Configuration

### Session Timeout

```dart
// In SessionManager
static const Duration _sessionTimeout = Duration(hours: 24);
```

Customize by modifying the constant or passing as parameter.

### Inactivity Timeout

```dart
// In UserActivityTracker
UserActivityTracker(
  inactivityTimeout: Duration(minutes: 15),
  child: child,
)
```

### Token Refresh Retry

```dart
// In TokenRefreshInterceptor
// Automatically retries failed requests after token refresh
// Max retries handled by RetryInterceptor
```

---

## Error Handling

### Session Restoration Errors

```dart
sessionRestoration.when(
  data: (restored) {
    if (restored) {
      // Session restored, show home
    } else {
      // No session, show login
    }
  },
  error: (error, stack) {
    // Handle restoration error
    logger.error('Session restoration failed', error: error);
  },
)
```

### Token Refresh Errors

```dart
// Handled automatically by TokenRefreshInterceptor
// On failure: User is logged out
// Error logged via logger
```

### State Sync Errors

```dart
// Handled in StateSynchronizationManager
// Errors logged but don't break app
// State sync continues on next change
```

---

## Testing

### Session Manager Tests

```dart
test('should restore session from stored token', () async {
  // Arrange
  when(mockAuthRepository.getAccessToken())
      .thenAnswer((_) async => 'access_token');

  // Act
  final restored = await sessionManager.restoreSession(ref);

  // Assert
  expect(restored, true);
});

test('should logout on session timeout', () async {
  // Arrange
  final sessionManager = SessionManager();

  // Act
  await sessionManager._handleSessionTimeout(ref);

  // Assert
  verify(mockAuthNotifier.logout()).called(1);
});
```

### Token Refresh Interceptor Tests

```dart
test('should refresh token on 401 response', () async {
  // Arrange
  final interceptor = TokenRefreshInterceptor(ref);
  final dioException = DioException(
    response: Response(statusCode: 401),
  );

  // Act
  await interceptor.onError(dioException, handler);

  // Assert
  verify(mockAuthRepository.refreshToken(any)).called(1);
});
```

---

## Security Considerations

✅ Token refresh prevents session hijacking  
✅ Session timeout prevents unauthorized access  
✅ User activity tracking prevents idle session abuse  
✅ State synchronization maintains consistency  
✅ Automatic logout on token refresh failure  
✅ Failed requests queued during refresh  

---

## Performance Considerations

✅ Single token refresh attempt at a time  
✅ Failed requests queued, not retried immediately  
✅ Session timer optimized with single timer  
✅ State sync uses efficient stream-based approach  
✅ Activity tracking uses gesture detection  

---

## File Structure

```
lib/
├── core/
│   ├── network/
│   │   └── token_refresh_interceptor.dart (NEW)
│   └── state/
│       └── state_synchronization.dart (NEW)
└── features/
    └── auth/
        └── presentation/
            ├── utils/
            │   ├── session_manager.dart (NEW)
            │   └── token_refresh_helper.dart (existing)
            └── widgets/
                ├── user_activity_tracker.dart (NEW)
                └── auth_guard.dart (existing)
```

---

## Integration Checklist

- [ ] Add TokenRefreshInterceptor to DioClient
- [ ] Wrap app with UserActivityTracker
- [ ] Watch sessionRestorationProvider in main.dart
- [ ] Test session restoration flow
- [ ] Test token refresh flow
- [ ] Test user activity tracking
- [ ] Test state synchronization
- [ ] Run all tests: `flutter test test/features/auth/`
- [ ] Verify no console errors
- [ ] Test on multiple devices

---

## Next Steps

### Phase 5: User Profile & Onboarding
- [ ] Complete onboarding flow
- [ ] Add profile setup screens
- [ ] Add role-specific onboarding
- [ ] Add profile editing

### Phase 6: Dashboard & Home
- [ ] Implement dashboard
- [ ] Add home page features
- [ ] Add navigation drawer
- [ ] Add quick actions

---

## Metrics

| Component | Lines | Status |
|-----------|-------|--------|
| SessionManager | 50 | ✅ |
| TokenRefreshInterceptor | 100 | ✅ |
| UserActivityTracker | 40 | ✅ |
| StateSynchronizationManager | 60 | ✅ |
| **Total** | **250** | **✅** |

---

## Status

**Phase 4: State Management Infrastructure** ✅ **COMPLETE**

All advanced state management features have been implemented and are ready for integration.

---

**Ready for Phase 5: User Profile & Onboarding** 🚀
