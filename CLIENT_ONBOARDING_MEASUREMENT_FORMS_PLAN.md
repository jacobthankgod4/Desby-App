# Desby Client Onboarding: Measurement Forms Plan (Women + Men)

## 0) Goal
Integrate Desby’s **Women’s** and **Men’s** measurement forms into the existing **client onboarding flow** so users can:
- Enter structured measurements across a large set of fields.
- Tap fields to **focus the 3D mannequin** on the relevant body part.
- Maintain consistent UX on **desktop + mobile**.
- Save results into your current `Client` + order workflow.
- Keep the process resilient (save progress locally; upload later).

---

## 1) Current Reality (What you already have)
Your current implementation in:
- `lib/features/clients/presentation/pages/unified_add_client_page.dart`

Already includes:
- A **multi-step** onboarding screen using `PageController` (`PageView`), where one step is dedicated to **measurements**.
- An **O3D mannequin** with a controller and logic to focus on body parts.
- A **HUD** style pattern (amber/overlay feedback) tied to the measurement selection.

✅ This is a strong foundation.

---

## 2) What “revamping” means (scope)
You do **not** necessarily need to rebuild the entire onboarding flow, but you **will** need to revamp the **measurement step** into a **wizard/sub-step system** because:
- Women’s measurement list alone is very large.
- Each field should map to mannequin focus + proper validation.
- A single flat grid becomes unmanageable and breaks UX.

**Therefore:**
- Keep your existing onboarding outer structure.
- Replace/extend the “measurement step” into a **Women/Men Measurement Wizard** with sub-steps.

---

## 3) UX Architecture (Recommended)
### 3.1 Outer onboarding flow (existing)
Keep:
1. Identity Verification
2. Project Definition (garment/outfit + date details)
3. Measurement Wizard (updated)

### 3.2 Inner measurement wizard (new)
Add a sub-step navigator within step #3.

#### Step pattern
- Sidebar/Stepper (desktop)
- Vertical progress / section headers (mobile)

Each sub-step must include:
- Required fields + validation rules
- Mannequin tap-to-focus mapping
- Navigation actions: Next/Back
- Optional “Skip / continue later” for uploads/AI section

---

## 4) Data Model Plan (typed draft + unit normalization)
### 4.1 Create a single draft model
Example:
- `MeasurementDraft`
  - personal: fullName, phone, email, eventDate, deliveryDate, unit
  - womenUpperBody / womenWaistHip / womenLeg / womenFullLength / womenCorset / womenStyle
  - menUpperBody / menLowerBody / menNativeWear / menSuit
  - photos: inspirationPhoto1, inspirationPhoto2, fabricPhoto
  - notes

### 4.2 Normalize units
- When unit selection changes (Inches vs Centimeters):
  - Convert to a canonical unit immediately for storage (choose one, ideally **centimeters**).
  - Store both the canonical value and optionally the original display unit.

### 4.3 Map into existing `Client` entity
You already store measurements as a map (`Map<String, String>`). Extend keys consistently.

**Recommended approach:**
- Use canonical measurement keys (stable identifiers)
- Store numeric values as strings (until you refactor storage type)

Example keys for women:
- `shoulder`, `neck_round`, `bust_round`, `under_bust`, `bust_point`, …

And for men:
- `shoulder`, `neck_round`, `chest_round`, `waist_round`, `hip_round`, …

---

## 5) Mannequin Integration Plan (tap-to-focus)
### 5.1 Field-to-focus schema
Define for every measurement field:
- `label`
- `key` (measurement id)
- `cameraPreset` (Front / Side / Back)
- `hudPlacementKey` (which overlay/amber line rule to use)
- `valueValidator`

When user taps/focuses a field:
1. Update active part
2. Call `_o3dController.cameraTarget(...)`
3. Call `_o3dController.cameraOrbit(...)`

### 5.2 Camera constraints
Ensure no top-down/pitched camera behavior:
- Restrict elevation/pitch to 0 or a strictly controlled range.
- Ensure **both**:
  - initial O3D configuration
  - all `_focusOn(part)` transitions
  use the same “no top-down” constraints.

### 5.3 HUD placement
Keep HUD amber line consistent:
- Use deterministic mapping from viewport size to overlay rect coordinates.
- Calibrate once per mannequin scale.

---

