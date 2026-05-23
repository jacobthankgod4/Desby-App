# Localization (l10n)

This folder contains localization files for multi-language support.

## Structure

### app_en.arb
- English translations (base language)
- All translation keys defined here first

### app_es.arb
- Spanish translations

### app_fr.arb (future)
- French translations

### app_de.arb (future)
- German translations

## ARB Format

ARB (Application Resource Bundle) is a JSON-based format for localization.

Example `app_en.arb`:
```json
{
  "appTitle": "Desby OS",
  "appDescription": "Digital operating system for tailors",
  "loginTitle": "Login",
  "loginEmail": "Email",
  "loginPassword": "Password",
  "loginButton": "Sign In",
  "errorInvalidEmail": "Please enter a valid email",
  "errorPasswordTooShort": "Password must be at least 8 characters"
}
```

## Usage

In Flutter code:
```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Text(l10n.appTitle);
  }
}
```

## Setup

1. Add to `pubspec.yaml`:
```yaml
flutter:
  generate: true
```

2. Create `l10n.yaml`:
```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

3. Run code generation:
```bash
flutter gen-l10n
```

## Guidelines

- Keep keys descriptive and hierarchical
- Use English as base language
- Translate all keys in all languages
- Test all languages before release
- Use placeholders for dynamic content: `{name}`
- Document complex translations
