# ATOMIC CONSULTATION: Uber UI → Tailor Finder Adaptation
## Comprehensive Implementation Plan for Client UserType

---

## 📋 ATOMIC PHASE BREAKDOWN

### Phase 1: Core Infrastructure (Foundation)
**Timeline**: Day 1-2 | **Priority**: Critical

#### 1.1 Data Layer
- [ ] Create `ServiceTier` enum (Custom, Ready-to-Wear, Bridal, Menswear, Womenswear)
- [ ] Create `TailorServiceEntity` with tier, pricing, turnaround
- [ ] Create `BookingQuoteEntity` with price breakdown
- [ ] Extend `TailorEntity` with service tiers array

#### 1.2 Provider Layer
- [ ] `tailorFinderProvider` - Main state management
- [ ] `selectedServiceTierProvider` - Current tier selection
- [ ] `tailorMarkersProvider` - Map markers data
- [ ] `quoteProvider` - Price estimation

**Files to Create:**
- `lib/features/tailor/domain/entities/service_tier.dart`
- `lib/features/tailor/domain/entities/booking_quote.dart`
- `lib/features/tailor/presentation/providers/tailor_finder_provider.dart`

**Files to Modify:**
- None yet (foundation only)

---

### Phase 2: Desktop UI Implementation
**Timeline**: Day 2-4 | **Priority**: High

#### 2.1 Desktop Page Scaffold (1536 × 1024px)
**Root Structure:**
```
RideBookingDesktop (0,0,1536,1024) #05070A
├── Header (0,0,1536,84) #04070C                    [KEEP]
├── Gold Divider (364,82,1172,3) #F4BE18              [ADAPT: Use as accent]
├── Left Map (0,84,836,940) #071018                  [MODIFY: Add tailor markers]
├── Right Panel (840,142,668,777) #F6F6F7            [MAJOR: Transform to service panel]
```

**Implementation Details:**
```dart
// lib/features/tailor/presentation/pages/tailor_finder_desktop.dart

class TailorFinderDesktop extends StatelessWidget {
  // Dimensions match Figma: 1536w × 1024h
  // Map area: 836px width (left)
  // Panel area: 668px width (right)
  // Panel top offset: 142px from header
  // Panel height: 777px
  // Corner radius: 28px
}
```

#### 2.2 Map Region Adaptation

