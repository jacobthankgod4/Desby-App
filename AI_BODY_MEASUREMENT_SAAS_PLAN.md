# AI Body Scan SaaS - Technical Specification

> **Version:** 2.1.0  
> **Status:** In Progress  
> **Last Updated:** 2025-01-14  
> **Owner:** Backend Team  
> **Target Platform:** Vercel Serverless  
> **Payment Provider:** Paystack  

---

## 1. Overview

| Field | Value |
|-------|-------|
| Product Name | AI Body Scan API |
| Type | Standalone SaaS API |
| Deployment Target | Vercel (Python 3.11) |
| Authentication | API Key (X-API-Key header) |
| Protocol | REST + JSON |
| Target Users | Tailor apps, fashion platforms |

---

## 2. Architecture

### 2.1 High-Level Design

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Client     │────▶│  Vercel Edge      │────▶│  FastAPI API     │
│  (Desby)    │     │  (CORS/Rate Limit)│     │  (Python 3.11)   │
└─────────────┘     └──────────────────┘     └─────────────────┘
                                                   │
                                          ┌────────┴────────┐
                                          │ MediaPipe      │
                                          │ ML Processing │
                                          └────────────────┘
```

### 2.2 Project Structure

```
ai-body-scan-saas/
├── api/
│   ├── __init__.py
│   ├── main.py              # FastAPI entry point
│   ├── routes/
│   │   ├── __init__.py
│   │   ├── measurements.py # /measurements/*
│   │   ├── health.py       # /health/*
│   │   └── subscriptions.py# /subscriptions/*
│   ├── services/
│   │   ├── __init__.py
│   │   └── measurement_engine.py
│   └── models/
│       ├── __init__.py
│       └── schemas.py     # Pydantic models
├── middleware/
│   ├── __init__.py
│   ├── api_key_auth.py
│   ├── rate_limiter.py
│   └── subscription_check.py
├── data/
│   ├── api_keys.json     # API key storage
│   └── usage_log.json   # Usage tracking
├── scripts/
│   ├── download_models.py
│   └── init_db.py
├── tests/
│   ├── __init__.py
│   ├── test_measurements.py
│   └── test_api.py
├── dashboard/            # Admin web UI
│   ├── index.html
│   ├── css/
│   │   └── styles.css
│   └── js/
│       └── app.js
├── config.yaml           # Configuration
├── vercel.json          # Vercel config
├── runtime.txt         # Python version
├── requirements.txt   # Dependencies
├── Dockerfile         # Docker build
└── README.md         # Documentation
```

---

## 3. API Specification

### 3.1 Base URL

| Environment | URL |
|-------------|-----|
| Production | `https://api.body-scan.ai` |
| Staging | `https://ai-body-scan-saas.vercel.app` |
| Development | `http://localhost:5001` |

### 3.2 Authentication

All endpoints require API key via `X-API-Key` header:

```http
GET /api/v2/health HTTP/1.1
Host: api.body-scan.ai
X-API-Key: sk_live_xxxxxxxxxxxx
```

### 3.3 Endpoints

#### 3.3.1 Health Check

```http
GET /api/v2/health
```

Response:

```json
{
  "status": "healthy",
  "version": "2.0.0",
  "timestamp": "2025-01-13T10:30:00Z"
}
```

#### 3.3.2 Extract Measurements

```http
POST /api/v2/measurements/extract
Content-Type: multipart/form-data
X-API-Key: sk_live_xxxxxxxxxxxx
```

Request Body:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| front | File | Yes | Front-facing photo (JPEG/PNG) |
| side | File | Yes | Side profile photo (JPEG/PNG) |
| height | Float | Yes | User height in cm (120-220) |
| gender | String | No | Gender: male/female/other (default: male) |

Response:

