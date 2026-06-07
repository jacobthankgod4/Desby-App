# AI Body Measurement System - Documentation
## Last Updated: 2024-05-29

---

## Architecture Overview

### System Components

| Component | Location | Type | Status |
|-----------|----------|------|--------|
| Mobile App | `/Users/mac/desby_app` | Flutter | ✅ Complete |
| AI API Service | `/Users/mac/ai-body-scan-saas` | FastAPI + Vercel | ✅ Complete |
| Reference Backend | `/Users/mac/desby_app/backend` | Flask + Express | 🔶 Reference |

---

## Integration Flow

```
┌─────────────────────────────────────────────────────────────┐
│                        desby_app                           │
│                    (Flutter Mobile App)                     │
└─────────────────────┬───────────────────────────────────────┘
                     │ Environment.aiScanApiBaseUrl
                     │ X-API-Key header
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                    ai-body-scan-saas                       │
│                 (FastAPI /api/v2 endpoints)                │
│                                                             │
│  ┌────────────────────────────────────────────────────────┐  │
│  │           CASCADE PIPELINE                         │  │
│  │  1. HMR 3D (±1-2cm)    [TensorFlow + SMPL]  │  │
│  │  2. MediaPipe (±3-5cm)   [Google Pose]        │  │
│  │  3. Ratios (±5-10cm)     [Fallback]         │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌────────────────────────────────────────────────────────┐  │
│  │           MIDDLEWARE                                 │  │
│  │  • API Key Auth (subscription_check.py)              │  │
│  │  • Rate Limiter (rate_limiter.py)                   │  │
│  └────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## API Endpoints

### Base URL
- **Development:** `http://localhost:5001`
- **Production:** `https://ai-body-scan-saas.vercel.app` (to be deployed)

### Endpoints

| Method | Path | Auth | Description |
|--------|------|------|------------|
| GET | `/api/v2/health` | No | Health check |
| POST | `/api/v2/measurements/extract` | API Key | Extract from dual photos |
| POST | `/api/v2/measurements/estimate` | API Key | Estimate from height |
| GET | `/api/v2/subscriptions/status` | API Key | Get subscription status |
| POST | `/api/v2/payments/verify` | API Key | Verify payment |

---

## Flutter Client Integration

### Service File
```dart
// lib/core/services/body_measurement_service.dart

class BodyMeasurementService {
  String get _baseUrl => Environment.current.aiScanApiBaseUrl;
  
  Future<MeasurementResult> extractFromPhotos({
    required File frontImage,
    required File sideImage,
    required double heightCm,
    required String gender,
  }) async {
    // Uses Environment.aiScanApiBaseUrl (from .env)
    // Uses X-API-Key header
  }
}
```

### Environment Configuration
```dart
// lib/config/environment.dart

String get aiScanApiBaseUrl =>
    _getEnv('AI_SCAN_API_URL') ?? 'http://localhost:5001';
```

---

## Measurement Output

### Male (18 measurements)
```json
{
  "Shoulder": 45.2,
  "Neck Round": 38.2,
  "Chest Round": 100.0,
  "Stomach Round": 85.0,
  "Waist Round": 80.1,
  "Half Length": 60.0,
  "Full Top Length": 75.0,
  "Across Back": 42.0,
  "Across Chest": 44.0,
  "Hip Round": 95.0,
  "Thigh Round": 55.1,
  "Knee Round": 38.1,
  "Calf Round": 36.0,
  "Ankle Round": 26.0,
  "Trouser Waist": 82.0,
  "Trouser Length": 100.0,
  "Inseam": 78.0,
  "Crotch Depth": 28.0
}
```

### Female (27 measurements)
```json
{
  "Shoulder": 39.1,
  "Neck Round": 35.0,
  "Bust Round": 88.6,
  "High Bust": 78.2,
  "Under Bust": 70.0,
  "Bust Point": 20.6,
  "Shoulder to Bust Point": 24.7,
  "Shoulder to Under Bust": 28.9,
  "Shoulder to Waist": 39.1,
  "Front Waist Length": 37.1,
  "Back Waist Length": 41.1,
  "Across Chest": 35.0,
  "Across Back": 33.0,
  "Armhole Round": 41.1,
  "Sleeve Length": 56.6,
  "Bicep Round": 28.9,
  "Elbow Round": 24.7,
  "Wrist Round": 18.5,
  "Waist Round": 68.0,
  "Half Length": 53.6,
  "Waist to Hip": 18.5,
  "Upper Hip": 88.6,
  "Hip Round": 96.9,
  "Thigh Round": 53.6,
  "Knee Round": 35.0,
  "Calf Round": 33.0,
  "Ankle Round": 22.6
}
```

---

## Subscription Tiers

| Tier | Monthly Scans | Price (₦) | Features |
|------|---------------|-----------|----------|
| Free | 0 | 0 | Manual input only |
| Pro | 50 | 5,000 | AI + Manual |
| Business | 200 | 12,000 | Full AI |
| Elite | 500 | 25,000 | Premium |

### API Key Management
- Keys stored in: `ai-body-scan-saas/data/api_keys.json`
- Usage logged in: `ai-body-scan-saas/data/usage_log.json`

---

## Cascade Pipeline Details

### Tier 1: HMR 3D (Best Accuracy: ±1-2cm)
- **Model:** TensorFlow + SMPL 3D mesh
- **Input:** Person-segmented image
- **Output:** 6890 vertices → 18-27 measurements
- **File:** `api/services/extract_measurements.py`
- **Model files:** `models/model.ckpt-667589` (or `hmr_model.ckpt`)

