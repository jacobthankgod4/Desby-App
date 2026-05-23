# Find Tailor Screen Enhancement Plan

## Task Overview
Enhance the Find Tailor (TailorDiscoveryPage) screen with:
1. ✅ Functional cart icon - navigate to booking cart
2. Complete fabric types - from tailor's available fabrics
3. ✅ Functional rating cards - show tailor ratings
4. ✅ Functional chart cards - show order statistics
5. ✅ Location filtering - State + LGA selection
6. ✅ Proximity sorting - show tailors closest to user

---

## Feature Plan

### 1. Cart Icon Navigation
**Current State**: Icon exists but no navigation/action
**Fix**: Add navigation to booking cart page
- Add to appBar actions in TailorDiscoveryPage
- Navigate to `/booking-cart`

### 2. Fabric Types from Tailor
**Current State**: Not implemented
**Implementation**:
- Add `availableFabrics` field to UserProfile entity
- Add fabric selection in tailor onboarding
- Fetch tailor's fabrics from their profile
- Display in tailor card/preview

### 3. Rating Cards (Functional)
**Current State**: Static display
**Implementation**:
- Fetch actual ratings from Firebase
- Show: average rating, total reviews, breakdown
- Make interactive (tap to see reviews)

### 4. Chart Cards (Functional)  
**Current State**: Static display
**Implementation**:
- Fetch order statistics from Firebase
- Show: completed orders, pending, revenue chart
- Make interactive (tap for details)

### 5. Location Filter (State + LGA)
**Current State**: No filtering
**Implementation**:
- Add filter button in appBar
- Show modal with NigeriaLgaData states
- Filter tailors by state/location field only

### 6. Proximity Sorting
**Current State**: No sorting
**Implementation**:
- Get user's current location
- Calculate distance to each tailor
- Sort by distance (nearest first)
- Show distance on tailor card

---

## Files to Modify

1. `lib/features/tailor/presentation/pages/tailor_discovery_page.dart` - Main UI
2. `lib/features/profile/domain/entities/user_profile.dart` - Add fabrics field
3. `lib/features/orders/presentation/providers/order_provider.dart` - Add cart provider
4. `lib/core/constants/nigeria_lga_data.dart` - Already exists

---

## Implementation Steps

### Step 1: Add Cart Navigation
```dart
// In TailorDiscoveryPage appBar actions
actions: [
  IconButton(
    icon: const Icon(Icons.shopping_cart),
    onPressed: () => Navigator.pushNamed(context, '/booking-cart'),
  ),
]
```

### Step 2: Add Location Filter
- Add state/lga filter state variables
- Add filter dropdowns modal
- Filter tailors by location field

### Step 3: Add Proximity Sorting
- Add location service
- Calculate distances
- Sort by distance

### Step 4: Enhance Tailor Card
- Add fabrics display
- Add rating widget (interactive)
- Add stats widget (interactive)
- Add distance display

---

## User Experience

1. User opens Find Tailor screen
2. Can filter by State → LGA
3. Sees tailors sorted by proximity
4. Each tailor card shows:
   - Name, location, distance
   - Rating (tap for reviews)
   - Stats (tap for details)
   - Available fabrics
5. Tap cart icon → go to booking cart
6. Select tailor → continue booking

---

## Status: PLANNING PHASE

Awaiting user approval to proceed with implementation.