```json
{
  "success": true,
  "request_id": "req_abc123",
  "measurements": {
    "chest": 102.5,
    "waist": 84.0,
    "hips": 98.5,
    "shoulder_width": 45.2,
    "arm_length": 58.0,
    "inseam": 82.5
  },
  "accuracy": {
    "mode": "dual",
    "estimated_cm": "±1-3"
  },
  "metadata": {
    "processing_time_ms": 2500,
    "model_version": "mediapipe_v0.10.9"
  }
}
```

#### 3.3.3 Subscription Status

```http
GET /api/v2/subscriptions/status
X-API-Key: sk_live_xxxxxxxxxxxx
```

Response:

```json
{
  "tier": "tailor_pro",
  "scans_used": 7,
  "scans_remaining": 3,
  "reset_date": "2025-02-01",
  "features": ["dual_scan", "priority_queue"]
}
```

---

## 4. Error Handling

### 4.1 Error Response Schema

```json
{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Monthly scan limit reached",
    "details": {
      "limit": 10,
      "used": 10,
      "reset_date": "2025-02-01"
    }
  }
}
```

### 4.2 Error Codes

| Code | HTTP Status | Description |
|------|------------|-------------|
| INVALID_API_KEY | 401 | Missing or invalid API key |
| SUBSCRIPTION_EXPIRED | 403 | Subscription not active |
| RATE_LIMIT_EXCEEDED | 429 | Monthly quota exceeded |
| INVALID_IMAGE | 400 | Image format/size issue |
| PROCESSING_ERROR | 500 | ML processing failed |
| SERVICE_UNAVAILABLE | 503 | Maintenance/latency |

---

## 5. Subscription Tiers

### 5.1 Tier Comparison

| Tier | Monthly Scans | Price | Features |
|------|---------------|-------|----------|
| tailor_basic | 0 | Free | - |
| tailor_pro | 10 | $9.99/mo | Dual scan, priority |
| tailor_elite | 50 | $24.99/mo | Dual scan, priority, analytics |
| enterprise | 200+ | Custom | Dedicated, white-label, SLA |

### 5.2 Usage Tracking

```python
SUBSCRIPTION_QUOTAS = {
    'tailor_basic': 0,
    'tailor_pro': 10,
    'tailor_elite': 50,
    'enterprise': 200,
}
```

---

## 6. Payment Integration (Paystack)

### 6.1 Overview

Paystack integration enables subscription billing and payment processing for SaaS tiers.

| Feature | Details |
|---------|---------|
| Provider | Paystack |
| Payment Methods | Card, Bank Transfer, USSD, Mobile Money |
| Currency | NGN, GHS, USD, etc. |
| Webhook Support | Yes - for payment verification |
| Test Mode | Available |

### 6.2 Payment Endpoints

#### 6.2.1 Initiate Payment

```http
POST /api/v2/payments/initialize
X-API-Key: sk_live_xxxxxxxxxxxx
Content-Type: application/json

{
  "tier": "tailor_pro",
  "email": "user@example.com",
  "amount": 999999,
  "currency": "NGN"
}
```

Response:

```json
{
  "status": true,
  "message": "Authorization URL created",
  "data": {
    "authorization_url": "https://checkout.paystack.com/...",
    "access_code": "1234567",
    "reference": "ref_1234567890abcdef"
  }
}
```

#### 6.2.2 Verify Payment

```http
GET /api/v2/payments/verify/{reference}
X-API-Key: sk_live_xxxxxxxxxxxx
```

Response:

```json
{
  "status": true,
  "message": "Verification successful",
  "data": {
    "reference": "ref_1234567890abcdef",
    "amount": 999999,
    "paid_at": "2025-01-13T10:30:00Z",
    "customer": {
      "email": "user@example.com"
    },
    "subscription_activated": true
  }
}
```

#### 6.2.3 List Transactions

```http
GET /api/v2/payments/transactions?limit=10&page=1
X-API-Key: sk_live_xxxxxxxxxxxx
```

### 6.3 Webhook Events

