# Garment Style Integration Plan for Unified Client Onboarding

## Overview

**EXISTING FLOW FOUND**: There is already a garment selector in `unified_add_client_page.dart`:
- Current garments: `['Suit', 'Agbada', 'Kaftan', 'Shirt', 'Dress']`
- Located in `_buildGarmentSelector()` method
- Measurement categories auto-adjust by gender

This plan outlines **ENHANCING** the existing flow with full categories and style preferences.

---

## 1) Garment Style Categories

### Male Categories

| Category | Garments |
|----------|---------|
| **Native Wear** | Senator wear, Agbada, Kaftan, Isiagu, Dashiki, Babariga |
| **Corporate** | Suits, Dress shirts |
| **Casual** | Blazer with chinos, Polo shirts, T-shirts, Jeans, Shorts |
| **Streetwear/Sportswear** | Oversized tees, Cargo pants, Hoodies |
| **Resort/Vacation** | Linen shirts, Shorts |
| **Groom/Wedding** | Tuxedos, Tailored suits, Embroidered native wear |

### Female Categories

| Category | Garments |
|----------|---------|
| **Native Wear** | Ankara Styles, Lace, Aso Ebi, Iro and Buba, Kaftans, Boubou Gowns, George Styles |
| **Dresses & Gowns** | Maxi, Midi, Bodycon, Maternity, Resort/Vacation |
| **Corporate Wear** | Blazers, Pencil skirts, Trousers, Shirts |
| **Casual Wear** | Jeans, T-shirts, Jumpsuits, Streetwear |
| **Luxury Couture** | Hand-beaded gowns, Structured dresses, Premium fabrics |
| **Bridal Wear** | White Wedding Gowns, Traditional Bridal Outfits, Reception, Bridesmaid Dresses |

---

## 2) Selection Criteria (Additional Fields)

| Field | Description | Input Type |
|-------|------------|-----------|
| **Occasion** | Event type (wedding, corporate event, casual, etc.) | Dropdown |
| **Color** | Preferred color(s) | Color picker |
| **Fabric** | Fabric type preference | Multi-select |
| **Budget** | Price range | Slider/Range |
| **Designer/Tailor** | Preferred designer | Search/Dropdown |
| **Delivery Time** | Required date | Date picker |
| **Size** | Current size reference | Dropdown |
| **Location** | Delivery/shipping address | Address input |

---

## 3) Measurement Mappings by Style

Each garment category requires specific measurements:

### Male Native Wear Measurements
- Body measurements: shoulder, chest, waist, hip, inseam, sleeve_length
- Style-specific: agbada_length, senator_length, kaftan_length

### Male Corporate Measurements  
- Body measurements: shoulder, chest, waist, hip, neck, sleeve_length
- Style-specific: jacket_length, trouser_length, shirt_length

### Female Native Wear Measurements
- Body measurements: shoulder, bust, waist, hip, height, inseam
- Style-specific: iro_length, buba_length, gown_length

### Female Corporate Measurements
- Body measurements: shoulder, bust, waist, hip, arm
- Style-specific: blazer_length, skirt_length, trouser_length

### Female Bridal Measurements
- Full body: shoulder, bust, waist, hip, height, arm, calf
- Detailed: bust_point, corset_measurements, train_length

---

> **NOTE**: No 3D model or camera mapping needed. The existing measurement fields already provide the necessary focus behavior.

---

## 5) Implementation Architecture

### Data Models

```dart
// GarmentCategory model
class GarmentCategory {
  final String id;
  final String name; // e.g., "native_wear_male"
  final String label; // e.g., "Native Wear"
  final List<String> garments;
  final List<String> requiredMeasurements;
  final String cameraProfile;
  final Gender gender;
}
```

### New Files to Create

1. **Domain Layer**
   - `lib/features/clients/domain/model/garment_category.dart`
   - `lib/features/clients/domain/model/garment_style_selection.dart`
   - `lib/features/clients/domain/model/client_preferences.dart`

