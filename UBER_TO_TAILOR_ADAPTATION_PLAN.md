# Uber UI to Tailor Finder Adaptation Plan

## Executive Summary

This document provides a comprehensive plan to adapt the Uber-style ride booking UI (for finding cars) to a **tailor finder UI** for the client user type on the Desby platform. The adaptation maps ride-booking concepts to tailoring service discovery, following the existing Desby brand theme (Dark Navy + Amber).

---

## Table of Contents

1. [Concept Mapping: Cars → Tailors](#concept-mapping-cars--tailors)
2. [UI Component Adaptation Matrix](#ui-component-adaptation-matrix)
3. [Phase 1: Core Infrastructure](#phase-1-core-infrastructure)
4. [Phase 2: Desktop UI Implementation](#phase-2-desktop-ui-implementation)
5. [Phase 3: Mobile UI Implementation](#phase-3-mobile-ui-implementation)
6. [Phase 4: Integration & Navigation](#phase-4-integration--navigation)
7. [Technical Specifications](#technical-specifications)
8. [Implementation Dependencies](#implementation-dependencies)

---

## Concept Mapping: Cars → Tailors

| Uber Concept | Tailor Finder Concept | Description |
|-------------|---------------------|--------------|
| **Ride Type (UberX, Black, etc.)** | **Service Tier** | Custom, Ready-to-Wear, Bridal, Menswear, Womenswear |
| **Driver** | **Tailor** | Professional tailor/fashion designer |
| **Vehicle** | **Portfolio/Showcase** | Gallery of past work samples |
| **ETA** | **Turnaround Time** | Estimated completion time |
| **Pickup Location** | **Client Location** | Where measurement/fitting occurs |
| **Destination** | **Delivery Address** | Where finished garment is delivered |
| **Ride Fare** | **Service Quote** | Estimated cost for service |
| **Driver Rating** | **Tailor Rating** | Rating out of 5 stars |
| **License Plate** | **Shop Name** | Tailor's business identifier |
| **Trip** | **Appointment/Booking** | Service booking |

---

## UI Component Adaptation Matrix

### Desktop UI (1536 × 1024px)

| Figma Element (Cars) | Adapted Element (Tailors) | Implementation |
|--------------------|------------------------|----------------|
| `RideBookingDesktop` root frame | `TailorFinderDesktop` root frame | Copy & transform frame |
| Header with Uber logo | Header with DESBY logo | Keep existing header |
| Map view (left, 836px) | Tailor map discovery (left, 836px) | Map with tailor markers |
| Ride option chips | Service tier chips | Service selection |
| Vehicle image | Tailor portfolio preview | Image carousel |
| Price & ETA block | Quote & turnaround block | Price estimation |
| "Request Ride" CTA | "Book Consultation" CTA | Primary action |
| Car markers on map | Tailor markers on map | Custom map pins |

### Mobile UI (941 × 1672px)

| Figma Element (Cars) | Adapted Element (Tailors) | Implementation |
|--------------------|------------------------|----------------|
| `RideBookingMobile` root | `TailorFinderMobile` root | Copy & transform |
| Status bar | Status bar | Keep |
| Map (1314px height) | Tailor discovery map | Interactive map |
| Bottom sheet | Service selection sheet | Service tier cards |
| Ride option chips | Service chips | Horizontal scroll |
| Vehicle illustration | Portfolio preview | Image gallery |
| "Request Ride" CTA | "Book Appointment" CTA | Primary button |

---

## Phase 1: Core Infrastructure

### 1.1 Data Models

```dart
// lib/features/tailor/domain/entities/tailor_service.dart

enum ServiceTier {
  custom,      // Custom tailoring (full bespoke)
  readyToWear, // Ready-to-wear adjustments
  bridal,      // Bridal/wedding wear
  menswear,    // Men's uniforms/garments
  womenswear,  // Women's garments
}

class TailorServiceEntity {
  final String id;
  final String tailorId;
  final ServiceTier tier;
  final String name;
  final String description;
  final double startingPrice;
  final int estimatedDays; // turnaround time
  final List<String> includes; // what's included
}
```

### 1.2 Provider Setup

```dart
// lib/features/tailor/presentation/providers/tailor_finder_provider.dart

final tailorsProvider = FutureProvider.family<List<TailorEntity>, TailorFilters?>
final selectedTailorProvider = StateProvider<TailorEntity?>
final serviceTierProvider = StateProvider<ServiceTier?>
final bookingQuoteProvider = StateProvider<BookingQuote?>
```

### 1.3 Repository Updates

```dart
// lib/features/tailor/domain/repositories/tailor_repository.dart

abstract class TailorRepository {
  Future<List<TailorEntity>> findNearbyTailors(GeoPoint location, double radiusKm);
  Future<List<TailorEntity>> searchTailors(String query, TailorFilters filters);
  Future<BookingQuote> getQuote(TailorEntity tailor, ServiceTier tier, GarmentType garment);
}
```

---

## Phase 2: Desktop UI Implementation

### 2.1 Page Structure

```
lib/features/tailor/presentation/pages/
├── tailor_finder_desktop.dart    [NEW] Desktop main discovery
├── tailor_finder_mobile.dart     [NEW] Mobile main discovery
├── tailor_card.dart              [REUSE] Existing card component
├── service_tier_selector.dart   [NEW] Service tier chips
├── tailor_map_view.dart         [NEW] Map with tailor markers
├── quote_estimation_card.dart  [NEW] Price & time display
└── booking_confirmation_sheet.dart [NEW] Booking bottom sheet
```

### 2.2 Main Desktop Page Layout

```dart
// TailorFinderDesktop - 1536 × 1024px
// Split: 836px map (left) + 668px panel (right)

class TailorFinderDesktop extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: Row(children: [
        // LEFT: Interactive Map with Tailor Markers
        Expanded(
          flex: 836,
          child: _TailorMapView(),
        ),
        // RIGHT: Service Selection Panel
        Expanded(
          flex: 668,
          child: _ServiceSelectionPanel(),
        ),
      ]),
    );
  }
}
```

### 2.3 Map View Components

```dart
class _TailorMapView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      // Base map (dark theme)
      Container(color: AppColors.uberBg),
      // Tailor markers (replacing car icons)
      ..._buildTailorMarkers(),
      // Origin pill ("You" = client location)
      _OriginPill(),
      // Route line to selected tailor
      _RouteLine(),
      // Destination marker (tailor shop)
      _TailorDestinationMarker(),
    ]);
  }
}
```

### 2.4 Service Selection Panel

```dart
class _ServiceSelectionPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 142), // Match Figma spec
      decoration: BoxDecoration(
        color: AppColors.fgmaCardFill, // #F6F6F7
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppColors.figmaShadow,
      ),
      child: Column(children: [
        // Service Tier Chips (like ride types)
        _ServiceTierChips(),
        // Selected Tailor Info
        _TailorInfoCard(),
        // Portfolio Preview
        _PortfolioPreview(),
        // Price & Turnaround
        _QuoteEstimation(),
        // Action Buttons
        _ActionButtons(),
      ]),
    );
  }
}
```

---

## Phase 3: Mobile UI Implementation

### 3.1 Mobile Layout (941 × 1672px)

```
┌─────────────────────────────┐
│ Status Bar (40px)           │
├─────────────────��───────────┤
│                             │
│   Map with Tailor Markers     │
│   (1314px height)           │
│                             │
├─────────────────────────────┤
│  Bottom Sheet (358px)       │
│  - Service Chips           │
│  - Tailor Info             │
│  - Quote                  │
│  - Book CTA               │
├─────────────────────────────┤
│ Navigation Bar (80px)       │
└─────────────────────────────┘
```

### 3.2 Bottom Sheet Components

```dart
class TailorFinderMobile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.uberBg,
      body: Column(children: [
        // Map (full width)
        Expanded(child: _TailorMapMobile()),
        // Bottom Sheet
        _BookingBottomSheet(),
      ]),
    );
  }
}
```

---

## Technical Specifications

### 4.1 Theme Integration

All components use existing Desby theme colors:

| Purpose | Color |
|---------|-------|
| Background | `AppColors.darkNavy` (#0A1921) |
| Panel Background | `AppColors.figmaCardFill` (#F6F6F7) |
| Primary Accent | `AppColors.amber` (#FFC107) |
| Active Selection | `AppColors.uberLive` (#00E676) |
| Text Primary | `AppColors.textPrimary` (#0F172A) |
| Text Secondary | `AppColors.textSecondary` (#64748B) |

### 4.2 Component Reuse

| Existing Component | Usage |
|-------------------|-------|
| `DesbyCard` | Tailor info cards |
| `StatusPill` | Availability status |
| `CompactProgressBar` | Order progress tracking |
| `UberCard` | Desktop order cards |
| `TrackingProgress` | Order timeline |

### 4.3 Navigation Routes

```dart
// lib/main.dart routes to add

'/tailor-finder': (context) => TailorFinderDesktop(),
'/tailor-finder-mobile': (context) => TailorFinderMobile(),
'/tailor-profile': (context) => TailorProfilePage(tailor: args),
'/booking-confirmation': (context) => BookingConfirmationSheet(args),
```

---

## Implementation Dependencies

### Files to Create (New)

1. `lib/features/tailor/domain/entities/tailor_service.dart`
2. `lib/features/tailor/domain/entities/booking_quote.dart`
3. `lib/features/tailor/domain/repositories/tailor_repository.dart`
4. `lib/features/tailor/presentation/providers/tailor_finder_provider.dart`
5. `lib/features/tailor/presentation/pages/tailor_finder_desktop.dart`
6. `lib/features/tailor/presentation/pages/tailor_finder_mobile.dart`
7. `lib/features/tailor/presentation/widgets/tailor_map_view.dart`
8. `lib/features/tailor/presentation/widgets/service_tier_selector.dart`
9. `lib/features/tailor/presentation/widgets/quote_estimation_card.dart`

### Files to Modify (Existing)

1. `lib/main.dart` - Add routes
2. `lib/core/constants/nigeria_lga_data.dart` - May need expansion
3. `lib/features/tailor/presentation/pages/tailor_discovery_page.dart` - May adapt or replace
4. `lib/features/dashboard/presentation/pages/client_dashboard.dart` - Update "Find Tailor" button

---

## Implementation Sequence

### Step 1: Data Layer (Day 1)
- [ ] Create `TailorServiceEntity`
- [ ] Create `BookingQuoteEntity`
- [ ] Add repository methods

### Step 2: Providers (Day 1-2)
- [ ] Implement `tailorsProvider`
- [ ] Implement `selectedTailorProvider`
- [ ] Implement `serviceTierProvider`

### Step 3: Desktop UI (Day 2-3)
- [ ] Create `TailorFinderDesktop` page
- [ ] Build map view with markers
- [ ] Build service selection panel
- [ ] Connect to providers

### Step 4: Mobile UI (Day 3-4)
- [ ] Create `TailorFinderMobile` page
- [ ] Build bottom sheet UI
- [ ] Connect to desktop providers

### Step 5: Integration (Day 4-5)
- [ ] Add routes to main.dart
- [ ] Update client dashboard
- [ ] Connect to booking flow

---

## Key Differences from Uber UI

| Aspect | Uber (Cars) | Desby (Tailors) |
|--------|------------|----------------|
| Selection | Single ride type | Multiple service tiers possible |
| Pricing | Fixed fare | Quote-based (varies by garment) |
| ETA | Minutes | Days (turnaround time) |
| Map Markers | Cars (moving) | Shops (static locations) |
| Booking | Immediate | Consultation first, then quote |
| Route | Point-to-point | Client → Tailor → Delivery |

---

## Success Metrics

- [ ] Desktop page loads under 2 seconds
- [ ] Mobile page maintains 60fps scrolling
- [ ] Map markers load within 500ms
- [ ] Quote fetches within 1 second
- [ ] Booking flow completes in under 5 taps

---

## Notes

- Reuse existing `TailorDiscoveryPage` logic where possible
- Maintain dark theme on map areas (consistent with Uber-style)
- Keep light theme on right panel (matching Figma spec)
- Use amber for all interactive elements
- Follow accessibility guidelines for touch targets
