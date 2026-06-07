# AI Scan Premium Feature: Comprehensive Business Logic Plan V2

## Document Purpose

This document provides the comprehensive business logic for implementing AI Scan as a premium feature within the Desby tailor marketplace. This V2 version integrates with the existing UI components identified during the codebase audit, ensuring non-destructive integration with the TailorCard, TailorProfilePage, and subscription system.

---

## 1. Feature Overview

### 1.1 What Is AI Scan?

AI Scan is an AI-powered measurement extraction feature that allows clients to obtain accurate body measurements by photographing themselves in front of and at a right angle to their phone camera. The system processes these photographs through the backend AI measurement service and returns 18-27 body measurements (chest, waist, hip, shoulder width, sleeve length, inseam, and other key dimensions) that a tailor uses to create bespoke garments.

### 1.2 Core Value Proposition

| For Client | For Tailor | For Platform |
|-----------|-----------|---------------|
| No manual measurement or tailor visit needed to begin | Attracts clients who want convenience | Subscription upgrade motivation for tailors |
| Instant measurement capture in under five minutes | Faster onboarding for new clients | Revenue driver through premium tier differentiation |
| Remote measurement support enables nationwide tailoring | Reduced client measurement errors | Competitive advantage in custom tailoring market |
| Reuse saved measurements for repeat orders | Professional measurement data format | Marketplace differentiation |

---

## 2. Business Model

### 2.1 Premium Feature Logic

AI Scan functions as a tier-restricted feature. The tailor's subscription status determines whether AI Scan appears as an available option to clients browsing or viewing that tailor's profile. This creates a direct incentive structure: tailors who upgrade their subscription gain access to AI Scan as a client-attraction tool, while free-tier tailors do not have access to the feature available in their profile.

The logic follows this flow: When a client browses the tailor finder, each tailor's profile card displays a visual indicator reflecting the tailor's AI Scan status. When the client taps to view a tailor's full profile, the profile page renders either the active AI Scan button (for subscribed tailors) or a locked indicator (for free-tier tailors). The client-initiated measurement flow operates within the context of the selected tailor—the measurements are associated with that tailor's account for subsequent orders.

### 2.2 Subscription Tier Matrix (Updated)

| Feature | Free Tier | PRO (₦15,000) | BUSINESS (₦45,000) |
|---------|----------|---------------|---------------------|
| Profile listing in finder | Yes | Yes | Yes |
| AI Scan badge on profile card | No | No | **Yes** |
| AI Scan button on profile | No | No | **Yes** |
| Client measurement storage | Manual only | Manual only | AI + Manual |
| Measurement re-use for orders | Per-order manual | Per-order manual | Saved and auto-populated |
| Priority discovery ranking | No | Yes | Higher |
| Commission rate | Standard | Standard | Reduced |

### 2.3 Plan Features (from PlanRegistry)

```
TAILOR_BUSINESS plan includes:
- AI Body Scan        ← PRIMARY FEATURE
- Auto Measurements
- AI Design Help
- Custom App
- Priority Ranking
- Reduced Commission
```

---

## 3. UI Integration Points (Non-Destructive)

### 3.1 Integration Audit Results

After auditing the existing codebase, the following integration points were identified:

#### A. TailorCard Widget (`lib/features/tailor/presentation/widgets/tailor_card.dart`)

**Current State:**
- Already has premium selection styling (amber border, shadow)
- Shows tailor name, price, distance badge
- Has `isSelected` flag for premium state

**Integration Point:**
- Add AI Scan badge below the rating/price row
- Only visible when `tailor.aiScanEnabled == true`
- Uses existing badge styling pattern

**UI Layout:**
```
Tailor Name                ⭐4.8
₦15,000                  15min

[AI Scan ✓]             (NEW - Business tier only)
```

#### B. TailorProfilePage (`lib/features/tailor/presentation/pages/tailor_profile_page.dart`)

**Current State:**
- Has "MEASUREMENT STATION" in RESOURCES section (line ~260)
- Routes to `/measurements-input` on tap
- Shows: "Update your precision digital profile"

**Integration Point:**
- Modify MEASUREMENT STATION row conditionally:
  - If AI Scan enabled: Show camera icon + "AI Body Scan" + tap launches AI Scan flow
  - If AI Scan disabled: Show normal MEASUREMENT STATION (manual) + "AI Scan not available for this tailor" info text - NO upgrade prompt shown to client

**UI Layout (Premium Tailor):**
```
MEASUREMENT STATION
[📸] AI Body Scan       →    Launches AI scan flow
       Tap to capture your measurements
```

**UI Layout (Free Tailor):**
```
MEASUREMENT STATION
[📏] Manual Measurement
       AI Scan not available for this tailor
```

### 3.2 Finder Screen Integration

#### TailorFinderMobile / TailorFinderDesktop

These pages render TailorCard in a grid. No changes needed to the page structure—only the card needs to render the AI Scan badge conditionally based on the tailor's subscription status.