## 6) Women’s Measurement Form Layout (Sub-step Design)
### 6.1 Women: Form layout (as you provided)
#### Personal Information
1. Full Name
2. Phone Number
3. Email Address
4. Event Date
5. Delivery Date
6. Preferred Measurement Unit (Inches/Centimeters)

#### Upper Body Measurements
1. Shoulder
2. Neck Round
3. Bust Round
4. High Bust
5. Under Bust
6. Bust Point (Nipple to Nipple)
7. Shoulder to Bust Point
8. Shoulder to Under Bust
9. Shoulder to Waist
10. Front Waist Length
11. Back Waist Length
12. Across Chest
13. Across Back
14. Armhole Round
15. Sleeve Length
16. Bicep Round
17. Elbow Round
18. Wrist Round

#### Waist and Hip Measurements
19. Waist Round
20. Half Length
21. Waist to Hip
22. Upper Hip
23. Hip Round
24. Thigh Round
25. Knee Round
26. Calf Round
27. Ankle Round

#### Full Length Measurements
28. Waist to Knee
29. Waist to Calf
30. Waist to Floor
31. Full Dress Length
32. Skirt Length
33. Wrapper Length

#### Corset Measurements
34. Corset Front Length
35. Corset Side Length
36. Corset Back Length
37. Under Bust to Waist
38. Waist to Lower Corset Edge
39. Cup Size

#### Style Preferences
1. Outfit Type (Gown, Corset Dress, Bubu, Iro & Buba, Jumpsuit)
2. Neckline Style
3. Sleeve Style
4. Back Style
5. Slit Height
6. Train Length
7. Preferred Heel Height
8. Fit Preference (Tight, Moderate, Relaxed)
9. Fabric Type
10. Lining Preference

#### Upload Section (or Ai)
1. Inspiration Photo 1
2. Inspiration Photo 2
3. Fabric Photo 4
4. Additional Notes

---

### 6.2 Women: Recommended sub-step grouping
To implement this cleanly, split into these wizard sections:
1. Personal & Unit
2. Upper Body (1–18)
3. Waist/Hip & Leg Rounds (19–27)
4. Full Length (28–33)
5. Corset (34–39)
6. Style Preferences (outfit + styles + preferences)
7. Uploads & Notes (optional / later)

Each section can map to mannequin focus differently:
- Upper Body → front/side/back presets
- Waist/Hip → front/back/side presets
- Full length → back outline + leg focus
- Corset → front/side/back presets

---

### 6.3 Women: Size charts included
Include these tables in an “Info” modal/side panel during onboarding.

**Standard Nigerian Women’s Size Chart (UK 6–24)**
| UK Size | Bust (in) | Waist (in) | Hip (in) |
|--------:|-----------:|-----------:|----------:|
| 6 | 32 | 24 | 34 |
| 8 | 34 | 26 | 36 |
| 10 | 36 | 28 | 38 |
| 12 | 38 | 30 | 40 |
| 14 | 40 | 32 | 42 |
| 16 | 42 | 34 | 44 |
| 18 | 44 | 36 | 46 |
| 20 | 46 | 38 | 48 |
| 22 | 48 | 40 | 50 |
| 24 | 50 | 42 | 52 |

**Nigerian Ready-to-Wear Size Labels**
| Label | UK Size Range |
|-------|---------------:|
| XS | 6–8 |
| S | 10–12 |
| M | 14–16 |
| L | 18–20 |
| XL | 22–24 |

---

## 7) Men’s Measurement Form Layout (Sub-step Design)
### 7.1 Men: Form layout (as you provided)
#### Personal Information
1. Full Name
2. Phone Number
3. Email Address
4. Event Date
5. Delivery Date
6. Preferred Measurement Unit (Inches/Centimeters)

#### Upper Body Measurements
1. Shoulder
2. Neck Round
3. Chest Round
4. Stomach Round
5. Waist Round
6. Half Length (Shoulder to Waist)
7. Full Top Length
8. Across Back
9. Across Chest
10. Armhole Round
11. Sleeve Length
12. Bicep Round
13. Elbow Round
14. Wrist Round
15. Shirt Length

#### Lower Body Measurements
16. Hip Round
17. Thigh Round
18. Knee Round
19. Calf Round
20. Ankle Round
21. Trouser Waist
22. Trouser Length
23. Inseam
24. Crotch Depth
25. Rise
26. Seat Round