```http
POST /api/v2/payments/webhook
Content-Type: application/json
X-Paystack-Signature: signature_hash

{
  "event": "charge.success",
  "data": {
    "reference": "ref_1234567890abcdef",
    "customer": {
      "email": "user@example.com"
    },
    "amount": 999999
  }
}
```

**Webhook Events:**
- `charge.success` - Payment succeeded
- `charge.failed` - Payment failed
- `subscription.create` - Subscription created
- `subscription.disable` - Subscription disabled

### 6.4 Tier Pricing (Paystack)

| Tier | Monthly Price (NGN) | Annual Price (NGN) | Features |
|------|---------------------|-------------------|----------|
| tailor_pro | ₦2,999 | ₦29,999 | 10 scans/month |
| tailor_elite | ₦7,499 | ₦74,999 | 50 scans/month |
| enterprise | Custom | Custom | 200+ scans/month |

---

## 7. Configuration

### 7.1 Environment Variables

| Variable | Required | Description | Default |
|----------|----------|-------------|---------|
| API_SECRET | Yes | Admin secret key | - |
| LOG_LEVEL | No | Debug level | INFO |
| DATABASE_URL | No | PostgreSQL URL | file-based |
| PAYSTACK_SECRET_KEY | Yes | Paystack secret key | - |
| PAYSTACK_PUBLIC_KEY | Yes | Paystack public key | - |
| REDIS_URL | No | Redis for caching | - |

### 7.2 Vercel Configuration

```json
{
  "builds": [
    {
      "src": "api/main.py",
      "use": "@vercel/python"
    }
  ],
  "routes": [
    {
      "src": "/(.*)",
      "dest": "/api/main.py"
    }
  ],
  "pythonVersion": "3.11"
}
```

### 7.3 Dependencies

```
# Core ML/Image Processing
mediapipe==0.10.9.0
opencv-python-headless==4.8.1
numpy==1.26.3
pillow==10.2.0

# Web Framework
fastapi==0.109.0
uvicorn[standard]==0.27.0
python-multipart==0.0.6
httpx==0.26.0

# Data Handling
pydantic==2.5.3
pydantic-settings==2.1.0

# Payment Processing (Paystack)
paystack-python==0.2.3

# Deployment
vercel==0.13.0

# Utilities
python-dotenv==1.0.0
```

---

## 8. Integration

### 8.1 Desby Flutter Integration

```dart
class BodyMeasurementService {
  static const String _baseUrl = 'https://api.body-scan.ai';
  
  late final Dio _dio;
  
  BodyMeasurementService({String? apiKey}) {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'X-API-Key': apiKey ?? _getStoredApiKey(),
        'Content-Type': 'multipart/form-data',
      },
    ));
  }
  
  String _getStoredApiKey() {
    return LocalStorage.getString(StorageKeys.aiScanApiKey) ?? '';
  }
}
```

### 8.2 Storage Keys

```dart
class StorageKeys {
  static const String aiScanApiKey = 'ai_scan_api_key';
  static const String subscriptionTier = 'subscription_tier';
  static const String paystackCustomerId = 'paystack_customer_id';
  static const String lastPaymentRef = 'last_payment_ref';
}
```

---

## 9. Deployment

### 9.1 Vercel Deploy Steps

```bash
# 1. Login
vercel login

# 2. Link project
vercel link

# 3. Deploy production
vercel deploy --prod

# 4. Set environment variables
vercel env add API_SECRET production
vercel env add LOG_LEVEL production
```

### 9.2 Custom Domain

| Domain | Target |
|--------|--------|
| api.body-scan.ai | Production |
| api-staging.body-scan.ai | Staging |

---

## 10. Monitoring

### 10.1 Health Metrics

| Metric | Target |
|-------|--------|
| Uptime | 99.9% |
| P95 Latency | <3s |
| Error Rate | <1% |

### 10.2 Logging

- Request/Response logging
- Error tracking (Sentry)
- Usage analytics