| Figma Element (Cars) | Tailor Finder Adaptation |
|---------------------|----------------------|
| Map Background (#071018) | Keep (dark theme) |
| Dark Overlay (46% opacity) | Keep |
| Back Button Circle (76×76) | Keep (navigation) |
| "YOU" Location Pill | "MY LOCATION" Pill (client) |
| Route Origin Marker | Client marker (pulsing blue) |
| Route Line | Path to tailor |
| Destination Marker | Tailor shop marker |
| HOME Pill | Selected tailor info card |
| Car Icons (5 cars) | Tailor Shop Icons (5 nearby) |

**Map Markers Implementation:**
```dart
// Replace car icons with tailor markers
// Car 1: (98, 328) → Tailor Shop A
// Car 2: (104, 372) → Tailor Shop B
// Car 3: (490, 222) → Tailor Shop C
// Car 4: (744, 446) → Tailor Shop D
// Car 5: (384, 724) → Tailor Shop E
// Each shows: avatar initial, rating badge
```

#### 2.3 Service Selection Panel

**Chip Row Adaptation:**
```
UberX Chip → Custom Chip
Select Chip → Ready-to-Wear Chip  
Black Chip → Bridal Chip
UberBAG Chip → Menswear Chip
```

| Chip | Original | Adapted Content |
|------|----------|---------------|
| Chip Dimensions | 126×54 | Keep |
| Gap | 26px | Keep |
| Radius | 27 | Keep |
| Active State | #000000 fill | #000000 fill (selected) |
| Inactive | #FFFFFF fill | #FFFFFF fill |

**Info Block Adaptation:**
| Original | Adapted |
|---------|---------|
| "Popular" Label | "Recommended" Label |
| Passenger Icon | Person icon |
| Capacity Text | "Available Now" text |
| Subtitle | Tailor specialties |

**Price Block Adaptation:**
| Original | Adapted |
|---------|---------|
| Price Text | Service Quote (₦X,XXX) |
| Time Text | Turnaround (X days) |
| Position | Right-aligned in panel |

#### 2.4 Vehicle Image → Portfolio Preview
- Replace car illustration with tailor portfolio carousel
- Show 3-4 work samples in 534×188px area
- Support horizontal swipe

#### 2.5 Action Buttons
| Original | Adapted |
|---------|---------|
| Money Button | "Save Quote" Button |
| Clock Button | "Schedule" Button |
| "Request Ride" CTA | "Book Consultation" CTA |

---

### Phase 3: Mobile UI Implementation
**Timeline**: Day 4-5 | **Priority**: High

#### 3.1 Mobile Page Structure (941 × 1672px)

```
RideBookingMobile (0,0,941,1672) #05070A
├── Status Bar (0,0,941,40) transparent
├── Map (0,0,941,1314) #080B0D
├── Bottom Sheet (44,768,853,844) #F7F7F8
└── Phone Navigation Bar (0,1592,941,80) #000000
```

**Implementation Details:**
```dart
// lib/features/tailor/presentation/pages/tailor_finder_mobile.dart

class TailorFinderMobile extends StatelessWidget {
  // Canvas: 941w × 1672h
  // Map height: 1314px
  // Bottom sheet: 844px height
  // Safe margins: 20px
}
```

#### 3.2 Mobile Map Adaptation
- Keep all marker positions relative to parent
- Add "nearby tailors" filter chips above map
- Show distance in minutes/km

#### 3.3 Mobile Bottom Sheet
- Service tier chips (horizontal scroll)
- Selected tailor card
- Quote estimation
- Portfolio preview (horizontal)
- Primary CTA: "Book Now"

---

### Phase 4: Integration & Navigation
**Timeline**: Day 5-6 | **Priority**: Medium

#### 4.1 Route Registration
```dart
// lib/main.dart - Add routes

'/tailor-finder': (context) => DesktopShellWrapper(
  title: 'Find a Tailor',
  selectedIndex: -1,
  child: TailorFinderDesktop(),
),

'/tailor-finder-mobile': (context) => TailorFinderMobile(),
```

#### 4.2 Dashboard Integration
- Update ClientDashboard "Find Tailor" button
- Add to desktop shell navigation

#### 4.3 Booking Flow Integration
- Link to existing booking flow
- Pass selected tailor + service tier

---

## 📐 EXACT DIMENSION SPECIFICATIONS

### Desktop Panel Layout (Right Side)
```
x: 840 (left edge)
y: 142 (top offset from header, below gold divider at y=82)
w: 668
h: 777
radius: 28
fill: #F6F6F7
shadow: 0 20 60 rgba(0,0,0,0.35)
```

### Service Chips Row
```
x: 876 (36px from panel left)
y: 210 (68px from panel top)
w: 590 (total row)
h: 62
Chip template: 126w × 54h × 27r
Gap: 26px
Active chip: fill #000000
Inactive chip: fill #FFFFFF
```

### Info Block Position
```
Label x: 880
Label y: 350
Price x: 1240 (right-aligned)
Price y: 338
Time y: 418
```

### Vehicle/Portfolio Area
```
x: 904
y: 494
w: 534
h: 188
```

### Action Buttons Row
```
Container: x:876, y:762, w:596, h:92
Money button: 92×92, radius 46, left
Clock button: 92×92, radius 46, center
Primary CTA: 352×92, radius 46, right
CTA text: "BOOK CONSULTATION"
```

---

## 🎨 COLOR MAPPING TO DESBY THEME

| Figma Color | Desby Theme | Usage |
|-------------|------------|-------|
| #05070A | `AppColors.darkNavy` | Root background |
| #04070C | `AppColors.darkNavy` | Header |
| #F4BE18 | `AppColors.amber` | Gold divider/accent |
| #071018 | `AppColors.uberBg` | Map background |
| rgba(0,0,0,0.46) | `Colors.black54` | Map overlay |
| #4D5DFF | `AppColors.uberInfo` | Route marker blue |
| #2B8CFF | `AppColors.uberInfo` | Route line |
| #F6F6F7 | `AppColors.fgmaCardFill` | Panel fill |
| #000000 | `Colors.black` | Active chip |
| #FFFFFF | `Colors.white` | Inactive chip |
| #3247D9 | `AppColors.amber` | Popular label |
| #00FF7F | `AppColors.uberLive` | Live status |

---

## 📱 COMPONENT REUSE STRATEGY

### Existing Components to Reuse
| Component | Location | Usage |
|----------|----------|-------|
| `DesbyCard` | `lib/core/widgets/uber_card.dart` | Tailor info cards |
| `StatusPill` | `lib/core/widgets/status_pill.dart` | Availability status |
| `CompactProgressBar` | `lib/core/widgets/tracking_progress.dart` | Order progress |
| `NigeriaLgaData` | `lib/core/constants/nigeria_lga_data.dart` | Location filter |

### New Components Required
| Component | File |
|-----------|------|
| `TailorFinderDesktop` | `tailor_finder_desktop.dart` |
| `TailorFinderMobile` | `tailor_finder_mobile.dart` |
| `TailorMapMarker` | `tailor_marker_widget.dart` |
| `ServiceTierChips` | `service_tier_selector.dart` |
| `QuoteEstimationCard` | `quote_estimation_card.dart` |
| `TailorShopCard` | `tailor_shop_card.dart` |

---

## 🔗 INTEGRATION POINTS

### From Existing Pages
1. **ClientDashboard** → "Find Tailor" button → `/tailor-finder`
2. **DesktopDashboardShell** → "Find Tailor" nav item → `/tailor-finder`
3. **TailorDiscoveryPage** → May replace or wrap

### To Existing Pages
1. **TailorProfilePage** → Select tailor → Show profile
2. **BookingConfirmation** → Book consultation → Order flow

---

## 🗺️ MAP INTEGRATION: OpenStreetMap (Free)

### Package Selection
Use `flutter_map` + `latlong2` - free, open-source, no API key required

### pubspec.yaml Dependencies
```yaml
dependencies:
  flutter_map: ^7.0.0
  latlong2: ^0.9.0
```

### Map Implementation
```dart
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// Nigeria center: Lagos
const LatLng NIGERIA_CENTER = LatLng(6.5244, 3.3792);

FlutterMap(
  options: MapOptions(
    initialCenter: NIGERIA_CENTER,
    initialZoom: 12.0,
  ),
  children: [
    TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.desby.app',
    ),
    MarkerLayer(markers: tailorMarkers),
  ],
);
```

### Tailor Markers
- Each marker shows tailor avatar + rating
- Tap to select and show route
- Route drawn using Polyline

### Implementation Notes
- Dark map tiles available via CartoCSS: `https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png`
- Use dark tiles to match Uber-style dark theme
- Marker clusters for many tailors in area

---

## ⚡ ATOMIC IMPLEMENTATION TODO

### Step 1: Create Foundation
```bash
# Create directory structure
mkdir -p lib/features/tailor/domain/entities
mkdir -p lib/features/tailor/presentation/pages
mkdir -p lib/features/tailor/presentation/widgets
```

### Step 2: Implement Data Models
```dart
// service_tier.dart
enum ServiceTier { custom, readyToWear, bridal, menswear, womenswear }

// booking_quote.dart  
class BookingQuote {
  final double price;
  final int turnaroundDays;
  final String garmentType;
  final List<String> inclusions;
}
```

### Step 3: Build Desktop Page
- Scaffold 1536×1024 layout
- Implement left map with markers
- Implement right panel with chips
- Add quote estimation
- Add CTA buttons

### Step 4: Build Mobile Page
- Scaffold 941×1672 layout  
- Implement bottom sheet
- Add service chips scroll
- Connect to providers

### Step 5: Connect Routes
- Register in main.dart
- Test navigation flow

---

## 📊 SUCCESS CRITERIA

- [ ] Desktop loads in <2s
- [ ] Mobile maintains 60fps
- [ ] Map markers render <500ms
- [ ] Quote fetches <1s
- [ ] Booking flow <5 taps

---

## 📝 NOTES

1. **Maintain dark theme** in map areas (consistent with Uber-style)
2. **Light theme** in service panel (matching Figma #F6F6F7)
3. **Amber accent** for all interactive elements
4. **Consultation-first** flow (quote before booking)
5. **Turnaround time** replaces ETA concept
6. **Portfolio** replaces vehicle image

---

*Generated: Atomic Consultation for Uber → Tailor Finder Adaptation*
*Based on: Figma Frame Spec Desktop & Mobile Ride Booking UI*
