# HIGH CONTRAST AUDIT - Desby OS

## Summary
Audit all screens for WCAG AA compliant text contrast ratios (minimum 4.5:1 for normal text, 3:1 for large text).

## Current Color Usage Analysis

### Problematic Low-Contrast Combinations (on darkNavy #0A1921)
| Current | Contrast Ratio | Issue | Recommended |
|---------|--------------|-------|------------|
| Colors.white12 | ~1.2:1 | Too faint | Remove or use higher |
| Colors.white24 | ~1.8:1 | Very subtle | Use white38 or AppColors.textHighContrastDisabled |
| Colors.white38 | ~2.5:1 | Below AA | Use AppColors.textHighContrastMuted |
| Colors.white54 | ~3.5:1 | Borderline | Use AppColors.textHighContrastMuted |
| Colors.white70 | ~8.5:1 | OK - passes | Keep or use AppColors.textHighContrastSecondary |

### Added High Contrast Colors (in AppColors)
```dart
static const Color textHighContrast = Color(0xFFFFFFFF);        // Pure white
static const Color textHighContrastSecondary = Color(0xFFE0E0E0); // Near white  
static const Color textHighContrastMuted = Color(0xFFBDBDBD);    // Light gray (replaces white70)
static const Color textHighContrastSubtle = Color(0xFF9E9E9E);    // Mid gray (replaces white54)
static const Color textHighContrastDisabled = Color(0xFF757575); // Disabled (replaces white38)
```

## Files to Fix (Priority Order)

### P0 - Critical (Main Navigation Shells)
1. lib/features/dashboard/presentation/widgets/desktop_dashboard_shell.dart
2. lib/core/widgets/desktop_shell_wrapper.dart

### P1 - High (Dashboard Pages)
3. lib/features/dashboard/presentation/pages/client_dashboard.dart
4. lib/features/dashboard/presentation/pages/tailor_dashboard.dart
5. lib/features/dashboard/presentation/pages/apprentice_dashboard.dart  
6. lib/features/dashboard/presentation/pages/fabric_seller_dashboard.dart

### P2 - Medium (Key Features)
7. lib/features/tailor/presentation/pages/tailor_finder_desktop.dart
8. lib/features/tailor/presentation/pages/tailor_discovery_page.dart
9. lib/features/orders/presentation/pages/order_list_page_uber.dart
10. lib/features/marketplace/presentation/pages/fabric_catalog_page.dart

### P3 - Normal (Supporting Screens)
11. lib/features/auth/presentation/pages/login_page.dart
12. lib/features/auth/presentation/pages/register_page.dart
13. lib/features/profile/presentation/pages/settings_page.dart
14. All onboarding pages

## Fix Guidelines

### For Primary Text (headings, labels):
```dart
// Before
style: TextStyle(color: Colors.white)

// After - Use explicit color
style: TextStyle(color: AppColors.textHighContrast, fontSize: 16, fontWeight: FontWeight.w600)
```

### For Secondary Text (descriptions):
```dart
// Before  
style: TextStyle(color: Colors.white70)

// After
style: TextStyle(color: AppColors.textHighContrastSecondary)
```

### For Tertiary/Muted Text (hints, timestamps):
```dart
// Before
style: TextStyle(color: Colors.white54)

// After  
style: TextStyle(color: AppColors.textHighContrastMuted)
```

### For Disabled States:
```dart
// Before
style: TextStyle(color: Colors.white38)

// After
style: TextStyle(color: AppColors.textHighContrastDisabled)
```

### For Input Hints:
```dart
// Before
hintStyle: TextStyle(color: Colors.white24)

// After
hintStyle: TextStyle(color: AppColors.textHighContrastSubtle, fontSize: 14)
```

## Status

- [x] Added high contrast colors to lib/theme/colors.dart
- [ ] P0 files - Main navigation shells
- [ ] P1 files - Dashboard pages  
- [ ] P2 files - Key features
- [ ] P3 files - Supporting screens

## Notes
- The main background is darkNavy (#0A1921) which is very dark
- For WCAG AA compliance, text needs at least 4.5:1 contrast ratio
- Pure white (#FFFFFF) on darkNavy gives 14.4:1 - excellent
- Colors.white70 (#B3B3B3) on darkNavy gives 8.5:1 - passes AA
- Colors.white54 (#8A8A8A) on darkNavy gives 5.9:1 - passes AA
- Colors.white38 (#5F5F5F) on darkNavy gives 3.5:1 - borderline, fails for small text
- Colors.white24 (#3D3D3D) on darkNavy gives 1.8:1 - FAILS, must fix