---

## 11. Milestones

| # | Task | Estimate |
|---|------|----------|
| 1 | Project structure & FastAPI setup | 2h |
| 2 | API routes & authentication | 2h |
| 3 | Paystack integration | 2h |
| 4 | Vercel deployment | 30m |
| 5 | Flutter integration | 1h |
| 6 | Testing & polish | 2h |

**Total: ~9.5 hours**

---

## 12. Open Questions

| # | Question | Status |
|---|----------|--------|
| 1 | Database: PostgreSQL or file-based? | Resolved: File-based (JSON) |
| 2 | Custom domain or .vercel.app? | Pending |
| 3 | Payment provider selection? | Resolved: Paystack |

---

## 13. Appendix

### A. File Outputs

**A.1 api/main.py**

```python
"""
AI Body Scan SaaS - FastAPI Entry Point
"""
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import uvicorn

from api.routes import measurements, health, subscriptions

@asynccontextmanager
async def lifespan(app: FastAPI):
    print("Starting AI Body Scan SaaS v2.0.0")
    yield
    print("Shutting down...")

app = FastAPI(
    title="AI Body Scan API",
    description="AI-powered body measurement extraction",
    version="2.0.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health.router, prefix="/api/v2", tags=["Health"])
app.include_router(measurements.router, prefix="/api/v2", tags=["Measurements"])
app.include_router(subscriptions.router, prefix="/api/v2", tags=["Subscriptions"])

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=5001)
```

**A.2 api/routes/measurements.py**

```python
"""
Measurement Routes
"""
from fastapi import APIRouter, UploadFile, File, Form, Header, HTTPException, Depends
from api.services.measurement_engine import extract_measurements_from_dual_photos
from middleware.subscription_check import validate_subscription, track_usage

router = APIRouter()

def get_current_user(x_api_key: str = Header(None)):
    if not x_api_key:
        raise HTTPException(status_code=401, detail="API key required")
    result = validate_subscription(x_api_key)
    if not result['valid']:
        raise HTTPException(status_code=403, detail=result['error'])
    return {'api_key': x_api_key}

@router.post("/measurements/extract")
async def extract_measurements(
    front: UploadFile = File(...),
    side: UploadFile = File(...),
    height: float = Form(...),
    gender: str = Form("male"),
    user: dict = Depends(get_current_user)
):
    track_usage(user['api_key'])
    
    import io
    from PIL import Image
    import numpy as np
    
    front_image = Image.open(io.BytesIO(await front.read()))
    side_image = Image.open(io.BytesIO(await side.read()))
    
    measurements = extract_measurements_from_dual_photos(
        np.array(front_image), np.array(side_image), height, gender
    )
    
    return {
        "success": True,
        "request_id": f"req_{user['api_key'][:8]}",
        "measurements": measurements,
        "accuracy": {"mode": "dual", "estimated_cm": "±1-3"}
    }
```

**A.3 middleware/api_key_auth.py**

```python
"""
API Key Authentication Middleware
"""
import json
from pathlib import Path
from fastapi import HTTPException, Security
from fastapi.security import APIKeyHeader

API_KEY_HEADER = APIKeyHeader(name="X-API-Key", auto_error=False)
DATA_DIR = Path(__file__).parent.parent / "data"

def load_api_keys():
    keys_file = DATA_DIR / "api_keys.json"
    if keys_file.exists():
        with open(keys_file) as f:
            return json.load(f)
    return {}

async def validate_api_key(api_key: str = Security(API_KEY_HEADER)):
    if not api_key:
        raise HTTPException(status_code=401, detail="API key required")
    
    keys = load_api_keys()
    if api_key not in keys:
        raise HTTPException(status_code=401, detail="Invalid API key")
    
    return api_key
```

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2024-12-01 | Team | Initial draft |
| 2.0.0 | 2025-01-13 | Team | Atomic restructure, industry standards |
