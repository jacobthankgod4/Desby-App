# AI BODY MEASUREMENT SYSTEM - ATOMIC IMPLEMENTATION PLAN

## ⚠️ PREMIUM FEATURE - PAID SUBSCRIBERS ONLY
This AI measurement feature is **EXCLUSIVE to paid subscribers** and NOT available for free users. Free users can only use manual measurement input.

---

## Overview
This plan integrates the [Human-Body-Measurements-using-Computer-Vision](https://github.com/farazBhatti/Human-Body-Measurements-using-Computer-Vision) GitHub repository as an AI-powered body measurement backend for the Desby App.

### Source Repository
- **URL**: https://github.com/farazBhatti/Human-Body-Measurements-using-Computer-Vision
- **Author**: Faraz Bhatti
- **Technology**: TensorFlow 1.x, HMR (Human Mesh Regression), SMPL 3D Model, DeepLab segmentation

### How It Works
1. User uploads a front photo (full-body)
2. User provides their height (needed for scale)
3. Backend processes image using DeepLab → HMR → SMPL 3D reconstruction
4. Control points extract body measurements from 3D mesh
5. Returns measurements scaled to user's height

---

## PHASE 1: BACKEND INFRASTRUCTURE SETUP

### Step 1.1: Create Python Backend Service
```
Task: Create Flask/FastAPI backend service
File: backend/ai_measurement_service.py
Location: /backend/ai_measurement_service.py
```

```python
# Requirements
- flask / fastapi
- tensorflow==1.13.1 (or updated version)
- opencv-python
- numpy==1.16.1
- pillow
- scipy==1.2.1
- scikit-image
```

### Step 1.2: Set Up Model Download Scripts
```
Task: Automate downloading pre-trained models
Files:
  - backend/download_models.py
  - backend/models/ (directory for model files)
```

### Step 1.3: Create Measurement API Endpoints
```
Task: Create REST API endpoints
Endpoints:
  POST /api/measurements/extract
  GET /api/measurements/status
  POST /api/measurements/verify
```

---

## PHASE 2: TENSORFLOW MIGRATION (Modernization)

### Step 2.1: Update TensorFlow Version
```
Issue: TensorFlow 1.x is deprecated and incompatible
Solution: Migrate to TensorFlow 2.x with compatibility layer

Task: Update requirements.txt
File: backend/requirements.txt
Changes:
  - tensorflow==1.13.1 → tensorflow>=2.10.0
  - Update all TF-dependent imports
```

### Step 2.2: Fix Breaking Changes
```
Task: Fix TensorFlow 2.x breaking changes
Updates needed:
  - tf.Session() → tf.compat.v1.Session() or eager execution
  - tf.placeholder() → tf.compat.v1.placeholder()
  - Update Slim APIs
```

### Step 2.3: Create Model Download Automation
```
Task: Script to download HMR and DeepLab models
Files:
  - backend/scripts/download_hmr.py
  - backend/scripts/download_deeplab.py
```

---

## PHASE 3: MEASUREMENT EXTENSION

### Step 3.1: Expand Control Points
```
Issue: Current system outputs only 11 measurements
Solution: Extend control points to match your 18-27 measurements

Current outputs:
- height, waist, belly, chest, wrist, neck, arm length, thigh, shoulder width, hips, ankle

Your app needs (Male - 18):
- Shoulder, Neck Round, Chest Round, Stomach Round, Waist Round,
- Half Length, Full Top Length, Across Back, Across Chest, Hip Round,
- Thigh Round, Knee Round, Calf Round, Ankle Round, Trouser Waist,
- Trouser Length, Inseam, Crotch Depth

Your app needs (Female - 27):
- Shoulder, Neck Round, Bust Round, High Bust, Under Bust,
- Bust Point, Shoulder to Bust Point, Shoulder to Under Bust,
- Shoulder to Waist, Front Waist Length, Back Waist Length,
- Across Chest, Across Back, Armhole Round, Sleeve Length,
- Bicep Round, Elbow Round, Wrist Round, Waist Round,
- Half Length, Waist to Hip, Upper Hip, Hip Round,
- Thigh Round, Knee Round, Calf Round, Ankle Round

Task: Create extended control points file
File: backend/data/customBodyPoints_extended.txt
```

### Step 3.2: Add Gender Differentiation
```
Task: Add male/female control point variants
Files:
  - backend/data/customBodyPoints_male.txt
  - backend/data/customBodyPoints_female.txt
```

### Step 3.3: Create Measurement Mapping
```
Task: Map AI outputs to your app measurements
File: backend/utils/measurement_mapper.py
```

---

## PHASE 4: FLUTTER INTEGRATION

### Step 4.1: Create Measurement Service Client
```
Task: Create Flutter service to call backend
File: lib/core/services/ai_body_measurement_service.dart
Features:
  - Image upload with crop guidance
  - Height input
  - API call handling
  - Response parsing
```

### Step 4.2: Add UI for AI Measurement Capture
```
Task: Create photo capture flow
File: lib/features/designs/presentation/pages/ai_measurement_page.dart
Features:
  - Front photo capture
  - Photo quality check
  - Height input
  - Loading/processing UI
  - Results display with edit capability
```

### Step 4.3: Integrate with Existing Measurement Page
```
Task: Add AI measurement option to measurement_input_page.dart
Features:
  - "Auto-Measure with AI" button
  - Hybrid flow: AI + manual verification
```

---

## PHASE 5: IMAGE PROCESSING

### Step 5.1: Add Photo Guidance Overlay
```
Task: Guide user to take proper photo
Features:
  - Front-facing full-body pose
  - Good lighting
  - Tight clothing
  - Neutral background
  - Overlay guide in camera UI
```

### Step 5.2: Add Image Preprocessing
```
Task: Create image preprocessing pipeline
Features:
  - Auto crop to person
  - Background removal (DeepLab)
  - Resize to optimal dimensions
  - Quality validation
```

### Step 5.3: Add Error Handling
```
Task: Handle photo quality issues
Features:
  - Blur detection
  - Lighting check
  - Pose detection
  - Re-capture prompts
```

---

## PHASE 6: API SERVICE DEPLOYMENT

### Step 6.1: Docker Containerize
```
Task: Create Docker container for backend
Files:
  - backend/Dockerfile
  - backend/docker-compose.yml
```

### Step 6.2: Set Up Cloud Hosting
```
Task: Deploy to cloud service
Options:
  - Google Cloud Run
  - AWS Lambda + API Gateway
  - Heroku
  - Railway
  - Render
```

### Step 6.3: Add Rate limiting & Security
```
Task: Secure API endpoints
Features:
  - API key authentication
  - Rate limiting
  - Image size limits
  - Request timeout handling
```

---

## PHASE 7: TESTING & OPTIMIZATION

### Step 7.1: Accuracy Testing
```
Task: Test measurement accuracy
Method:
  - Compare AI measurements vs manual
  - Calculate error margins
  - Refine control points
```

### Step 7.2: Performance Optimization
```
Task: Reduce inference time
Current: ~10-15 seconds
Target: <5 seconds
Methods:
  - Model optimization
  - Caching
  - Async processing
```

### Step 7.3: User Experience Polish
```
Task: Improve UI/UX
Features:
  - Better loading states
  - Progress indicators
  - Error recovery
  - Verification flow
```

---

## IMPLEMENTATION ORDER

### Phase 1 (Days 1-3): Backend Setup
- [ ] Set up Python environment
- [ ] Clone and test source repo
- [ ] Download models

### Phase 2 (Days 4-7): TensorFlow Migration
- [ ] Update TensorFlow version
- [ ] Fix compatibility issues
- [ ] Test inference

### Phase 3 (Days 8-14): Measurement Extension
- [ ] Add extended control points
- [ ] Create gender variants
- [ ] Test all measurements

### Phase 4 (Days 15-21): Flutter Integration
- [ ] Create backend API
- [ ] Flutter service client
- [ ] Photo capture UI

### Phase 5 (Days 22-25): Image Processing
- [ ] Photo guidance
- [ ] Preprocessing
- [ ] Quality checks

### Phase 6 (Days 26-30): Deployment
- [ ] Dockerize
- [ ] Deploy to cloud
- [ ] Add security

### Phase 7 (Days 31-35): Testing
- [ ] Accuracy testing
- [ ] Performance optimization
- [ ] UX polish

---

## MONETIZATION (PAID SUBSCRIBERS ONLY)

### Access Control
This AI measurement feature is **EXCLUSIVE to paid subscribers** only and NOT available for free users.

### Subscription Tiers
| Tier | Access | Included Scans |
|------|--------|----------------|
| **Free** | Manual measurement only | 0 |
| **Basic** | AI Measurement + Manual | 3/month |
| **Premium** | AI Measurement + Manual | 10/month |
| **Enterprise** | Unlimited AI + Priority | Unlimited |

### API Key Authentication
```
Task: Add subscription check to API
File: backend/middleware/subscription_check.py
Logic:
  1. Validate API key from Flutter request
  2. Check subscription status in database
  3. Verify scan quota remaining
  4. Allow/Deny access
  5. Track usage for billing
```

### Usage Tracking
```
Task: Track AI measurement usage
Database: Firestore collection 'subscription_usage'
Fields:
  - user_id
  - scans_used_this_month
  - scans_remaining
  - last_scan_timestamp
  - subscription_tier
```

### Implementation Steps Added

#### Phase 8: Subscription Integration (Days 36-42)

##### Step 8.1: Add Subscription Check Middleware
```
Task: Create subscription validation middleware
File: backend/middleware/subscription_check.py
Features:
  - API key validation
  - Tier-based access control
  - Quota tracking
  - Usage logging
```

##### Step 8.2: Update Flutter Service Client
```
Task: Add subscription check to AI service
File: lib/core/services/ai_body_measurement_service.dart
Updates:
  - Check subscription before calling API
  - Show upgrade prompt for free users
  - Display remaining scans for paid users
```

##### Step 8.3: Add Upgrade Prompt UI
```
Task: Create subscription upgrade flow
File: lib/features/payments/presentation/pages/ai_measurement_upgrade_page.dart
Features:
  - "Premium Feature" badge
  - Scan count display
  - Upgrade CTA button
  - Comparison with manual input
```

##### Step 8.4: Integrate with Subscription System
```
Task: Connect to existing subscription provider
Files to update:
  - lib/features/payments/presentation/providers/subscription_provider.dart
  - lib/features/payments/data/repositories/firebase_subscription_repository.dart
```

---

## DEPENDENCIES

### Python Backend Dependencies
```
tensorflow>=2.10.0
opencv-python
numpy
pillow
scipy
scikit-image
flask
werkzeug
```

### Flutter Dependencies
```
dio: ^5.0.0  # HTTP client
image_picker: ^1.0.0  # Photo capture
```

---

## FILES TO CREATE

### Backend Files
1. `backend/ai_measurement_service.py` - Main Flask API
2. `backend/requirements.txt` - Python dependencies
3. `backend/download_models.py` - Model download script
4. `backend/data/customBodyPoints_extended.txt` - Extended measurements
5. `backend/utils/measurement_mapper.py` - Measurement mapping
6. `backend/Dockerfile` - Container configuration
7. `backend/tests/test_accuracy.py` - Accuracy tests

### Flutter Files
1. `lib/core/services/ai_body_measurement_service.dart` - Service client
2. `lib/features/designs/presentation/pages/ai_measurement_page.dart` - UI
3. `lib/core/widgets/photo_guide_overlay.dart` - Photo guidance

---

## SUCCESS CRITERIA

- ✅ API responds within 10 seconds
- ✅ Accuracy within ±5cm for all measurements
- ✅ Works on both iOS and Android
- ✅ Hybrid flow: AI + manual verification available
- ✅ Gender-specific measurements

---

## RISKS & MITIGATION

| Risk | Mitigation |
|------|-----------|
| TensorFlow migration issues | Use TF 1.x compatibility mode initially |
| Model download failures | Add retry logic, fallback URLs |
| Accuracy not production-ready | Keep manual input as fallback |
| Slow inference | Async processing, background tasks |
| Cloud costs | Implement caching, free tier limits |
