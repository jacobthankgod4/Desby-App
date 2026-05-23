# Theme & Design System

This folder contains the complete design system for Desby OS, including colors, typography, spacing, and theme configuration.

## Structure

### app_theme.dart
- Material Design 3 theme configuration
- Light theme definition
- Dark theme definition
- Theme provider (Riverpod)

### colors.dart
- Primary color palette
- Secondary colors
- Accent colors
- Semantic colors (success, warning, error)
- Neutral colors (grays, blacks, whites)

### typography.dart
- Font families
- Text styles hierarchy (headline, body, caption, button)
- Font weights and sizes
- Line heights and letter spacing

### spacing.dart
- 8px grid system constants
- Padding/margin values
- Border radius values
- Gap/spacing utilities

### shadows.dart
- Elevation system
- Shadow definitions for different levels
- Material Design 3 shadow specifications

## Usage

Access theme values via:
```dart
import 'package:desby_app/theme/colors.dart';
import 'package:desby_app/theme/typography.dart';

final primaryColor = AppColors.primary;
final headlineStyle = AppTypography.headline1;
```

Use theme in widgets:
```dart
Container(
  color: Theme.of(context).colorScheme.primary,
  child: Text(
    'Hello',
    style: Theme.of(context).textTheme.headlineMedium,
  ),
)
```

## Color Palette

- **Primary**: Deep Plum (#6B4C8A) - Professional, fashion-forward
- **Secondary**: Gold/Champagne (#D4A574) - Luxury, elegance
- **Accent**: Teal/Emerald (#2A9D8F) - Modern, trustworthy
- **Neutral**: Dark grays/blacks with warm undertones
- **Semantic**: Green (success), Amber (warning), Red (error)

## Typography Hierarchy

- **Headline1**: 32px, Bold - Page titles
- **Headline2**: 28px, Bold - Section titles
- **Headline3**: 24px, SemiBold - Subsection titles
- **Body1**: 16px, Regular - Main content
- **Body2**: 14px, Regular - Secondary content
- **Caption**: 12px, Regular - Helper text
- **Button**: 14px, SemiBold - Button labels

## Guidelines

- Use theme colors instead of hardcoding colors
- Follow typography hierarchy for consistency
- Use 8px grid for spacing
- Test colors for WCAG AA accessibility
- Support both light and dark modes
