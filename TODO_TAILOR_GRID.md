# Tailor Finder Grid Implementation

## Step 1: Update TailorFinderProvider
- [x] Already exists with mock data structure
- [ ] Connect to Firestore via FirebaseAuthRepository.getTailors()

## Step 2: TailorCardWidget  
- [ ] Create TailorCard widget for grid display
- [ ] Show: name, rating stars, price, services, availability badge

## Step 3: Desktop Page Updates
- [ ] Add filter bar at top
- [ ] Add scrollable tailor grid (left)
- [ ] Add curved edge split screen layout
- [ ] Add Uber screen on right when selected

## Step 4: Mobile Page Updates
- [ ] Add filter bar (collapsible)  
- [ ] Add scrollable grid above map
- [ ] Add bottom sheet with tailor details when selected

## Implementation Plan
1. Update TailorFinderProvider to call Firestore
2. Add filter state fields (state, lga, priceMin, priceMax)
3. Create TailorCardWidget 
4. Integrate into both desktop and mobile pages
