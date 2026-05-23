# Coding Standards - Desby OS

## Overview
This document defines the coding standards and best practices for the Desby OS project.

## File Organization

### Naming Conventions
- **Files**: `snake_case.dart` (e.g., `user_repository.dart`)
- **Classes**: `PascalCase` (e.g., `UserRepository`)
- **Functions/Methods**: `camelCase` (e.g., `getUserById()`)
- **Variables**: `camelCase` (e.g., `userName`)
- **Constants**: `camelCase` (e.g., `maxRetries`)
- **Private members**: `_camelCase` (e.g., `_internalValue`)

### File Structure
```dart
// 1. Imports (organized)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/logging/logger.dart';
import 'models/user.dart';

// 2. Constants
const int maxRetries = 3;

// 3. Main class/function
class UserRepository {
  // ...
}

// 4. Helper classes (if needed)
class _UserHelper {
  // ...
}
```

## Import Organization

Order imports as follows:
1. Dart imports (`dart:*`)
2. Flutter imports (`package:flutter/*`)
3. Package imports (alphabetical)
4. Relative imports (alphabetical)

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../core/logging/logger.dart';
import 'models/user.dart';
```

## Code Style

### Formatting
- Use 2-space indentation
- Line length: 80 characters (soft limit), 120 characters (hard limit)
- Use `const` constructors whenever possible
- Use `final` for variables that don't change

### Null Safety
- Always use non-nullable types by default
- Use `?` only when null is a valid value
- Use `!` sparingly and only when you're certain

```dart
// Good
String name = 'John';
String? nickname;

// Avoid
String? name = 'John'; // Unnecessary nullable
String nickname = null; // Compile error
```

### Type Annotations
- Always specify types explicitly
- Use type inference only for obvious cases

```dart
// Good
final List<String> names = ['Alice', 'Bob'];
final user = User.fromJson(json); // Type is obvious

// Avoid
var names = ['Alice', 'Bob']; // Type not obvious
final List<String> user = User.fromJson(json); // Redundant
```

### Comments

#### Documentation Comments
Use `///` for public APIs:

```dart
/// Fetches a user by ID.
///
/// Returns the user if found, otherwise throws [UserNotFoundException].
///
/// Example:
/// ```dart
/// final user = await repository.getUserById('123');
/// ```
Future<User> getUserById(String id) async {
  // ...
}
```

#### Implementation Comments
Use `//` for implementation details:

```dart
// Check if user is authenticated
if (isAuthenticated) {
  // ...
}
```

#### Block Comments
Use `/* */` for multi-line comments:

```dart
/*
 * This is a complex algorithm that:
 * 1. Validates input
 * 2. Processes data
 * 3. Returns result
 */
```

## Dart/Flutter Best Practices

### Use Const Constructors
```dart
// Good
const SizedBox(height: 16);
const EdgeInsets.all(8);

// Avoid
SizedBox(height: 16);
EdgeInsets.all(8);
```

### Use Sealed Classes for Type Safety
```dart
// Good
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final String error;
  const Failure(this.error);
}

// Usage
final result = switch (response) {
  Success(:final data) => data,
  Failure(:final error) => throw Exception(error),
};
```

### Use Extension Methods
```dart
// Good
extension StringExtension on String {
  bool get isValidEmail => contains('@');
}

// Usage
if (email.isValidEmail) { }

// Avoid
if (isValidEmail(email)) { }
```

### Avoid Nested Ternary Operators
```dart
// Good
final status = switch (code) {
  200 => 'Success',
  400 => 'Bad Request',
  401 => 'Unauthorized',
  _ => 'Unknown',
};

// Avoid
final status = code == 200 ? 'Success' : code == 400 ? 'Bad Request' : 'Unknown';
```

## Riverpod Guidelines

### Provider Naming
- `featureProvider` - Main provider
- `featureNotifierProvider` - StateNotifier provider
- `featureFamilyProvider` - Family provider
- `featureListProvider` - List provider

