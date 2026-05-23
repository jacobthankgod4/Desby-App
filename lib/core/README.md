# Core Infrastructure Layer

This folder contains all shared infrastructure and utilities used across the application.

## Structure

### error/
- **exceptions.dart** - Custom exception hierarchy
- **failures.dart** - Failure types and Result pattern
- **error_handler.dart** - Error mapping utilities

### logging/
- **logger.dart** - Structured logging service with multiple outputs

### network/
- **dio_client.dart** - Dio HTTP client configuration
- **interceptors.dart** - Custom request/response interceptors
- **api_endpoints.dart** - Centralized API route constants

### storage/
- **local_storage.dart** - Hive local database abstraction
- **secure_storage.dart** - Secure token storage abstraction
- **storage_keys.dart** - Storage key constants

### utils/
- **extensions.dart** - Dart/Flutter extension methods
- **validators.dart** - Input validation utilities

## Usage

All core services are provided via Riverpod providers in `lib/config/providers/`.

Example:
```dart
final dioProvider = Provider((ref) => DioClient().dio);
final loggerProvider = Provider((ref) => Logger());
```

## Guidelines

- Keep core services stateless and reusable
- Use dependency injection via Riverpod
- Document all public APIs
- Add tests for all utilities
