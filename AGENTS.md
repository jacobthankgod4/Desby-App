# Desby OS - AI Agent Instructions

## Project Overview
Desby OS is a Flutter-based digital operating system for tailors and fashion entrepreneurs. It follows Clean Architecture with Riverpod for state management.

## Key Technologies
- **Framework**: Flutter (Dart SDK ^3.11.5)
- **State Management**: Riverpod
- **Architecture**: Clean Architecture (Presentation → Domain → Data)
- **Code Generation**: Freezed, Riverpod Generator, JSON Serializable
- **Local Storage**: Hive, SharedPreferences
- **Networking**: Dio
- **Firebase**: Auth, Firestore, Storage
- **Payments**: Paystack

## Project Structure
```
lib/
├── config/          # App configuration and constants
├── core/            # Shared infrastructure (error, logging, network, storage, utils)
├── features/        # Feature modules (auth, dashboard, clients, orders, etc.)
├── theme/           # Design system (colors, typography, spacing)
└── main.dart        # Entry point
```

## Development Commands
```bash
# Run the app
flutter run

# Run tests
flutter test

# Run code generation
flutter pub run build_runner build --delete-conflicting-outputs

# Analyze code
flutter analyze

# Format code
dart format .

# Run specific test
flutter test test/path/to/file_test.dart
```

## Coding Conventions
- Files: `snake_case.dart`
- Classes: `PascalCase`
- Functions/Variables: `camelCase`
- Constants: `camelCase` (not UPPER_SNAKE_CASE)
- 2-space indentation
- Always use `const` constructors when possible
- Always use `final` for immutable variables
- Use non-nullable types by default
- Organize imports: Dart → Flutter → Packages → Relative

## Architecture Guidelines
1. **Presentation Layer**: Pages, Widgets, Providers (Riverpod)
2. **Domain Layer**: Entities, Repository interfaces, Usecases (pure Dart)
3. **Data Layer**: Models, Datasources, Repository implementations

## When Making Changes
1. Follow the existing feature module structure
2. Keep business logic in the domain layer
3. Use Riverpod providers for dependency injection
4. Write tests for new functionality
5. Run `flutter analyze` and `dart format .` before committing
6. Follow the commit message format: `type(scope): description`

## Important Notes
- Never hardcode secrets; use `.env` files with `flutter_dotenv`
- Use `flutter_secure_storage` for sensitive data
- Prefer const constructors for performance
- Use sealed classes for type safety where appropriate
- Keep widgets small and focused
