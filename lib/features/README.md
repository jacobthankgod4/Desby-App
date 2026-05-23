# Features Layer

This folder contains all feature modules organized by business domain. Each feature follows clean architecture with three layers: data, domain, and presentation.

## Feature Structure

Each feature (e.g., `auth/`, `clients/`, `orders/`) contains:

```
feature/
├── data/
│   ├── datasources/
│   │   ├── local_datasource.dart
│   │   └── remote_datasource.dart
│   ├── models/
│   │   └── model_name.dart (with @freezed)
│   └── repositories/
│       └── repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── entity_name.dart
│   ├── repositories/
│   │   └── repository.dart (abstract)
│   └── usecases/
│       └── usecase_name.dart
└── presentation/
    ├── pages/
    │   └── page_name.dart
    ├── widgets/
    │   └── widget_name.dart
    ├── providers/
    │   └── feature_provider.dart (Riverpod)
    └── state/
        └── feature_state.dart (if needed)
```

## Layers Explained

### Data Layer
- **Datasources**: Fetch data from API (remote) or local storage
- **Models**: JSON-serializable data classes (use @freezed)
- **Repositories**: Implement abstract repository interfaces

### Domain Layer
- **Entities**: Pure business logic models (no serialization)
- **Repositories**: Abstract interfaces defining data contracts
- **Usecases**: Business logic operations (one per operation)

### Presentation Layer
- **Pages**: Full-screen widgets
- **Widgets**: Reusable UI components
- **Providers**: Riverpod providers for state management
- **State**: State classes (if using StateNotifier)

## Available Features

1. **auth/** - Authentication and authorization
2. **dashboard/** - Home/dashboard screens
3. **clients/** - Client management
4. **orders/** - Order management
5. **designs/** - Design gallery and measurements
6. **marketplace/** - Fabric marketplace
7. **apprenticeship/** - Apprentice management
8. **chat/** - Messaging and chat
9. **profile/** - User profile and settings
10. **analytics/** - Analytics and reporting

## Example: Creating a Feature

### 1. Create Entity (domain/entities/)
```dart
class User {
  final String id;
  final String name;
  final String email;
  
  User({required this.id, required this.name, required this.email});
}
```

### 2. Create Repository Interface (domain/repositories/)
```dart
abstract class UserRepository {
  Future<User> getUser(String id);
  Future<void> updateUser(User user);
}
```

### 3. Create Model (data/models/)
```dart
@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String name,
    required String email,
  }) = _UserModel;
  
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
```

### 4. Create Datasources (data/datasources/)
```dart
abstract class UserRemoteDatasource {
  Future<UserModel> getUser(String id);
}

class UserRemoteDatasourceImpl implements UserRemoteDatasource {
  final Dio dio;
  
  @override
  Future<UserModel> getUser(String id) async {
    final response = await dio.get('/users/$id');
    return UserModel.fromJson(response.data);
  }
}
```

### 5. Create Repository Implementation (data/repositories/)
```dart
class UserRepositoryImpl implements UserRepository {
  final UserRemoteDatasource remoteDatasource;
  
  @override
  Future<User> getUser(String id) async {
    final model = await remoteDatasource.getUser(id);
    return User(id: model.id, name: model.name, email: model.email);
  }
}
```

### 6. Create Usecase (domain/usecases/)
```dart
class GetUserUsecase {
  final UserRepository repository;
  
  GetUserUsecase(this.repository);
  
  Future<User> call(String id) => repository.getUser(id);
}
```

### 7. Create Provider (presentation/providers/)
```dart
final userProvider = FutureProvider.family<User, String>((ref, id) async {
  final usecase = GetUserUsecase(ref.watch(userRepositoryProvider));
  return usecase(id);
});
```

### 8. Create Page (presentation/pages/)
```dart
class UserPage extends ConsumerWidget {
  final String userId;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider(userId));
    
    return userAsync.when(
      data: (user) => UserView(user: user),
      loading: () => const LoadingWidget(),
      error: (err, stack) => ErrorWidget(error: err),
    );
  }
}
```

## Guidelines

- Keep layers separate and independent
- Use dependency injection via Riverpod
- Entities should not depend on models
- Repositories are the only bridge between layers
- Usecases encapsulate business logic
- Providers manage state and side effects
- Test each layer independently