### Tier 2: MediaPipe Pose (Medium: ±3-5cm)
- **Model:** Google MediaPipe Pose Landmarker
- **Input:** Full-body photo
- **Output:** 33 landmarks → proportional measurements
- **File:** `api/services/mediapipe_measurement_engine.py`
- **Model files:** `models/pose_landmarker_full.task`

### Tier 3: Anthropometric Ratios (Fallback: ±5-10cm)
- **Method:** Height-based ratios (no AI)
- **Input:** User height + gender
- **Output:** Proportional calculations
- **Always available** as final fallback

---

## File Structure

### ai-body-scan-saas/
```
ai-body-scan-saas/
├── api/
│   ├── __init__.py
│   ├── main.py                 # FastAPI entry point
│   ├── models/
│   │   └── schemas.py         # Pydantic models
│   ├── routes/
│   │   ├── __init__.py
│   │   ├── health.py         # GET /api/v2/health
│   │   ├── measurements.py # POST /api/v2/measurements/*
│   │   ├── subscriptions.py # GET /api/v2/subscriptions/*
│   │   └── payments.py     # POST /api/v2/payments/*
│   └── services/
│       ├── __init__.py
│       ├── measurement_engine.py    # Main cascade logic
│       ├── extract_measurements.py   # HMR 3D extraction
│       └── mediapipe_measurement_engine.py  # MediaPipe extraction
├── middleware/
│   ├── __init__.py
│   ├── subscription_check.py  # API key validation
│   ├── api_key_auth.py       # Auth middleware
│   └── rate_limiter.py      # Rate limiting
├── data/
│   ├── api_keys.json        # API key storage
│   ├── usage_log.json      # Usage tracking
│   └── customBodyPoints.txt # Control points
├── models/                 # HMR + MediaPipe models (downloaded)
├── scripts/
│   ├── init_db.py
│   └── download_models.py
├── tests/
│   ├── test_api.py
│   └── test_measurements.py
├── requirements.txt
├── runtime.txt
├── vercel.json
├── Dockerfile
└── README.md
```

---

## Setup Instructions

### 1. Clone & Install
```bash
cd ai-body-scan-saas
pip install -r requirements.txt
```

### 2. Download Models
```bash
python scripts/download_models.py
# Downloads HMR checkpoint + MediaPipe model
```

### 3. Run Local
```bash
python -m uvicorn api.main:app --reload --port 5001
```

### 4. Test Health
```bash
curl http://localhost:5001/api/v2/health
```

### 5. Initialize API Keys
```bash
python scripts/init_db.py
```

---

## Environment Variables

### desby_app (.env)
```
AI_SCAN_API_URL=http://localhost:5001
```

### ai-body-scan-saas (.env)
```
# Add any secrets for production
PAYSTACK_SECRET_KEY=sk_test_xxx
```

---

## Testing

### Local Test
```bash
# In ai-body-scan-saas directory
python test_local.py
```

---

## Known Issues

### 1. HMR Model Naming
- May need to check multiple checkpoint patterns:
  - `hmr_model.ckpt.index`
  - `model.ckpt-667589.index`
- Fixed in `api/routes/health.py`

### 2. Single Photo Mode
- Currently requires BOTH front + side photos for ±1-3cm accuracy
- Single photo has lower accuracy (±5-10cm)

### 3. TensorFlow 1.x Compatibility
- Original HMR model uses TensorFlow 1.x
- Use `tensorflow.compat.v1` if running TF2

---

## Deployment

### Vercel
```bash
cd ai-body-scan-saas
vercel deploy --prod
```

### Docker
```bash
cd ai-body-scan-saas
docker build -t ai-body-scan-saas .
docker run -p 5001:5001 ai-body-scan-saas
```

---

## Documentation History

| File | Status | Description |
|------|--------|------------|
| `AI_BODY_MEASUREMENT_PLAN.md` | ⚠️ Outdated | Original planning doc |
| `TODO_MEASUREMENT_INTEGRATION_UPDATE.md` | ⚠️ Partial | GitHub integration notes |
| `AI_BODY_MEASUREMENT_FULL_AUDIT.md` | ⚠️ Outdated | Previous audit |
| `AI_BODY_MEASUREMENT_AUDIT_REPORT.md` | ⚠️ Partial | Audit report |
| `AI_BODY_MEASUREMENT_SAAS_PLAN.md` | ✅ Current | Latest SAAS plan |
| `AI_BODY_MEASUREMENT_INTEGRATION_AUDIT.md` | ✅ Current | Integration audit |
| `AI_BODY_MEASUREMENT_DOCUMENTATION.md` | ✅ Current | This file |

---

## TODO Items

- [ ] Deploy ai-body-scan-saas to Vercel production
- [ ] Generate production API keys
- [ ] Add webhook for subscription events
- [ ] Test accuracy with real users
- [ ] Add single photo fallback mode

---

## Old Documentation (Consolidated)

The following 6 files are now consolidated into this document:

| File | Status | Notes |
|------|--------|-------|
| `AI_BODY_MEASUREMENT_PLAN.md` | ⚠️ Outdated | Original planning - see above ✓ |
| `TODO_MEASUREMENT_INTEGRATION_UPDATE.md` | ⚠️ Partial | GitHub integration - see above ✓ |
| `AI_BODY_MEASUREMENT_FULL_AUDIT.md` | ⚠️ Outdated | Previous audit - see above ✓ |
| `AI_BODY_MEASUREMENT_AUDIT_REPORT.md` | ⚠️ Partial | Old audit report - see above ✓ |
| `AI_BODY_MEASUREMENT_SAAS_PLAN.md` | ✅ Current | Included in setup ✓ |
| `AI_BODY_MEASUREMENT_INTEGRATION_AUDIT.md` | ✅ Current | Integration audit ✓ |

**Recommendation:** Delete the 6 old files after confirming this document captures everything.
