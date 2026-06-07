# Tailor Finder Data Fetching Fix Plan

## Issue Summary
The Tailor Finder is not showing tailor cards because data is not being fetched from Firestore properly or the filtering logic is too strict.

## Data Flow Understanding

### 1. Data Provider Chain:
- `tailorsFromFirestoreProvider` → `FirebaseAuthRepository.getTailors()` 
- Query: Firestore `users` collection where `userType == 'tailor'`

### 2. In TailorFinderNotifier.loadNearbyTailors():
- Fetch from `tailorsFromFirestoreProvider`
- Apply filters via `_applyFilters()`
- Sort by distance
- Update state with filtered tailors

### 3. The Mock Data Method:
- `_getMockTailors()` exists in the class but is NEVER called!
- This method should be removed as per task

## Files to Edit

### Primary File: `lib/features/tailor/presentation/providers/tailor_finder_provider.dart`

### Changes Required:
1. **Remove the unused `_getMockTailors()` method** (lines ~380-430)
2. **Fix the filtering logic** in `_applyFilters()` to not filter out tailors with missing/zero pricing
3. **Update TailorMarker.fromMap()** to handle missing fields gracefully

## Step Plan

- [x] 1. Remove unused `_getMockTailors()` method
- [x] 2. Fix `_applyFilters()` to show tailors even without pricing
- [x] 3. Fix `TailorMarker.fromMap()` to use defaults for missing fields
- [x] 4. Verify data fetching works properly

## Changes Made

1. **Removed `_getMockTailors()` method** - Deleted the unused mock data method completely
2. **Fixed `_applyFilters()`** - Now allows tailors with pricing = 0 to be displayed (new tailors without pricing setup)
3. **Fixed `TailorMarker.fromMap()`** - Default price to 5000 instead of 0 for new tailors

## Expected Result After Fix
- No mock data is used
- Live Firestore data is fetched and displayed
- Tailors with incomplete profiles (no pricing, no GPS) are shown with defaults
- Filters don't filter out valid tailors
