# TODO: Tailor Post-Registration Onboarding Implementation

## Task: Implement mandatory tailor onboarding after registration
Based on the feedback: "they cannot skip the post sign up onboarding questions to fill them up later"

---

## Implementation Plan

### Information Gathered:
1. **Current Registration Flow**: register_page.dart calls authStateProvider.notifier.register() - after registration there's an incorrect navigation to /login (should be dashboard)
2. **UserProfile Entity**: lib/features/profile/domain/entities/user_profile.dart - missing services and working hours fields
3. **Storage Keys**: lib/core/storage/storage_keys.dart - need new key for tracking onboarding completion
4. **Apprentice Onboarding**: Reference at lib/features/apprenticeship/presentation/pages/apprentice_onboarding_page.dart - multi-step PageView pattern
5. **Profile Updates**: Available via updateProfileUsecaseProvider

---

## Detailed Steps:

### Step 1: Add Storage Key (lib/core/storage/storage_keys.dart)
- Add: `static const String tailorOnboardingComplete = 'tailor_onboarding_complete';`

### Step 2: Extend UserProfile Entity (lib/features/profile/domain/entities/user_profile.dart)
Add new fields:
- `services` (List<String>) - services offered (Alteration, Zig-Zag Work, Stitching, Hemming, Embroidery)
- `workingHours` (String?) - business hours string
- `locationEnabled` (bool) - for location services
- `latitude/longitude` (double?) - for map location

### Step 3: Create TailorOnboardingPage (NEW FILE)
Location: lib/features/tailor/presentation/pages/tailor_onboarding_page.dart

Steps:
1. **Services Selection** - multi-select chips for services
2. **Business Details** - business name, phone, address
3. **Working Hours** - time picker for open/close times
4. **Location** - address input (skip map for MVP)
5. **Confirmation** - review and save

Features:
- PageView with step indicators
- Validation per step (cannot skip)
- Save to UserProfile via updateProfileUsecaseProvider
- Mark onboarding complete in localStorage
- Navigate to dashboard on finish

### Step 4: Update Register Page (lib/features/auth/presentation/pages/register_page.dart)
Fix navigation after registration:
- For tailor: navigate to /tailor-onboarding
- For others: navigate to /home

### Step 5: Register Route in main.dart
Add: '/tailor-onboarding': (context) => const TailorOnboardingPage()

### Step 6: Update AuthState to include hasCompletedOnboarding check
On app start, check:
- If userType == tailor AND tailorOnboardingComplete != true → force navigate to tailor onboarding

---

## Pre-Requisites:
- Need profile_provider for updateProfileUsecaseProvider (already available)
- Need localStorage for storage key

## Followup Steps After Implementation:
1. Test registration flow for tailor
2. Verify onboarding blocks access until complete
3. Test that services are saved to UserProfile
