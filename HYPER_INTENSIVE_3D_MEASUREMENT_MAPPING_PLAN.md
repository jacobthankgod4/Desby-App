# Hyper-Intensive Plan: Measurement-to-3D Body-Part Mapping, Precision Zoom, Rigging, and Advanced Algorithms

## 1) Objective

Design and implement a production-grade, cross-platform 3D measurement guidance system that:

- Maps **every measurement input** to a precise anatomical region on the mannequin.
- Applies **high-precision camera targeting and zoom framing** for each measurement.
- Supports **rig-aware highlighting** and local focus cues for body segments.
- Uses an **advanced adaptive mapping algorithm** to refine focus quality over time.
- Works reliably on:
  - **Web** (`model-viewer` module path)
  - **Mobile** (`o3d` package path)

---

## 2) Current State (What exists now)

### Existing strengths
- 3D model loads correctly with valid `.glb` assets.
- Per-field focus trigger exists (`onTap => _focusOn(label)`).
- Basic camera mappings are implemented in `_focusOn(String part)` with rough grouped focus presets.
- Gender-based model switching exists and works.

### Current gaps
- Mapping granularity is coarse (many measurements grouped under the same camera).
- No canonical body-landmark dictionary.
- No algorithmic calibration based on model bounding boxes / pose context.
- No rig-aware body segment metadata in code.
- No deterministic quality scoring loop for focus precision.
- No explicit fallbacks for unknown/custom measurement labels.
- No comprehensive measurement-to-focus test matrix.

---

## 3) Gap Workarounds & Execution Playbook (Immediate + Strategic)

This section is the direct workaround for each identified gap.

## 3.1 Gap: Coarse mapping granularity
### Workaround
Replace grouped `switch` handling with **per-measurement camera profiles**.

### Implementation Tasks
1. Create `measurement_camera_registry.dart` with one profile per measurement key.
2. Profile includes:
   - `cameraTarget(x,y,z)`
   - `cameraOrbit(theta,phi,radius)`
   - `fov`
   - `transitionMs`
   - `preferredView` (front/back/left/right/oblique)
3. Keep grouped profiles only as fallback.

### Acceptance Criteria
- Every visible measurement field has a unique profile ID.
- No field routes to default unless explicitly configured as fallback.

### Risk + Fallback
- Risk: too many hand-tuned profiles.
- Fallback: bootstrap from grouped defaults, then refine by telemetry.

---

## 3.2 Gap: No canonical body-landmark dictionary
### Workaround
Create a strict dictionary contract linking:
- measurement key -> landmark IDs
- landmark ID -> coordinates (+ optional segment tags)

### Implementation Tasks
1. Add `measurement_key.dart` enum-like constants.
2. Add `measurement_aliases.dart` for normalization.
3. Add `landmark_registry_male.dart`, `landmark_registry_female.dart`.

### Acceptance Criteria
- 100% measurement labels normalize to canonical keys or known fallback.
- No duplicate canonical key conflicts.

### Risk + Fallback
- Risk: naming drift from UI labels.
- Fallback: lint/check script to validate label registry parity.

---

## 3.3 Gap: No bbox/pose calibration
### Workaround
Use **region-size-aware zoom** from landmark clusters.

### Implementation Tasks
1. Add `regionBoundingRadius` per landmark cluster.
2. Compute radius: `r = clamp(k * regionRadius, minR, maxR)`.
3. Apply pose/view offsets:
   - back measurements -> theta + 180
   - side measurements -> theta ± 90

### Acceptance Criteria
- Focus framing keeps region centered and readable on first tap.
- Zoom level is measurement-appropriate (neck tighter than full torso).

### Risk + Fallback
- Risk: inconsistent model scales.
- Fallback: per-model calibration multipliers (`maleScaleK`, `femaleScaleK`).

---

## 3.4 Gap: No rig-aware segment metadata
### Workaround
Introduce a **rig metadata contract** independent of renderer limitations.

### Implementation Tasks
1. Define segment IDs and required metadata (see section 7).
2. Add optional segment highlight hooks.
3. If bone access unavailable, use overlay markers bound to landmarks.

### Acceptance Criteria
- Every measurement key maps to at least one segment ID.
- Highlight/overlay appears for focused segment in debug mode.

### Risk + Fallback
- Risk: limited runtime rig manipulation support.
- Fallback: marker/annotation overlays only.

---

## 3.5 Gap: No deterministic quality scoring loop
### Workaround
Add deterministic focus scoring on each camera jump.

### Implementation Tasks
1. Implement scoring formula (section 6).
2. Log score + chosen profile + fallback triggers.
3. Auto-fallback when score below threshold.

### Acceptance Criteria
- Every focus event produces score [0,1].
- Sub-threshold events trigger predictable fallback profile.