2. **Presentation Layer**
   - `lib/features/clients/presentation/widgets/garment_category_selector.dart`
   - `lib/features/clients/presentation/widgets/style_preferences_form.dart`
   - `lib/features/clients/presentation/pages/client_onboarding_page.dart`

3. **State Management**
   - `lib/features/clients/presentation/providers/onboarding_provider.dart`

---

## 6) UI Flow Integration

### Phase 1: Gender Selection → Style Selection
1. User selects gender (existing)
2. User selects garment categories (multi-select)
3. User selects specific garments within category
4. System loads required measurements for selected style

### Phase 2: Measurement Input with 3D Focus
1. For each measurement, show relevant 3D view
2. Focus camera on body part appropriate for garment type
3. Validate measurement against style requirements

### Phase 3: Additional Preferences
1. Collect: Occasion, Color, Fabric, Budget
2. Collect: Designer/Tailor, Delivery Time
3. Collect: Size reference, Location

### Phase 4: Review & Submit
1. Display summary of selections
2. Show estimated price/time
3. Submit to create client profile

---

## 7) Database Schema Updates

### Firestore: clients/{clientId}

```json
{
  "clientId": "string",
  "garmentPreferences": {
    "categories": ["native_wear_male", "corporate_male"],
    "selectedGarments": ["agbada", "suit"],
    "occasions": ["wedding", "corporate_event"],
    "colors": ["navy", "black"],
    "fabrics": ["lace", "wool"],
    "budget": {
      "min": 50000,
      "max": 200000
    },
    "designerId": "string|null",
    "deliveryDate": "timestamp",
    "location": {
      "address": "string",
      "city": "string",
      "state": "string"
    }
  },
  "measurementProfile": {
    "garmentType": "string",
    "measurements": {...}
  }
}
```

---

## 8) Technical Implementation Steps

### Step 1: Create Data Models
- Create garment category constants
- Create selection data classes
- Add type-safe enums

### Step 2: Build UI Components
- Category selection chips/widget
- Multi-select garment picker
- Style preferences form

### Step 3: Add 3D Integration
- Map categories to camera profiles
- Update focus controller
- Add style-based overrides

### Step 4: State Management
- Create onboarding state provider
- Add persistence to Firestore
- Handle multi-step navigation

### Step 5: Form Validation
- Required fields by category
- Budget validation
- Date validation

### Step 6: Testing
- Unit tests for mappings
- Widget tests for forms
- Integration test flow

---

## 9) API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/categories` | GET | List all garment categories |
| `/categories/{id}` | GET | Get category details |
| `/preferences/{clientId}` | POST | Save preferences |
| `/preferences/{clientId}` | GET | Get preferences |

---

## 10) Priority Sequencing

### MVP (Phase 1)
1. Gender → Category selection
2. Basic 3D focus profiles
3. 5 core measurements
4. Local storage

### Phase 2
1. Full category/garment list
2. All measurements
3. Firestore integration

### Phase 3 (Full)
1. Designer/Tailor selection
2. Budget/time inputs
3. Location mapping
4. Analytics dashboard

---

## 11) Files to Modify

- `lib/features/clients/presentation/pages/unified_add_client_page.dart`
- `lib/features/clients/presentation/providers/client_provider.dart`
- `lib/features/clients/data/repositories/firebase_client_repository.dart`
- `lib/features/clients/domain/entities/client.dart`

---

## 12) Testing Checklist

- [ ] Category selection persists
- [ ] 3D focuses correct region per garment
- [ ] Form validation shows errors
- [ ] Data saves to Firestore
- [ ] Multi-step navigation works
- [ ] Back/forward navigation preserves state

---

## 13) Next Actions

1. Create garment category model file
2. Build category selector UI component  
3. Integrate into unified_add_client_page.dart
4. Test with sample client flow
5. Add to Firestore schema

---

## Related Files

- `HYPER_INTENSIVE_3D_MEASUREMENT_MAPPING_PLAN.md`
- `CLIENT_ONBOARDING_MEASUREMENT_FORMS_PLAN.md`
