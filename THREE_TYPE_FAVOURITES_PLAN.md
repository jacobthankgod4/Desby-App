# Three-Type Favourites Implementation Plan

**Date:** May 26, 2026  
**Project:** Add Ready-to-Wear Garments as Third Favourite Category

---

## Executive Summary

The task involves expanding the current 2-type favourites system (fabrics + tailors) to include a third category: **Ready-to-Wear Garments** - completed garments posted by tailors that users love.

### Current State
- ✅ Fabrics Favourites (via `favorites` collection in Firestore)
- ✅ Tailors Favourites (via `tailor_favorites` collection in Firestore)
- ❌ Ready-to-Wear Garments (NOT YET IMPLEMENTED)

### Target State
- 3 Tabbed Favourites Page with: FABRICS | TAILORS | GARMENTS

---

## Architecture Overview

### Data Model: ReadyToWearGarment

```dart
class ReadyToWearGarment {
  final String id;
  final String tailorId;
  final String tailorName;
  final String imageUrl;
  final String garmentType; // e.g., "Ankara Dress", "Senator Suit"
  final String description;
  final double price;
  final List<String> tags;
  final DateTime createdAt;
  final bool isAvailable;
}
```

### Firestore Collection Structure

```
users/
  {userId}/
    favorites/
      fabricIds: List<String>
    tailor_favorites/
      tailorIds: List<String>
    garment_favorites/    // NEW
      garmentIds: List<String>
```

### Alternative: Unified Collection Approach

```
favourites/
  {userId}/
    fabrics: List<String>
    tailors: List<String>
    garments: List<String>
```

---

## Implementation Plan

### Phase 1: Data Layer (Priority: HIGH)

#### 1.1 Create Garment Model
- Create `lib/features/marketplace/domain/entities/ready_to_wear_garment.dart`
- Properties: id, tailorId, tailorName, imageUrl, garmentType, description, price, tags, createdAt, isAvailable

#### 1.2 Create Provider
- Add `garmentFavouritesProvider` in marketplace providers
- Methods: addToFavourites(), removeFromFavourites(), isFavourite()

#### 1.3 Firestore Integration
- Add methods to read/write garment IDs in `garment_favorites` subcollection
- Or extend existing `favorites` collection with `garmentIds` field

#### 1.4 Service Repository
- Add `GarmentFavouritesRepository` class similar to FabricFavouritesRepository

---

### Phase 2: Tailor Profile Updates (Priority: HIGH)

#### 2.1 Add Save Button to Tailor Profile
- Location: `lib/features/tailor/presentation/pages/tailor_profile_page.dart`
- Add favourite button next to existing action buttons (Call, WhatsApp, Share)
- Icon: `Icons.favorite_border` / `Icons.favorite`
- Action: Toggle save to `garment_favorites` collection

#### 2.2 Ready-to-Wear Section Display
- Tailor profile already has `portfolioImages` field (from tailors data)
- Display as "My Creations" or "Ready-to-Wear" carousel
- Each garment card shows save button

#### 2.3 Portfolio Image Save Feature
- Add heart icon on each portfolio image in tailor profile
- Tapping saves to user's garment favourites

---

### Phase 3: UI Layer - Favourites Page (Priority: HIGH)

#### 3.1 Update FavouritesPage
- File: `lib/features/marketplace/presentation/pages/favorites_page.dart`
- Change TabController from length: 2 to length: 3
- Add third tab: "GARMENTS" or "STYLES"

#### 3.2 Create Garment Favourites Tab
- New widget: `GarmentFavouritesTab` (similar to existing tabs)
- Stream from `garment_favorites` collection
- Display grid of saved garments

#### 3.3 Garment Card Component
- Create reusable garment card for favourites
- Properties: image, tailor name, garment type, price
- Tap navigates to detail page

#### 3.4 Empty State
- Update empty state messaging for new third category
- "NO SAVED GARMENTS" with explore CTA

---

### Phase 4: Navigation & Routing (Priority: MEDIUM)

#### 4.1 Add Route for Garment Details
- If not exists: `/garment-details` or reuse existing route
- Pass garment ID as argument

#### 4.2 Update Dashboard Navigation
- File: `lib/features/dashboard/presentation/pages/main_page.dart`
- Favourites nav item shows count badge (sum of all 3 types)

#### 4.3 Desktop Shell Integration
- File: `lib/core/widgets/desktop_shell_wrapper.dart`
- Update nav item to show combined or 3-tab view

---

### Phase 5: Edge Cases & Polish (Priority: LOW)

#### 5.1 Duplicate Prevention
- Prevent saving same garment twice
- Show snackbar: "Added to favourites" / "Already saved"

#### 5.2 Synchronization
- Sync favorites across devices if user logs in on multiple
- Use Firestore real-time streams

#### 5.3 Performance
- Use pagination for large favorite lists
- Lazy load images

#### 5.4 Accessibility
- Add semantic labels for screen readers
- Ensure proper contrast ratios

---

## File Changes Summary

### New Files to Create:

1. `lib/features/marketplace/domain/entities/ready_to_wear_garment.dart`
   - Garment entity class with all required properties

2. `lib/features/marketplace/data/repositories/garment_favourites_repository.dart`
   - Repository for CRUD operations on garment favorites

3. `lib/features/marketplace/presentation/widgets/garment_favourite_card.dart`
   - UI card widget for displaying saved garment

### Files to Modify:

4. `lib/features/marketplace/presentation/pages/favorites_page.dart`
   - Add third tab + GarmentFavouritesTab widget

5. `lib/features/tailor/presentation/pages/tailor_profile_page.dart`
   - Add save button to portfolio images

6. `lib/features/marketplace/presentation/providers/fabric_provider.dart`
   - Add garmentFavouritesProvider

---

## Implementation Sequence

### Step 1: Model & Provider (1-2 hours)
1. Create ReadyToWearGarment entity
2. Add GarmentFavouritesRepository

### Step 2: Favourites Page UI (2-3 hours)
1. Update TabController to 3 tabs
2. Create GarmentFavouritesTab widget
3. Wire up Firestore streams

### Step 3: Tailor Profile Save Buttons (1-2 hours)
1. Add save button to portfolio section
2. Wire up to Firestore write

### Step 4: Garment Details Page (2-3 hours)
1. Create garment detail view
2. Add route and navigation

---

## Total Estimated Effort: 6-10 hours

| Phase | Hours |
|-------|-------|
| Phase 1: Data Layer | 2-3 |
| Phase 2: Tailor Updates | 1-2 |
| Phase 3: Favourites UI | 2-3 |
| Phase 4: Navigation | 1 |
| Phase 5: Polish | 1 |
| **Total** | **7-10** |

---

## Acceptance Criteria

- [ ] User can view 3 tabs in Favourites page: FABRICS, TAILORS, GARMENTS
- [ ] User can save Ready-to-Wear garments from tailor profiles
- [ ] Saved garments persist in Firestore under user's favorites
- [ ] User can remove garments from favorites
- [ ] Empty state shows appropriate messaging for each category
- [ ] Navigation reflects favorites count (all 3 categories)
- [ ] Responsive design works on mobile and desktop