---

## 4. User Journey Flow

### 4.1 From Tailor Finder (Updated Flow)

**Step 1: Browse Finders**

The client opens the app and navigates to the tailor finder. The finder displays a grid or list of available tailors, each rendered as a tailor card.

- **Business tier (AI-enabled)**: Card shows "AI Scan ✓" badge
- **Free/PRO tier**: Card shows no AI badge

```
┌─────────────────────────────────────────┐
│  [Tailor Photo]                         │
│                                         │
│  John Adeyemi Tailoring           ⭐4.8  │
│  ₦15,000                        15min   │
│                                         │
│  AI Scan ✓                        (NEW)  │
└─────────────────────────────────────────┘
```

**Step 2: View Tailor Profile**

The client taps a tailor card to view the full profile.

- **Business tier**: MEASUREMENT STATION shows "AI Body Scan" with camera icon → Tapping launches AI scan flow
- **Free tier**: MEASUREMENT STATION shows "Manual Measurement" → Tapping routes to manual measurement input

**Step 3: Initiate AI Scan (Premium Path)**

If AI Scan is available, the client taps the "AI Body Scan" button. The app presents the photo capture flow:

1. **Step 1**: Front photo capture (with silhouette guide overlay)
2. **Step 2**: Side photo capture (with silhouette guide overlay)
3. **Step 3**: Enter height (numeric input)
4. **Result**: Display 18-27 measurements for verification
5. **Save**: Confirm and save measurements to profile

**Step 4: Proceed to Booking**

With measurements captured, the client proceeds to booking. The measurements auto-populate the order form.

### 4.2 From Free Tailor Profile (Non-Premium Path)

**Step 1: View Profile**

When viewing a free/pro tier tailor's profile, the MEASUREMENT STATION shows manual input:

```
MEASUREMENT STATION
📏 Manual Measurement
  AI Scan not available for this tailor
```

**Step 2: Tap Manual Measurement**

Tapping routes to the manual measurement input form (existing flow).

---

## 5. Technical Implementation Requirements

### 5.1 Data Model Changes

#### Tailor Data (Firestore)

```dart
class TailorMarker {
  // ... existing fields
  final bool aiScanEnabled;  // NEW - derived from subscription tier
}
```

**Derivation Logic:**
```
aiScanEnabled = (currentSubscription == 'tailor_elite'/'tailor_business')
```

### 5.2 Subscription Check Integration

```dart
// In subscription_provider.dart
final aiScanEnabledProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  
  final repository = ref.read(subscriptionRepositoryProvider);
  final subscription = await repository.getSubscription(user.uid);
  
  // Check if subscription includes AI Body Scan
  return subscription?.features.contains('AI Body Scan') ?? false;
});
```

### 5.3 Frontend Components

#### TailorCard Updates

```dart
// Add conditional badge in TailorCard
Widget _buildAiScanBadge() {
  if (!tailor.aiScanEnabled) return const SizedBox.shrink();
  
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.amber.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.smartphone, size: 12, color: AppColors.amber),
        const SizedBox(width: 4),
        Text(
          'AI Scan ✓',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.amber,
          ),
        ),
      ],
    ),
  );
}
```

#### TailorProfilePage Updates

```dart
Widget _buildMeasurementStation(bool aiScanEnabled) {
  return InkWell(
    onTap: aiScanEnabled ? () => _launchAiScan() : () => _openManualMeasurement(),
    child: Row(
      children: [
        Icon(
          aiScanEnabled ? Icons.smartphone_rounded : Icons.straighten_rounded,
          color: aiScanEnabled ? AppColors.amber : Colors.white,
          size: 24,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                aiScanEnabled ? 'AI Body Scan' : 'Manual Measurement',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                aiScanEnabled 
                  ? 'Tap to capture your measurements'
                  : 'AI Scan not available for this tailor',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.arrow_forward_ios_rounded,
          color: aiScanEnabled ? AppColors.amber : Colors.white,
          size: 14,
        ),
      ],
    ),
  );
}
```

### 5.4 Measurement Service Integration

The existing `BodyMeasurementService` (`lib/core/services/body_measurement_service.dart`) handles the backend communication.

**Flow:**
```
1. Client takes front photo
2. Client takes side photo (optional, improves accuracy)
3. Client enters height
4. Service calls: POST /api/measurements
5. Returns: { measurements: {...}, confidence: 0.95 }
6. Display measurements for verification
7. Save to client profile
```

---

## 6. UI Reference Layouts

### 6.1 Tailor Card - Business Tailor (Finder)

```
┌──────────────────────────────────────────┐
│  [Tailor Photo]                         │
│                                        │
│  John Adeyemi Tailoring           ⭐4.8  │
│  ₦15,000                        15min  │
│                                        │
│  [AI Scan ✓]    ← New badge             │
└──────────────────────────────────────────┘
```

### 6.2 Tailor Card - Free Tailor (Finder)

