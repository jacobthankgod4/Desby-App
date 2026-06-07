# AI Body Scan Dashboard Audit Report

**Date**: $(date +%Y-%m-%d)
**Scope**: `/dashboard/index.html`

---

## Dashboard Overview

Current dashboard (`/dashboard/index.html`):

| Section | Status | Note |
|---------|--------|------|
| Stats: Total API Keys | ❌ Missing | Hardcoded "0" |
| Stats: Total Scans | ❌ Missing | Hardcoded "0" |
| Stats: Active Subscriptions | ❌ Missing | Hardcoded "0" |
| API Keys Table | ❌ Missing | Empty `<tbody>` |

**Problem**: Dashboard is a skeleton with hardcoded zeros and no backend integration.

---

## What's Implemented vs What's Missing

### ✅ What Exists (Frontend)
- Basic HTML structure with cards layout
- 3 stat placeholder cards
- API keys table structure (no rows)

### ❌ What's Missing (Critical)

| # | Feature | File(s) Needed | Impact |
|---|---------|----------------|--------|
| 1 | **Fetch API Keys** | `api/routes/admin.py` or stats endpoint | HIGH |
| 2 | **Fetch Usage Stats** | Backend endpoint | HIGH |
| 3 | **Fetch Subscriptions** | Backend endpoint | HIGH |
| 4 | **Populate Table** | JavaScript to render | MEDIUM |
| 5 | **Auth Protection** | Admin login check | HIGH |
| 6 | **Usage Charts** | Chart.js integration | LOW |
| 7 | **Export CSV** | Download button | LOW |
| 8 | **Search/Filter** | Table search | LOW |

---

## Detailed Gap Analysis

### Gap 1: API Keys Display
**Current**: Table `<tbody id="api-keys-list"></tbody>` empty

**Needed**:
- Call GET `/api/v2/auth/api-keys` (admin endpoint, not user-scoped)
- Render key data into table rows

**Severity**: HIGH - Core feature doesn't work

---

### Gap 2: Stats Counters
**Current**: Hardcoded `"0"` values

**Needed**:
- Total API keys = count keys in `api_keys.json`
- Total scans = sum `usage_log.json` totals
- Active subs = count keys with valid subscription tier

**Severity**: HIGH - Dashboard shows no real data

---

### Gap 3: Authentication
**Current**: No auth check - anyone can view dashboard

**Missing**:
- No login required to view dashboard
- No role-based access (admin vs user)

**Severity**: HIGH - Security risk

---

### Gap 4: No Admin Endpoints
The main API only has user-scoped endpoints:
- `/GET /api/v2/auth/api-keys` → returns only current user's keys
- No way to fetch all users' keys (for admin dashboard)

**Missing Backend**:
- `/GET /api/v2/admin/stats` → global stats
- `/GET /api/v2/admin/api-keys` → all keys (admin only)
- `/GET /api/v2/admin/usage` → usage logs

---

## Recommended Implementation

### Step 1: Backend - Admin Statistics Endpoint
```python
# api/routes/admin.py
@router.get("/admin/stats")
async def get_admin_stats():
    """Return global stats for dashboard."""
    keys = load_api_keys()
    usage = load_usage_log()
    return {
        "total_api_keys": len(keys),
        "active_keys": sum(1 for k in keys.values() if k.get("active")),
        "total_scans": sum(u.get("total", 0) for u in usage.values()),
        "tier_breakdown": {...}
    }
```

### Step 2: Frontend - Fetch and Render
```javascript
async function loadDashboard() {
  const res = await fetch('/api/v2/admin/stats');
  const data = await res.json();
  
  document.getElementById('total-api-keys').textContent = data.total_api_keys;
  document.getElementById('total-scans').textContent = data.total_scans;
  document.getElementById('active-subs').textContent = data.active_keys;
  // ...
}
```

### Step 3: Authentication
- Add basic auth check or API key check for admin routes
- Don't expose admin stats to public

---

## Priority Matrix

| Priority | Item | Effort |
|----------|------|--------|
| P0 | Add admin stats endpoint | 1 hr |
| P0 | Connect frontend to backend | 1 hr |
| P0 | Add auth check | 30 min |
| P1 | Populate API keys table | 30 min |
| P2 | Add simple charts | 2 hr |
| P2 | Export functionality | 1 hr |

---

## Summary

**Status**: Dashboard is a placeholder skeleton.

**Critical Gaps**:
1. No backend admin endpoints
2. No real data displayed
3. No authentication

**Action Required**: Implement admin backend routes + wire up frontend.