#### Native Wear Measurements
27. Senator Length
28. Kaftan Length
29. Agbada Length
30. Agbada Sleeve Length
31. Wrapper Length (if applicable)

#### Suit Measurements
32. Jacket Length
33. Lapel Width (optional)
34. Jacket Sleeve Length
35. Trouser Opening Width
36. Vest Length

---

### 7.2 Men: Recommended sub-step grouping
1. Personal & Unit
2. Upper Body (shoulder → shirt length)
3. Lower Body (hip → ankle)
4. Native Wear (senator/kaftan/agbada/wrapper)
5. Suit (jacket/trouser/vest)
6. Style Preferences & Fit
7. Uploads & Notes (optional)

---

### 7.3 Men: Size charts included
**Standard Nigerian Men’s Size Chart**
| Size | Chest (in) | Waist (in) | Hip (in) |
|------|------------:|------------:|----------:|
| XS | 34–36 | 28–30 | 34–36 |
| S | 36–38 | 30–32 | 36–38 |
| M | 38–40 | 32–34 | 38–40 |
| L | 40–42 | 34–36 | 40–42 |
| XL | 42–44 | 36–38 | 42–44 |
| XXL | 44–46 | 38–40 | 44–46 |
| 3XL | 46–48 | 40–42 | 46–48 |
| 4XL | 48–50 | 42–44 | 48–50 |

**Nigerian Men’s Ready-to-Wear Size Labels**
| Label | Chest (in) | Waist (in) | Equivalent Size |
|-------|------------:|------------:|-------------------|
| XS | 34–36 | 28–30 | Small Slim Fit |
| S | 36–38 | 30–32 | Small |
| M | 38–40 | 32–34 | Medium |
| L | 40–42 | 34–36 | Large |
| XL | 42–44 | 36–38 | Extra Large |
| XXL | 44–46 | 38–40 | Double XL |
| 3XL | 46–48 | 40–42 | Triple XL |
| 4XL | 48–50 | 42–44 | Quad XL |

---

## 8) Validation Strategy (staged gating)
### 8.1 Required vs optional
Mark:
- Personal fields required: name, phone, email, unit, dates
- Measurement anchors required early (minimum set)
- Upload fields optional

### 8.2 Progressive unlock
Example:
- Sub-step 2 (Upper Body) cannot complete unless minimum anchors exist.
- Later steps become optional when enough data exists for garment estimation.

### 8.3 Unit-aware validators
All validators must run on canonical values.

---

## 9) Persistence & Offline Resilience
### 9.1 Local draft save
- Save after each field change or at least each sub-step completion.
- Store in Hive/shared_preferences.

### 9.2 Final submission
- On submit:
  - validate all required
  - map to `Client`
  - create `Order` entity
  - store measurement + preferences

### 9.3 Upload later
- Store upload placeholders.
- Resume upload in background when network available.

---

## 10) Implementation Checklist (Actionable)
1. **Create wizard UI** inside client onboarding measurement step.
2. **Build schema** for Women fields + Men fields:
   - label
   - key
   - required
   - cameraPreset
   - hudCalibrationKey
3. **Implement unit normalization** (inches ↔ cm).
4. **Map field taps** → mannequin focus presets.
5. **Integrate validation** per sub-step.
6. **Persist draft locally**.
7. **Map schema into your `Client.measurements` storage**.
8. Add Info modal for size charts.
9. Add uploads/AI section with non-blocking UX.

---

## 11) Suggested Files to Add/Refactor
(Names are suggestions; align with your architecture.)
- `lib/features/clients/presentation/pages/women_measurement_wizard_page.dart`
- `lib/features/clients/presentation/pages/men_measurement_wizard_page.dart`
- `lib/features/clients/domain/models/measurement_draft.dart`
- `lib/features/clients/domain/models/measurement_schema.dart`
- `lib/features/clients/data/mappers/measurement_draft_mapper.dart`
- `lib/features/clients/presentation/widgets/mannequin_measurement_picker.dart`
- `lib/features/clients/presentation/widgets/measurement_field_widget.dart`

---

## 12) Outcome
By following this plan:
- Women and Men flows share the same technical backbone.
- UX remains coherent despite large measurement lists.
- O3D mannequin integration remains predictable.
- Your backend receives consistent measurement data.