### Risk + Fallback
- Risk: false negatives on acceptable shots.
- Fallback: dynamic threshold per measurement family.

---

## 3.6 Gap: No unknown/custom label fallback
### Workaround
Add resolver chain: exact -> alias -> fuzzy -> family -> default.

### Implementation Tasks
1. Build `MeasurementResolver`.
2. Add unknown token parser and fuzzy matching (Levenshtein/token set ratio).
3. Route unresolved labels to safe default profile with UI hint.

### Acceptance Criteria
- Unknown labels never crash focus flow.
- Fallback message is non-blocking and actionable.

### Risk + Fallback
- Risk: wrong fuzzy matches.
- Fallback: require confidence threshold for fuzzy, else default profile.

---

## 3.7 Gap: No comprehensive test matrix
### Workaround
Create matrix-driven tests with mandatory row coverage for all measurements.

### Implementation Tasks
1. Build table `measurement_key x gender x platform x expected_profile`.
2. Unit tests for resolver + dictionary integrity.
3. Widget/integration tests for camera calls and fallback paths.

### Acceptance Criteria
- 100% measurement keys covered by automated matrix checks.
- Manual calibration checklist completed per platform.

### Risk + Fallback
- Risk: test maintenance burden.
- Fallback: generate tests from registry metadata.

---

## 4) Architecture Blueprint

## 4.1 New Core Components

1. **Measurement Ontology Layer**
   - Canonical taxonomy of measurement labels.
   - Normalization and aliasing policy.

2. **Body Landmark Registry**
   - Coordinate anchors for key anatomy regions.
   - Gender/model variants.

3. **Camera Profile Engine**
   - Named profile per measurement key.

4. **Adaptive Focus Optimizer**
   - Computes camera from landmarks, visibility, and context.

5. **Rig Interaction Layer**
   - Bone/segment highlight or overlay marker fallback.

6. **Quality Telemetry Loop**
   - Captures confidence and user correction signals.

---

## 5) Canonical Dictionary Contract (Strict)

## 5.1 Canonical Key Policy
- lowercase snake_case (`neck_round` -> `neck_circumference`)
- one semantic meaning per key
- no UI-facing strings as keys

## 5.2 Alias Policy
- aliases point to exactly one canonical key
- ambiguity disallowed unless confidence model resolves

## 5.3 Unknown Label Handling
Resolver order:
1. exact canonical
2. exact alias
3. normalized alias
4. fuzzy alias (confidence >= threshold)
5. measurement family fallback
6. global default (`upper_torso_default`)

## 5.4 Contract Checks
- no duplicate aliases
- no orphan canonical keys
- no unresolved visible UI labels

---

## 6) Deterministic Quality Scoring Spec

Define score per focus event:

`Q = w1*C + w2*V + w3*O + w4*S`

Where:
- `C` = center alignment score (distance of target from viewport center)
- `V` = estimated visible region ratio (projected region coverage)
- `O` = occlusion penalty inverted (1 - occlusion risk)
- `S` = stability score (camera transition smoothness / jerk)

Recommended initial weights:
- `w1=0.35`, `w2=0.30`, `w3=0.25`, `w4=0.10`

Thresholds:
- `Q >= 0.82`: excellent
- `0.70 <= Q < 0.82`: acceptable
- `Q < 0.70`: trigger fallback profile + optional hint

Telemetry payload:
- measurementKey, gender, profileId, Q, fallbackUsed, interactionLatencyMs

---

## 7) Rig Metadata Contract

Minimum fields per segment:
- `segmentId` (e.g., `SEG_NECK`, `SEG_CHEST`, `SEG_WAIST`)
- `boneNames[]` (if available)
- `landmarkIds[]`
- `preferredView`
- `highlightMode` (`bone`, `mesh`, `overlay`)
- `priority` (for multi-segment measurements)

If bone access unsupported:
- fallback to `overlay` with landmark markers + directional label.

---

## 8) Calibration Protocol (Bounding Box / Pose Context)

## 8.1 Inputs
- model global bounds
- segment/landmark cluster bounds
- current platform (web/mobile)
- measurement family type

## 8.2 Procedure
1. Start from base profile.
2. Compute regional radius from cluster bounds.
3. Apply family multiplier:
   - neck/head: 0.75
   - chest/waist: 1.00
   - hip/leg: 0.95
   - full-length: 1.25
4. Apply gender/model scale adjustment.
5. Validate score `Q`; iterate `theta/phi/radius` small-step search if below threshold.
6. Persist tuned profile if stable across N sessions.

---

## 9) Full Measurement Mapping Matrix (Canonical Families)

## 9.1 Upper Body
- Shoulder, Neck Round, Bust Round, Chest Round, High Bust, Under Bust, Bust Point, Across Chest, Across Back, Armhole Round