```dart
// Good
final userProvider = FutureProvider<User>((ref) async {
  return await ref.watch(userRepositoryProvider).getUser();
});

final usersListProvider = FutureProvider<List<User>>((ref) async {
  return await ref.watch(userRepositoryProvider).getUsers();
});

final userFamilyProvider = FutureProvider.family<User, String>((ref, id) async {
  return await ref.watch(userRepositoryProvider).getUserById(id);
});
```

### Provider Dependencies
```dart
// Good - Clear dependencies
final userProvider = FutureProvider<User>((ref) async {
  final repository = ref.watch(userRepositoryProvider);
  final logger = ref.watch(loggerProvider);
  
  logger.info('Fetching user');
  return await repository.getUser();
});

// Avoid - Implicit dependencies
final userProvider = FutureProvider<User>((ref) async {
  return await userRepository.getUser(); // Where does userRepository come from?
});
```

## Error Handling

### Use Custom Exceptions
```dart
// Good
try {
  final user = await repository.getUser(id);
} on UserNotFoundException catch (e) {
  logger.error('User not found', error: e);
} on NetworkException catch (e) {
  logger.error('Network error', error: e);
}

// Avoid
try {
  final user = await repository.getUser(id);
} catch (e) {
  print('Error: $e'); // Generic error handling
}
```

### Use Result Pattern
```dart
// Good
final result = await repository.getUser(id);
final user = result.fold(
  (failure) => null,
  (user) => user,
);

// Avoid
try {
  final user = await repository.getUser(id);
} catch (e) {
  // Handle error
}
```

## Testing

### Test File Naming
- `feature_test.dart` for unit tests
- `feature_widget_test.dart` for widget tests
- `feature_integration_test.dart` for integration tests

### Test Structure
```dart
void main() {
  group('FeatureName', () {
    group('method name', () {
      test('should do something', () {
        // Arrange
        final input = 'test';
        
        // Act
        final result = function(input);
        
        // Assert
        expect(result, 'expected');
      });
    });
  });
}
```

### Test Coverage
- Aim for > 70% code coverage
- Test happy paths and error cases
- Test edge cases

## Performance

### Avoid Rebuilds
```dart
// Good - Const widget
class MyWidget extends StatelessWidget {
  const MyWidget({super.key});
  
  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 16);
  }
}

// Avoid - Unnecessary rebuilds
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 16);
  }
}
```

### Use Lazy Loading
```dart
// Good
final expensiveProvider = FutureProvider<Data>((ref) async {
  return await fetchExpensiveData();
});

// Avoid
final expensiveData = await fetchExpensiveData(); // Loaded immediately
```

## Security

### Never Hardcode Secrets
```dart
// Good
final apiKey = dotenv.env['API_KEY'];

// Avoid
const apiKey = 'sk_live_abc123'; // Hardcoded secret
```

### Use Secure Storage
```dart
// Good
await secureStorage.saveAccessToken(token);

// Avoid
await localStorage.saveAccessToken(token); // Unencrypted
```

## Documentation

### README Requirements
- Project description
- Setup instructions
- Architecture overview
- Contributing guidelines

### Code Comments
- Explain "why", not "what"
- Keep comments up-to-date
- Remove commented-out code

## Git Commit Messages

### Format
```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Code style
- `refactor`: Code refactoring
- `test`: Test changes
- `chore`: Build/dependency changes

### Example
```
feat(auth): add two-factor authentication

- Implement TOTP-based 2FA
- Add 2FA setup screen
- Add 2FA verification during login

Closes #123
```

## Code Review Checklist

- [ ] Code follows naming conventions
- [ ] Code is properly formatted
- [ ] Comments are clear and helpful
- [ ] No hardcoded values
- [ ] Error handling is appropriate
- [ ] Tests are included
- [ ] Documentation is updated
- [ ] No performance issues
- [ ] Security best practices followed
- [ ] No breaking changes

## Tools

### Linting
```bash
flutter analyze
```

### Formatting
```bash
dart format .
```

### Testing
```bash
flutter test
```

### Code Generation
```bash
flutter pub run build_runner build
```

## Resources

- [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- [Flutter Best Practices](https://flutter.dev/docs/testing/best-practices)
- [Riverpod Documentation](https://riverpod.dev)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
