# Development Guide - Desby OS

## Prerequisites

- Flutter SDK 3.11.5+
- Dart 3.11.5+
- Android Studio or Xcode
- Git

## Initial Setup

### 1. Clone Repository
```bash
git clone https://github.com/desby/desby-app.git
cd desby-app
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Setup Environment
```bash
cp .env.example .env
# Edit .env with your configuration
```

### 4. Generate Code
```bash
flutter pub run build_runner build
```

### 5. Run App
```bash
flutter run
```

## Development Workflow

### Creating a New Feature

1. **Create Feature Branch**
```bash
git checkout -b feat/feature-name
```

2. **Create Feature Structure**
```
lib/features/feature_name/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── pages/
    ├── widgets/
    ├── providers/
    └── state/
```

3. **Implement Domain Layer**
- Create entities
- Create repository interfaces
- Create usecases

4. **Implement Data Layer**
- Create models
- Create datasources
- Implement repositories

5. **Implement Presentation Layer**
- Create providers
- Create widgets
- Create pages

6. **Write Tests**
```bash
flutter test test/features/feature_name/
```

7. **Commit Changes**
```bash
git add .
git commit -m "feat(feature_name): add new feature"
git push origin feat/feature-name
```

8. **Create Pull Request**
- Describe changes
- Link related issues
- Request review

## Common Commands

### Code Generation
```bash
# Build once
flutter pub run build_runner build

# Watch for changes
flutter pub run build_runner watch

# Clean and rebuild
flutter pub run build_runner clean
flutter pub run build_runner build
```

### Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/core/error/error_handler_test.dart

# Run with coverage
flutter test --coverage

# View coverage report
open coverage/index.html
```

### Code Quality
```bash
# Analyze code
flutter analyze

# Format code
dart format .

# Check formatting
dart format --set-exit-if-changed .
```

### Building

#### Android
```bash
# Debug build
flutter build apk --debug

# Release build
flutter build apk --release

# App bundle
flutter build appbundle --release
```

#### iOS
```bash
# Debug build
flutter build ios --debug

# Release build
flutter build ios --release
```

#### Web
```bash
# Build web
flutter build web

# Serve locally
flutter run -d web-server
```

#### macOS
```bash
# Build macOS
flutter build macos --release
```

## Debugging

### Debug Mode
```bash
flutter run
# Press 'w' for widget inspector
# Press 'p' for performance overlay
# Press 'q' to quit
```

### Logging
```dart
import 'package:desby_app/core/logging/logger.dart';

logger.debug('Debug message');
logger.info('Info message');
logger.warning('Warning message');
logger.error('Error message', error: exception);
logger.fatal('Fatal message', error: exception);
```

### DevTools
```bash
flutter pub global activate devtools
devtools
```

## Hot Reload vs Hot Restart

### Hot Reload (Faster)
- Preserves app state
- Updates code
- Press 'r' in terminal

### Hot Restart (Slower)
- Restarts app
- Clears state
- Press 'R' in terminal

## Database

### Hive
```dart
// Initialize
await localStorage.initialize();

// Save data
await localStorage.saveCachedData('key', data);

// Get data
final data = localStorage.getCachedData('key');

// Clear
await localStorage.clearCacheBox();
```

### Secure Storage
```dart
// Save token
await secureStorage.saveAccessToken(token);

// Get token
final token = await secureStorage.getAccessToken();

// Clear
await secureStorage.clearTokens();
```

## API Integration

### Making Requests
```dart
final dio = ref.watch(dioProvider);

try {
  final response = await dio.get('/users/123');
  final user = User.fromJson(response.data);
} on DioException catch (e) {
  logger.error('API error', error: e);
}
```

### Adding Interceptors
Interceptors are configured in `lib/core/network/interceptors.dart`

## State Management

### Using Providers
```dart
// Define provider
final userProvider = FutureProvider<User>((ref) async {
  return await ref.watch(userRepositoryProvider).getUser();
});

// Use in widget
class UserWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    
    return userAsync.when(
      data: (user) => Text(user.name),
      loading: () => const CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
    );
  }
}
```

### Invalidating Cache
```dart
ref.refresh(userProvider);
```

## Performance Optimization

### Profile App
```bash
flutter run --profile
```

### Memory Profiling
- Use DevTools Memory tab
- Look for memory leaks
- Check widget rebuilds

### Performance Monitoring
```dart
logger.logPerformance('operation_name', duration);
```

## Troubleshooting

### Build Issues
```bash
# Clean everything
flutter clean
rm -rf pubspec.lock
flutter pub get

# Rebuild
flutter pub run build_runner clean
flutter pub run build_runner build
```

### Dependency Conflicts
```bash
flutter pub upgrade
flutter pub get
```

### Platform-Specific Issues

#### Android
```bash
# Clear Android build
rm -rf android/.gradle
rm -rf android/build
flutter clean
flutter pub get
```

#### iOS
```bash
# Clear iOS build
rm -rf ios/Pods
rm -rf ios/Podfile.lock
flutter clean
flutter pub get
```

## Environment Variables

Edit `.env` file:
```
APP_ENV=development
API_BASE_URL=http://localhost:3000/api
API_TIMEOUT_SECONDS=30
APP_DEBUG=true
```

## Git Workflow

### Branch Naming
- `feat/feature-name` - New feature
- `fix/bug-name` - Bug fix
- `docs/doc-name` - Documentation
- `refactor/refactor-name` - Code refactoring

### Commit Messages
```
feat(auth): add login functionality
fix(ui): fix button alignment
docs(readme): update setup instructions
```

### Pull Request Process
1. Create feature branch
2. Make changes
3. Write tests
4. Update documentation
5. Create pull request
6. Address review comments
7. Merge to main

## Continuous Integration

### Pre-commit Checks
```bash
flutter analyze
dart format --set-exit-if-changed .
flutter test
```

### CI/CD Pipeline
- Automated tests on PR
- Code coverage check
- Build verification
- Deployment on merge

## Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Documentation](https://dart.dev/guides)
- [Riverpod Guide](https://riverpod.dev)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

## Support

For questions or issues:
1. Check existing documentation
2. Search GitHub issues
3. Create new issue with details
4. Contact team lead
