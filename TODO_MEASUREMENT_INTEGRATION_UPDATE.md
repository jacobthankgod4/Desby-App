# TODO: Complete Atomic Integration from GitHub Repo

## Overview
Update the existing ai-body-scan-saas to EXACTLY follow the GitHub repo: https://github.com/farazBhatti/Human-Body-Measurements-using-Computer-Vision

## GitHub Repo Structure (Exact Reference)

### Core Dependencies
- tensorflow-gpu==1.13.1 or tensorflow==1.13.1
- absl-py
- google-opencv-python==3.4.2
- numpy
- scikit-image
- scipy
- matplotlib
- Pillow

### Core Files to Copy/Integrate

| File | Purpose | Action |
|------|---------|--------|
| `inference.py` | DeepLab segmentation + HMR inference | INTEGRATE |
| `demo.py` | HMR 3D model running | INTEGRATE |
| `extract_measurements.py` | Measurement extraction from vertices | INTEGRATE |
| `utils.py` | Constants (M_STR, V_NUM, F_NUM, M_NUM) | INTEGRATE |
| `networks.py` | Neural network definitions | CHECK |
| `functions.py` | Helper functions | CHECK |
| `src/RunModel.py` | HMR model runner | INTEGRATE |
| `src/config.py` | Configuration | INTEGRATE |
| `src/data_loader.py` | Data loading | CHECK |
| `src/main.py` | Main entry point | CHECK |
| `src/models.py` | Model definitions | CHECK |

### Required Data Files (Must Download)
1. **HMR Model**: `wget https://people.eecs.berkeley.edu/~kanazawa/cachedir/hmr/models.tar.gz && tar -xf models.tar.gz`
   - Save to `models/` folder
   - Contains: hmr_model.ckpt.data-00000-of-00001, hmr_model.ckpt.index, hmr_model.ckpt.meta

2. **CustomBodyPoints**: Download from https://github.com/farazBhatti/Human-Body-Measurements-using-Computer-Vision/files/5886235/customBodyPoints.txt
   - Save to `data/customBodyPoints.txt`

3. **DeepLab Model**: Auto-downloaded by inference.py
   - Downloads from http://download.tensorflow.org/models/deeplabv3_xception_coco_voctrainval.tar.gz
   - Saves to `deeplab_model/`

## Measurement Extraction Pipeline (Exact)

```
1. Input Image
   ↓
2. DeepLab Segmentation (remove background)
   - inference.py: DeepLabModel class
   - Uses xception_coco_voctrainval model
   - Filters for person class (15)
   ↓
3. HMR 3D Reconstruction
   - demo.py: RunModel predict()
   - Uses pretrained hmr_model.ckpt
   - Returns vertices (6890 points), joints, camera
   ↓
4. Extract Measurements
   - extract_measurements.py: calc_measure()
   - Uses customBodyPoints.txt control points
   - 11 measurements from SMPL vertices
```

## Measurements Extracted (Exact from utils.py)

```python
M_STR = [
    "height",      # 0 - Used for scaling
    "waist",      # 1
    "belly",      # 2
    "chest",      # 3
    "wrist",     # 4
    "neck",      # 5
    "arm length",# 6
    "thigh",     # 7
    "shoulder width", # 8
    "hips",      # 9
    "ankle"      # 10
]
```

## Integration Steps

### Phase 1: Copy Core Files
- [ ] Copy extract_measurements.py to ai-body-scan-saas/api/services/
- [ ] Copy utils.py to ai-body-scan-saas/api/services/
- [ ] Copy demo.py to ai-body-scan-saas/api/services/
- [ ] Copy inference.py to ai-body-scan-saas/api/services/

### Phase 2: Install Dependencies
- [ ] Update requirements.txt with tensorflow==1.13.1 (or tensorflow-gpu)
- [ ] Update requirements.txt with opencv-python==3.4.2
- [ ] Add all other dependencies from GitHub requirements.txt

### Phase 3: Download Models
- [ ] Run download script for HMR model
- [ ] Download CustomBodyPoints.txt

### Phase 4: Fix Integration
- [ ] Fix measurement_engine.py to use HMR instead of just MediaPipe
- [ ] Ensure DeepLab segmentation is integrated
- [ ] Add fallback cascade: HMR → MediaPipe → ratio-based

### Phase 5: API Updates
- [ ] Update /measurements/extract route
- [ ] Add background removal preprocessing
- [ ] Update response format to match GitHub output
