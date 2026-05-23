# Authentication & Onboarding Fixes TODO

## Priority 1: CRITICAL ISSUES ✅ COMPLETED

✅ 1. Add email validation to LoginPage - DONE!
✅ 2. Add email validation to RegisterPage - DONE!
✅ 3. Implement actual Firebase password reset - DONE!
✅ 4. Add password strength validation to RegisterPage - DONE!
✅ 5. Add password minimum length (8 chars) validation - DONE!

## Priority 2: MODERATE IMPROVEMENTS ✅ COMPLETED

✅ 6. Add strict validation for onboarding step transitions - DONE!
✅ 7. Add re-onboarding capability from profile settings - DONE!

## Priority 3: NICE TO HAVE ✅ COMPLETED

✅ 8. Make Terms & Conditions clickable link - DONE!

## Files Modified:

1. `/lib/core/utils/validators.dart` (NEW) - All validation utilities
2. `/lib/features/auth/presentation/pages/login_page.dart` - Email validation
3. `/lib/features/auth/presentation/pages/register_page.dart` - Email + password strength + validation + terms link
4. `/lib/features/auth/presentation/pages/forgot_password_page.dart` - Real Firebase reset
5. `/lib/features/profile/presentation/pages/settings_page.dart` - Re-onboarding capability
