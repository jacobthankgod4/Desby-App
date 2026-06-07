# AI Scan Premium Feature: Business Logic Plan

## Document Purpose

This document provides the comprehensive business logic for implementing AI Scan as a premium feature within the Desby tailor marketplace. The feature enables clients to capture body measurements using AI-powered photo analysis when booking with qualifying tailors. The implementation ties AI Scan availability directly to the tailor's subscription tier, creating a clear differentiation between free and premium tailors.

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

### 2.2 Subscription Tier Matrix

| Feature | Free Tier | Premium (AI-Enabled) |
|---------|----------|---------------------|
| Profile listing in finder | Yes | Yes |
| AI Scan badge on profile card | No | Yes |
| AI Scan button on profile | No (shows locked/unavailable) | Yes |
| Client measurement storage | Manual only | AI + Manual |
| Measurement re-use for orders | Per-order manual | Saved and auto-populated |
| Priority discovery ranking | Lower | Higher |
| Commission rate | Standard | Reduced |

### 2.3 Revenue Implications

The AI Scan feature serves as a conversion driver rather than a direct revenue stream. When clients see AI Scan available on a tailor's profile, they are more likely to book with that tailor due to the convenience of instant measurement. This perceived value justifies the premium pricing for the tailor, making the upgrade decision easier. The platform benefits through increased subscription conversions from tailors seeking a competitive edge.

---

## 3. User Journey Flow

### 3.1 From Tailor Finder

The client journey begins in the tailor finder screen.

**Step 1: Browse Finders**

The client opens the app and navigates to the tailor finder. The finder displays a grid or list of available tailors, each rendered as a tailor card. Free-tier tailors render without AI Scan indicators. Premium (subscribed) tailors render with a visible AI Scan badge on their card, positioned in the top-right corner or below their rating. This badge uses visual language such as "AI Scan" with an icon, or a checkmark with "AI Ready" text.

**Step 2: View Tailor Profile**

The client taps a tailor card to view the full tailor profile. The profile page loads the tailor's complete details including portfolio images, ratings, bio, location, pricing tiers, and—critically—the AI Scan availability indicator. If the tailor has a premium subscription with AI Scan enabled, the profile renders a prominent "AI Scan" button positioned near the "Book Now" or "Contact" action area. If the tailor does not have premium subscription, this area instead shows "AI Scan unavailable for this tailor" or a muted lock icon with explanatory text.

**Step 3: Initiate AI Scan (Premium Path)**

If AI Scan is available, the client taps the "AI Scan" button. The app presents a photo capture flow: instructions to take a front-facing full-body photograph, then a right-side profile photograph, and finally an input field for the client's known height in centimeters. Upon completion, the backend processes the photographs and returns the calculated measurements. These measurements display on screen for client verification. The client confirms or manually adjusts any values. The confirmed measurements save to the client's profile, associated with the selected tailor for this booking.

**Step 4: Proceed to Booking**

With measurements captured, the client proceeds to select fabric, style preferences, and finalizes the booking. The tailor receives the order with client measurements already complete, eliminating the need for a measurement consultation appointment.

### 3.2 From Direct Measurement Access

A client may also access AI Scan through their own measurement profile settings. The logic here differs: the measurements exist independently of any specific tailor. When the client later books with a tailor, if that tailor has AI Scan enabled, the saved measurements transfer to the order. If the tailor does not have AI Scan, the client must re-measure manually or provide measurements through the tailor's preferred process. This creates a subtle premium experience that clients come to expect once they have used AI Scan.

---

## 4. Technical Implementation Requirements

### 4.1 Backend Data Model

The tailor profile data structure requires two additions: an `aiScanEnabled` boolean field tied to the subscription status, and an `aiScanBadge` computed field for finder card rendering. This connects to the existing subscription system in Firebase, checking on profile load whether the current subscription tier includes AI Scan.

### 4.2 Frontend Components

**Tailor Card Widget**

The tailor card (used in finder) needs conditional badge rendering. When `aiScanEnabled` is true, render a small badge with "AI Scan" text and appropriate icon. When false, render no badge.

**Tailor Profile Page**

The profile page includes conditional button logic. The "AI Scan" button or equivalent displays based on subscription status. This page also handles the complete AI Scan flow: photo capture, height input, measurement display, and save action.

**Measurement Service Integration**

The Flutter `BodyMeasurementService` defined in this project connects to the backend AI measurement service. The integration accepts either single-photo (front only, yielding ±3-5cm accuracy) or dual-photo mode (front and side, yielding ±1-3cm accuracy). Recommend defaulting to dual-photo mode for best results. The service handles image compression, API communication, and response parsing.

### 4.3 State Management

The subscription state already exists in the app. The integration adds an AI Scan entitlement check to the existing provider. The provider should return a boolean indicating whether the currently viewed tailor has access to AI Scan, enabling conditional rendering across the finder and profile screens.

---

## 5. Edge Cases and Error Handling

### 5.1 Subscription Status Changes

If a tailor downgrades from premium to free tier, existing saved client measurements remain in the system but new AI Scan sessions become unavailable. Clients who previously booked with that tailor retain their measurement history. The system gracefully handles this: the profile re-renders without the AI Scan button, and the finder card removes the badge on next refresh. No orphaned measurement states occur.

### 5.2 API Failure

If the backend AI measurement service is unavailable during an AI Scan session, the app presents an error with retry option. Should the API remain unavailable, fallback to manual measurement input is available. The error handling preserves the user experience without blocking the booking flow.

### 5.3 Image Quality

Poor photograph quality (blur, bad lighting, incorrect pose) causes the validation layer in the backend to reject with specific error guidance. The frontend displays this guidance to the client ("Photo too dark—move to better lighting," "Stand further back—full body not visible") enabling successful resubmission without support contact.

