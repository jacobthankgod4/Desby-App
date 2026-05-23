# Desby OS - Architecture Documentation

## Overview

Desby OS follows **Clean Architecture** principles with **Riverpod** for state management. The project is organized into distinct layers that are independent, testable, and maintainable.

## Architecture Layers

### 1. Presentation Layer
**Location**: `lib/features/*/presentation/`

Responsible for UI and user interaction.

**Components**:
- **Pages**: Full-screen widgets (routes)
- **Widgets**: Reusable UI components
- **Providers**: Riverpod providers for state management
- **State**: State classes (if using StateNotifier)

**Responsibilities**:
- Display data to users
- Capture user input
- Handle navigation
- Manage UI state

**Dependencies**: Domain layer only

### 2. Domain Layer
**Location**: `lib/features/*/domain/`

Contains business logic and rules.

**Components**:
- **Entities**: Pure business models (no serialization)
- **Repositories**: Abstract interfaces
- **Usecases**: Business logic operations

**Responsibilities**:
- Define business rules
- Abstract data sources
- Encapsulate business logic

**Dependencies**: None (pure Dart)

### 3. Data Layer
**Location**: `lib/features/*/data/`

Handles data retrieval and persistence.

**Components**:
- **Datasources**: Remote (API) and local (database) data sources
- **Models**: JSON-serializable data classes
- **Repositories**: Implement abstract repository interfaces

**Responsibilities**:
- Fetch data from APIs
- Store data locally
- Map between models and entities
- Handle data transformations

**Dependencies**: Domain layer

### 4. Core Infrastructure
**Location**: `lib/core/`

Shared utilities and services used across the app.