```
┌──────────────────────────────────────────┐
│  [Tailor Photo]                         │
│                                        │
│  Quick Stitch Sewing             ⭐4.5  │
│  ₦10,000                        20min  │
│                                        │
│                      ← No AI badge     │
└──────────────────────────────────────────┘
```

### 6.3 Tailor Profile Page - Business Tier

```
┌──────────────────────────────────────────┐
│  ← BACK        TAILOR PROFILE            │
├──────────────────────────────────────────┤
│  [Profile Photo]                         │
│  John Adeyemi                        ⭐4.8│
│  Specialist in Agbada & Corporate       │
│  📍 Lagos, Nigeria                      │
│                                        │
│  ═══  PORTFOLIO  ═══                   │
│  [img] [img] [img] [img]                │
│                                        │
│  ═══  PRICING  ═══                    │
│  Agbada: ₦25,000 - ₦45,000            │
│  Suit: ₦35,000 - ₦80,000              │
│                                        │
│  ─────────────────────────────────────  │
│  [CONTACT]    [BOOK NOW]                │
│                                        │
│  ═══  RESOURCES  ═══                  │
│  [📦] FABRIC INVENTORY                  │
│  [📸] AI BODY SCAN      ← Button here  │
│       Tap to capture your measurements   │
└──────────────────────────────────────────┘
```

### 6.4 Tailor Profile Page - Free/Pro Tier

```
┌──────────────────────────────────────────┐
│  ← BACK        TAILOR PROFILE            │
├──────────────────────────────────────────┤
│  [Profile Photo]                         │
│  Quick Stitch Sewing             ⭐4.5│
│  Traditional & Party Wear             │
│  📍 Lagos, Nigeria                    │
│                                        │
│  ═══  PRICING  ═══                    │
│  Dress: ₦12,000 - ₦20,000           │
│  Agbada: ₦18,000 - ₦30,000           │
│                                        │
│  ─────────────────────────────────────  │
│  [CONTACT]    [BOOK NOW]               │
│                                        │
│  ═══  RESOURCES  ═══                │
│  [📦] FABRIC INVENTORY                 │
│  [📏] MANUAL MEASUREMENT             │
│       AI Scan not available            │
└──────────────────────────────────────────┘
```

---

## 7. Edge Cases and Error Handling

### 7.1 Subscription Downgrade

If a tailor downgrades from Business to Free tier:
- Existing saved client measurements remain
- Profile re-renders without AI Scan button
- Finder card removes AI badge on next refresh
- No orphaned measurement states

### 7.2 API Failure

If backend AI measurement service is unavailable:
- Show error with retry option
- Fallback to manual measurement

### 7.3 Image Quality

Poor photo quality (blur, bad lighting):
- Show specific error: "Photo too dark—move to better lighting"
- Prevent submission until quality threshold met

### 7.4 Offline Mode

No network:
- Show offline message
- Fallback to manual measurement entry

---

## 8. Implementation Phases

### Phase 1: Foundation (Complete)
- [x] Backend AI measurement service
- [x] Flutter service integration
- [x] Business logic plan documented

### Phase 2: Subscription Integration (Next)
- [ ] Add `aiScanEnabled` check to subscription provider
- [ ] Update PlanRegistry features (Done ✓)
- [ ] Add AI scan feature check to tailor data

### Phase 3: UI Integration
- [ ] Add AI Scan badge to TailorCard
- [ ] Modify MEASUREMENT STATION on TailorProfilePage
- [ ] Create AI scan flow screens

### Phase 4: Testing
- [ ] Internal testing
- [ ] UI/UX polish

### Phase 5: Soft Launch
- [ ] Enable for pilot Business tier tailors
- [ ] Monitor metrics

### Phase 6: General Availability
- [ ] Enable for all Business tier tailors
- [ ] Full analytics tracking

---

## 9. Metrics and Tracking

### Key Performance Indicators

| Metric | Target |
|--------|-------|
| AI Scan adoption rate | >40% |
| Subscription upgrade rate | >15% |
| Order completion rate | >60% |
| Measurement error rate | <10% |
| Premium tailor bookings | Baseline benchmark |

### Analytics Events

```dart
// Track these events
- ai_scan_initiated
- ai_scan_completed
- ai_scan_abandoned
- ai_scan_premium_viewed
- subscription_upgrade_viewed
```

---

## 10. Document Summary

AI Scan functions as a premium-tier feature tied directly to the tailor subscription. This V2 version integrates non-destructively with the existing UI:

- **TailorCard**: AI Scan badge appears on Business tier cards
- **TailorProfilePage**: MEASUREMENT STATION conditionally renders AI Scan button or upgrade prompt
- **PlanRegistry**: Updated to include "AI Body Scan" in Business tier features

The feature drives subscription upgrades by providing tangible differentiation: tailors with AI Scan attract more clients seeking convenient measurement. Clients benefit from instant measurement capture. The platform benefits from increased premium conversions.