### 5.4 Offline Mode

The app requires network connectivity for AI Scan as photographs upload to the backend. If offline, manual measurement mode serves as the fallback entry method. The offline message prompts the client accordingly.

---

## 6. UI Reference Layouts

### 6.1 Tailor Finder Card (Premium Tailor)

```
┌──────────────────────────────────────────┐
│  [Tailor Photo]                         │
│                                        │
│  John Adeyemi Tailoring              ⭐4.8│
│  Lagos • Starting ₦15,000              │
│                                      │
│  [AI Scan ✓ Badge]    👔 98% completion│
└──────────────────────────────────────────┘
```

### 6.2 Tailor Finder Card (Free Tailor)

```
┌──────────────────────────────────────────┐
│  [Tailor Photo]                         │
│                                        │
│  Quick Stitch Sewing              ⭐4.5│
│  Lagos • Starting ₦10,000            │
│                                      │
│                      👔 95% completion│
└──────────────────────────────────────────┘
```

### 6.3 Tailor Profile Page (Premium)

```
┌──────────────────────────────────────────┐
│  ← BACK        TAILOR PROFILE            │
├──────────────────────────────────────────┤
│  [Profile Photo]                         │
│  John Adeyemi                        ⭐4.8│
│  Specialist in Agbada & Corporate     │
│  📍 Lagos, Nigeria                    │
│                                        │
│  ═══  PORTFOLIO  ═══                 │
│  [img] [img] [img] [img]             │
│                                        │
│  ═══  PRICING  ═══                  │
│  Agbada: ₦25,000 - ₦45,000        │
│  Suit: ₦35,000 - ₦80,000           │
│                                        │
│  ─────────────────────────────────────  │
│  [CONTACT]    [BOOK NOW]              │
│  [📸 AI SCAN] ← Primary CTA          │
└──────────────────────────────────────────┘
```

### 6.4 Tailor Profile Page (Free)

```
┌──────────────────────────────────────────┐
│  ← BACK        TAILOR PROFILE            │
├──────────────────────────────────────────┤
│  [Profile Photo]                         │
│  Quick Stitch Sewing              ⭐4.5│
│  Traditional & Party Wear            │
│  📍 Lagos, Nigeria                    │
│                                        │
│  ═══  PRICING  ═══                  │
│  Dress: ₦12,000 - ₦20,000           │
│  Agbada: ₦18,000 - ₦30,000          │
│                                        │
│  ─────────────────────────────────────  │
│  [CONTACT]    [BOOK NOW]              │
│  📸 AI Scan unavailable for this tailor│
│  (Upgrade to enable)                  │
└──────────────────────────────────────────┘
```

### 6.5 AI Scan Flow

```
┌──────────────────────────────────────────┐
│  📸 AI BODY SCAN                       │
├──────────────────────────────────────────┤
│                                        │
│  Step 1 of 2: Front Photo            │
│  ┌────────────────────────────────┐   │
│  │                                │   │
│  │    [ Silhouette Guide ]         │   │
│  │                                │   │
│  │   Stand full body in view     │   │
│  └────────────────────────────────┘   │
│                                        │
│  [TAKE PHOTO]                         │
│                                        │
│  ─────────────────────────────────────  │
│  Front facing, full body visible      │
│  Neutral lighting, no flash          │
└──────────────────────────────────────────┘
```

---

## 7. Metrics and Success Tracking

### 7.1 Key Performance Indicators

| Metric | Description | Target |
|--------|-------------|--------|
| AI Scan adoption rate | Percentage of clients using AI Scan when available | >40% |
| Subscription upgrade rate | Free-to-premium conversions attributed to AI Scan | >15% |
| Order completion rate | Percentage of AI Scan sessions resulting in booked orders | >60% |
| Measurement error rate | Client-initiated corrections after AI Scan | <10% |
| Premium tailor bookings | Bookings through premium tailors with AI Scan | Baseline benchmark |

### 7.2 Analytics Events

Instrument the following events:

- `ai_scan_initiated`: Client enters AI Scan flow
- `ai_scan_completed`: Client successfully captures and confirms measurements
- `ai_scan_abandoned`: Client exits before completion
- `ai_scan_premium_viewed`: Client views a premium tailor profile (for conversion tracking)
- `subscription_upgrade_viewed`: Client taps upgrade prompt on free tailor profile

---

## 8. Implementation Phases

### Phase 1: Foundation (Current)

- Backend AI measurement service complete
- Flutter Dart service integration ready
- Publication plan documented

### Phase 2: Subscription Integration

- Add `aiScanEnabled` field to tailor data model
- Connect to existing subscription provider
- Conditional rendering in tailor card and profile

### Phase 3: Frontend UI

- Implement AI Scan button on profile page
- Implement photo capture flow screens
- Integrate measurement result display and save

### Phase 4: Testing

- Internal testing with sample photographs
- Threshold refinement for accuracy
- UI/UX polish

### Phase 5: Soft Launch

- Enable for pilot group of premium tailors
- Monitor metrics and feedback
- Iterate on flow based on real usage

### Phase 6: General Availability

- Enable for all premium tailors
- Remove beta labeling
- Full analytics tracking active

---

## 9. Document Summary

AI Scan functions as a premium-tier feature tied directly to the tailor subscription. Clients discover and use AI Scan through the tailor finder and profile pages, where premium status renders the active button and free status renders the unavailable state. The feature drives subscription upgrades by providing tangible differentiation: tailors with AI Scan attract more clients seeking convenient measurement. Clients benefit from instant, accurate measurement without manual tape work. The platform benefits from increased premium conversions and a differentiated marketplace positioning.

---
