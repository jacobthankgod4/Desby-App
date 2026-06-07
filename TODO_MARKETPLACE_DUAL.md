# TODO: Marketplace Fix & Desktop Enhancement

## Issues to Fix

### 1. Desktop Navigation - Add Marketplace for Client
**File**: `lib/core/widgets/desktop_shell_wrapper.dart`
- Add `Marketplace` nav item for client user type (currently missing)
- Add `Ready-to-Wear` as sub-item or second marketplace

### 2. Create Ready-to-Wear Marketplace Page
- Create `lib/features/marketplace/presentation/pages/ready_to_wear_marketplace.dart`
- Fetch finished garments from Firestore (tailors' products)
- Add dual-tab or toggle between Fabric/Ready-to-Wear

### 3. Implement Placeholder Client Pages
- `/live-milestones` - Live order tracking
- `/garment-architecture` - Visual design builder
- `/portfolio` - Client's saved designs
- `/digital-closet` - Virtual closet

### 4. Mobile Marketplace Verification
- Verify mobile nav has proper marketplace access

## Implementation Plan

### Step 1: Add Desktop Client Nav Items
Edit `lib/core/widgets/desktop_shell_wrapper.dart`:
```dart
case 'client':
  return [
    // ... existing items
    NavItem(label: 'Marketplace', icon: Icons.shopping_bag_rounded, route: '/marketplace'),
    // ... rest
  ];
```

### Step 2: Add Ready-to-Wear to Main.dart Routes
Add route for ready-to-wear marketplace

### Step 3: Create Ready-to-Wear Page
Create new page that displays tailors' finished garments

## Status
- [ ] Add Marketplace to desktop client nav
- [ ] Add Ready-to-Wear marketplace
- [ ] Verify mobile marketplace
- [ ] Implement placeholder pages

## Files to Edit
1. `lib/core/widgets/desktop_shell_wrapper.dart`
2. `lib/main.dart`
3. Create new marketplace page