## 9.2 Torso & Waist
- Shoulder to Waist, Front Waist Length, Back Waist Length, Waist Round, Stomach Round, Half Length

## 9.3 Hip & Legs
- Waist to Hip, Upper Hip, Hip Round, Thigh Round, Knee Round, Calf Round, Ankle Round, Waist to Knee, Waist to Calf, Waist to Floor, Trouser Waist, Trouser Length, Inseam, Crotch Depth, Rise, Seat Round, Trouser Opening Width

## 9.4 Garment Specific
- Senator Length, Kaftan Length, Agbada Length, Agbada Sleeve Length, Jacket Length, Lapel Width, Jacket Sleeve Length, Vest Length, Shirt Length, Full Top Length

## 9.5 Corset/Female Specific
- Corset Front Length, Corset Side Length, Corset Back Length, Under Bust to Waist, Waist to Lower Corset Edge, Cup Size

---

## 10) Code-Level Implementation Plan

## 10.1 Files to Add
- `lib/features/clients/domain/model/measurement_key.dart`
- `lib/features/clients/domain/model/body_landmark.dart`
- `lib/features/clients/domain/model/camera_profile.dart`
- `lib/features/clients/domain/services/measurement_normalizer.dart`
- `lib/features/clients/domain/services/measurement_focus_resolver.dart`
- `lib/features/clients/domain/services/focus_quality_scorer.dart`
- `lib/features/clients/domain/services/focus_optimizer.dart`
- `lib/features/clients/presentation/data/measurement_mapping_registry.dart`
- `lib/features/clients/presentation/data/landmark_registry_male.dart`
- `lib/features/clients/presentation/data/landmark_registry_female.dart`
- `lib/features/clients/presentation/data/camera_profile_registry.dart`
- `lib/features/clients/presentation/controllers/measurement_focus_controller.dart`
- `lib/features/clients/presentation/widgets/measurement_focus_debug_overlay.dart`
- `docs/3D_MEASUREMENT_MAPPING_MATRIX.md`
- `docs/3D_RIGGING_CONTRACT.md`

## 10.2 Files to Modify
- `lib/features/clients/presentation/pages/unified_add_client_page.dart`
  - Replace `_focusOn` with controller pipeline:
    `normalize -> resolve -> optimize -> apply -> score -> fallback`.
  - Add unknown label safe handling.
  - Add debug overlay toggle.

---

## 11) Comprehensive Test Matrix (Thorough)

## 11.1 Automated Unit Tests
1. canonical dictionary integrity
2. alias resolution and fuzzy thresholds
3. landmark presence validation
4. profile validity (orbit/radius ranges)
5. deterministic quality scorer outputs

## 11.2 Widget/Integration Tests
1. tap each measurement -> expected profile call
2. gender switch -> registry swap correctness
3. unknown label -> fallback flow
4. rapid taps -> race-safe final camera state
5. score below threshold -> fallback activation

## 11.3 Manual Full Coverage
- Run through all measurement fields:
  - male flow
  - female flow
- Validate:
  - first-tap framing quality
  - segment highlight visibility
  - camera smoothness
- Platforms:
  - web (Chrome)
  - Android
  - iOS (if available)

## 11.4 Exit Criteria
- 100% measurement keys covered
- zero unresolved label crashes
- >=95% first-tap acceptable framing
- fallback path verified on all platforms

---

## 12) Rollout Plan with Feature Flags

### Flags
- `focus_v2_registry_enabled`
- `focus_quality_scorer_enabled`
- `focus_auto_fallback_enabled`
- `focus_rig_overlay_enabled`

### Phases
1. Shadow mode (log-only, no behavior change)
2. Internal QA enablement
3. Beta cohort rollout
4. Global rollout

### Rollback
- single-flag disable returns to legacy `_focusOn` mapping.
- preserve telemetry for postmortem calibration.

---

## 13) Performance & UX Targets
- Transition latency < 450ms
- FPS floor >= 45 during focus transitions
- score computation overhead < 5ms average
- no user-visible stutter on rapid taps

---

## 14) Risks & Mitigations
- Rig incompatibility -> overlay fallback
- scale mismatch -> per-model multipliers
- web/mobile divergence -> platform calibration tables
- fuzzy mismatch -> strict confidence gate
- complexity creep -> phased rollout and telemetry-driven tuning

---

## 15) Deliverables
- Canonical dictionary + alias resolver
- Full measurement-to-profile registry
- Focus optimizer + deterministic scorer
- Rig metadata contract and overlays
- Full matrix test suite and calibration report

---

## 16) Immediate Next Actions
1. Generate canonical keys from existing UI labels.
2. Create first-pass profile registry for all measurements.
3. Integrate controller pipeline into `unified_add_client_page.dart`.
4. Enable score logging and fallback trigger.
5. Execute full test matrix and tune top failing profiles.
