# Configuration Layer

This folder contains application-wide configuration, constants, and environment setup.

## Structure

### app_config.dart
- App metadata (name, version, build number)
- Feature flags
- Environment-specific settings

### environment.dart
- Environment detection (dev, staging, production)
- Environment-specific API base URLs
- Debug/release mode configuration

### constants.dart
- App-wide constants
- Magic numbers and strings
- Configuration values

### providers/ (created in Phase 7)
- Global Riverpod providers
- App lifecycle providers
- Connectivity providers
- Device info providers

## Usage

Access configuration via:
```dart
import 'package:desby_app/config/app_config.dart';

final appName = AppConfig.appName;
final version = AppConfig.version;
```

## Environment Variables

Configuration is loaded from `.env` file via `flutter_dotenv`:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

final apiUrl = dotenv.env['API_BASE_URL'];
```

## Guidelines

- Keep configuration centralized
- Use environment variables for sensitive data
- Document all configuration options
- Never hardcode API URLs or credentials
