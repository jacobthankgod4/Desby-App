# Step 14: Risks & Mitigations

## Overview
This document outlines identified risks and their mitigations for the 3D Measurement Focus System.

---

## Risk 1: Rig Incompatibility

**Risk**: Limited runtime rig manipulation support on some platforms/browsers.

**Mitigation**: 
- Implemented overlay fallback in `FocusFeatureFlags.focusRigOverlayEnabled`
- Use marker/annotation overlays bound to landmarks when bone access unavailable

**Status**: ✅ Implemented via `focus_rig_overlay` feature flag

---

## Risk 2: Scale Mismatch

**Risk**: Inconsistent model scales across different .glb assets.

**Mitigation**:
- Per-model calibration multipliers (`maleScaleK`, `femaleScaleK`)
- Implemented in `FocusOptimizer` class

**Status**: ✅ Implemented in `focus_optimizer.dart`

---

## Risk 3: Web/Mobile Divergence

**Risk**: Platform-specific behavior differences between web and mobile.

**Mitigation**:
- Platform calibration tables in `CameraProfile` 
- Separate orbit/radius ranges per platform

**Status**: ✅ Implemented in `camera_profile.dart`

---

## Risk 4: Fuzzy Mismatch

**Risk**: Wrong fuzzy matches for similar measurement labels.

**Mitigation**:
- Strict confidence threshold (0.70) for fuzzy matching
- Falls back to family default if below threshold

**Status**: ✅ Implemented in `measurement_normalizer.dart`

---

## Risk 5: Complexity Creep

**Risk**: New features causing code bloat and maintenance burden.

**Mitigation**:
- Phased rollout via feature flags
- Telemetry-driven tuning
- Shadow mode for testing

**Status**: ✅ Implemented via `FocusFeatureFlags`

---

## Monitoring & Rollback

Each risk is monitored via:
- Focus quality scores (Q values)
- Fallback trigger counts
- Platform-specific telemetry

Rollback: Disable single feature flag to return to legacy behavior.

---

## Related Files

- `lib/features/clients/presentation/state/focus_feature_flags.dart`
- `lib/features/clients/domain/services/focus_optimizer.dart`
- `lib/features/clients/domain/model/camera_profile.dart`