**Components**:
- **error/**: Exception and failure handling
- **logging/**: Structured logging
- **network/**: HTTP client and interceptors
- **storage/**: Local and secure storage
- **utils/**: Extensions and validators

**Responsibilities**:
- Provide shared services
- Handle errors consistently
- Manage logging
- Configure networking

**Dependencies**: None (pure utilities)

### 5. Configuration
**Location**: `lib/config/`

Application-wide configuration and constants.

**Components**:
- **app_config.dart**: App metadata and settings
- **environment.dart**: Environment-specific configuration
- **constants.dart**: App-wide constants
- **providers/**: Global Riverpod providers

**Responsibilities**:
- Centralize configuration
- Manage environment variables
- Provide global providers

**Dependencies**: Core infrastructure

### 6. Theme & Design System
**Location**: `lib/theme/`

Design system and theming.

**Components**:
- **app_theme.dart**: Theme configuration
- **colors.dart**: Color palette
- **typography.dart**: Text styles
- **spacing.dart**: Layout constants
- **shadows.dart**: Elevation system

**Responsibilities**:
- Define visual design
- Ensure consistency
- Support dark/light modes

**Dependencies**: None

## Data Flow

```
User Interaction (UI)
        ↓
Presentation Layer (Pages/Widgets)
        ↓
Riverpod Providers (State Management)
        ↓
Domain Layer (Usecases)
        ↓
Data Layer (Repositories)
        ↓
Datasources (API/Local Storage)
        ↓
External Services (Backend/Database)
```

## Dependency Injection

All dependencies are injected via **Riverpod providers**.

### Provider Types

**Provider**: Synchronous, immutable value
```dart
final appNameProvider = Provider((ref) => 'Desby OS');
```

**FutureProvider**: Asynchronous operation
```dart
final userProvider = FutureProvider<User>((ref) async {
  return await ref.watch(userRepositoryProvider).getUser();
});
```

**StreamProvider**: Real-time data stream
```dart
final messagesProvider = StreamProvider<List<Message>>((ref) {
  return ref.watch(chatRepositoryProvider).getMessages();
});
```

**StateNotifierProvider**: Mutable state
```dart
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
```

**Family**: Dynamic parameters
```dart
final userProvider = FutureProvider.family<User, String>((ref, userId) async {
  return await ref.watch(userRepositoryProvider).getUser(userId);
});
```

## State Management Pattern

### Using Riverpod

1. **Define Provider**:
```dart
final userProvider = FutureProvider.family<User, String>((ref, id) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getUser(id);
});
```

2. **Use in Widget**:
```dart
class UserPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider('123'));
    
    return userAsync.when(
      data: (user) => UserView(user: user),
      loading: () => const LoadingWidget(),
      error: (err, stack) => ErrorWidget(error: err),
    );
  }
}
```

3. **Invalidate Cache**:
```dart
ref.refresh(userProvider('123'));
```

## Error Handling

### Exception Hierarchy

```
AppException (base)
├── NetworkException
├── AuthenticationException
├── AuthorizationException
├── ValidationException
├── StorageException
├── ServerException
└── UnknownException
```

### Failure Types

```
Failure (base)
├── NetworkFailure
├── ServerFailure
├── AuthFailure
├── ValidationFailure
├── CacheFailure
└── UnknownFailure
```

### Usage

```dart
try {
  final user = await repository.getUser(id);
} on NetworkException catch (e) {
  // Handle network error
} on AuthenticationException catch (e) {
  // Handle auth error
} catch (e) {
  // Handle unknown error
}
```

## Testing Strategy

### Unit Tests
- Test domain layer (usecases, entities)
- Test data layer (repositories, datasources)
- Mock dependencies

### Widget Tests
- Test presentation layer widgets
- Mock providers
- Test UI interactions

### Integration Tests
- Test complete user flows
- Use real providers
- Test navigation

### Test Structure
```
test/
├── core/
│   ├── error/
│   ├── logging/
│   ├── network/
│   └── storage/
├── features/
│   └── auth/
│       ├── data/
│       ├── domain/
│       └── presentation/
└── fixtures/
    ├── mock_data.dart
    └── test_helpers.dart
```

## Code Generation

### Freezed (Immutable Models)
```dart
@freezed
class User with _$User {
  const factory User({
    required String id,
    required String name,
  }) = _User;
  
  factory User.fromJson(Map<String, dynamic> json) =>
      _$UserFromJson(json);
}
```

### Riverpod Generator
```dart
@riverpod
Future<User> user(UserRef ref, String id) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getUser(id);
}
```

### Retrofit (API Client)
```dart
@RestApi(baseUrl: 'https://api.example.com')
abstract class ApiClient {
  factory ApiClient(Dio dio, {String baseUrl}) = _ApiClient;
  
  @GET('/users/{id}')
  Future<UserModel> getUser(@Path('id') String id);
}
```

## Naming Conventions

### Files
- `snake_case.dart` for file names
- One class per file (except related classes)

### Classes
- `PascalCase` for class names
- `RepositoryImpl` for repository implementations
- `Notifier` for state notifiers

### Variables
- `camelCase` for variables and functions
- `_privateVariable` for private members
- `kConstant` for constants

### Providers
- `featureProvider` for main providers
- `featureNotifierProvider` for state notifiers
- `featureFamilyProvider` for family providers

## Folder Structure Summary

```
lib/
├── config/                    # Configuration & constants
│   ├── app_config.dart
│   ├── environment.dart
│   ├── constants.dart
│   └── providers/            # Global providers (Phase 7)
├── core/                      # Shared infrastructure
│   ├── error/
│   ├── logging/
│   ├── network/
│   ├── storage/
│   └── utils/
├── features/                  # Feature modules
│   ├── auth/
│   ├── dashboard/
│   ├── clients/
│   ├── orders/
│   ├── designs/
│   ├── marketplace/
│   ├── apprenticeship/
│   ├── chat/
│   ├── profile/
│   └── analytics/
├── l10n/                      # Localization
├── theme/                     # Design system
└── main.dart                  # Entry point

test/
├── core/
├── features/
└── fixtures/
```

## Development Workflow

1. **Create Feature**
   - Create feature folder in `lib/features/`
   - Create data, domain, presentation subfolders

2. **Define Domain**
   - Create entities
   - Create repository interfaces
   - Create usecases

3. **Implement Data**
   - Create models
   - Create datasources
   - Implement repositories

4. **Build Presentation**
   - Create providers
   - Create widgets
   - Create pages

5. **Test**
   - Write unit tests
   - Write widget tests
   - Test integration

6. **Document**
   - Add comments
   - Update README
   - Document API

## Best Practices

1. **Dependency Injection**
   - Always use Riverpod for DI
   - Never use service locators
   - Avoid global state

2. **Error Handling**
   - Use custom exceptions
   - Map to failures
   - Provide user-friendly messages

3. **State Management**
   - Use appropriate provider types
   - Invalidate cache when needed
   - Handle loading/error states

4. **Testing**
   - Test each layer independently
   - Mock external dependencies
   - Aim for > 70% coverage

5. **Code Quality**
   - Follow naming conventions
   - Keep functions small
   - Document complex logic
   - Use type safety

6. **Performance**
   - Cache data appropriately
   - Use const constructors
   - Avoid rebuilds
   - Profile regularly

## Resources

- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Riverpod Documentation](https://riverpod.dev)
- [Flutter Best Practices](https://flutter.dev/docs/testing/best-practices)
- [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
