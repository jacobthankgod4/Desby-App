# GitHub Push Plan: AI Body Scan SaaS Backend

## Executive Summary

This document outlines a comprehensive, non-destructive plan to push the AI Body Scan SaaS backend API to GitHub securely. The audit revealed **CRITICAL security issues** that must be addressed before pushing.

---

## 🔴 Critical Security Issues Found

### 1. HARDCODED SECRETS (SEVERITY: CRITICAL)

**Location**: `api/routes/auth.py` (lines 17-18)
```python
SUPABASE_URL = 'https://blsettabymllulsxtziw.supabase.co'
SUPABASE_ANON_KEY = 'sb_publishable_miCOIXHtlxLkfDgpwE0N-g_BA1Q-x8y'
```

**Impact**: 
- Exposes Supabase project credentials publicly
- Allows unauthorized access to your database
- API key can be rotations/regenerated but URL exposes project ID

### 2. API KEYS FILE CONTAINS REAL DATA

**Location**: `data/api_keys.json`
```json
{
  "dev_test_key_12345": {
    "key": "dev_test_key_12345",
    "user_id": "test_user",
    ...
  }
}
```

**Impact**: Test credentials exposed

### 3. LARGE BINARY FILES (~50MB+)

**Problem Files**:
- `api/models/model.ckpt-*` (multiple files, ~2MB each)
- `api/models/models.tar.gz` 
- `api/models/neutral_smpl_with_cocoplus_reg.pkl`
- `models/models/` directory
- `body-capture.png` (2.3MB)
- `homepage_image.png` (2.3MB)

**Impact**: 
- bloats repository
- GitHub LFS recommended but not free for large repos
- Should use GitHub Releases for model files

### 4. DEVELOPMENT-ONLY CONFIGURATION

**Location**: `config.yaml`
```yaml
environment: "development"
debug: true  # in staging section
```

### 5. OPEN CORS POLICY

**Location**: `api/main.py`
```python
allow_origins=["*"],  # Should be restricted in production
```

---

## 📋 Comprehensive Push Plan

### Phase 1: Security Fixes (MUST DO FIRST)

| Step | Action | File | Risk Level |
|------|--------|------|------------|
| 1.1 | Replace hardcoded Supabase credentials with environment variables | `api/routes/auth.py` | 🔴 CRITICAL |
| 1.2 | Create `.env.example` template | New file | 🔴 CRITICAL |
| 1.3 | Add `.env` to `.gitignore` | `.gitignore` | 🔴 CRITICAL |
| 1.4 | Sanitize `data/api_keys.json` | `data/api_keys.json` | 🟠 HIGH |

### Phase 2: Clean Up Binary Files

| Step | Action | File | Risk Level |
|------|--------|------|------------|
| 2.1 | Add model files to `.gitignore` | `.gitignore` | 🟠 HIGH |
| 2.2 | Add large images to `.gitignore` | `.gitignore` | 🟠 HIGH |
| 2.3 | Create download script for models | `scripts/download_models.py` | 🟡 MEDIUM |
| 2.4 | Document model download in README | `README.md` | 🟡 MEDIUM |
| 2.5 | Remove binary files from git cache | Git commands | 🟠 HIGH |

### Phase 3: Configuration & Environment

| Step | Action | File | Risk Level |
|------|--------|------|------------|
| 3.1 | Restrict CORS to reasonable origins | `api/main.py` | 🟠 HIGH |
| 3.2 | Add production config section | `config.yaml` | 🟡 MEDIUM |
| 3.3 | Create environment variable loading | `.env` handling | 🟡 MEDIUM |

### Phase 4: Create Proper Documentation

| Step | Action | File | Risk Level |
|------|--------|------|------------|
| 4.1 | Update README with setup instructions | `README.md` | 🟢 LOW |
| 4.2 | Create CONTRIBUTING.md | `CONTRIBUTING.md` | 🟢 LOW |
| 4.3 | Create LICENSE (or keep proprietary) | `LICENSE` | 🟢 LOW |
| 4.4 | Add .gitignore file | `.gitignore` | 🟢 LOW |

### Phase 5: Git Operations

| Step | Action | Risk Level |
|------|--------|------------|
| 5.1 | Remove binary files from git tracking | 🟠 HIGH |
| 5.2 | Stage only safe files | 🟡 MEDIUM |
| 5.3 | Create initial commit | 🟢 LOW |
| 5.4 | Push to remote | 🟢 LOW |

---

## 🔧 Implementation Details

### Step 1.1: Fix Hardcoded Supabase Credentials

**Before** (`api/routes/auth.py`):
```python
SUPABASE_URL = 'https://blsettabymllulsxtziw.supabase.co'
SUPABASE_ANON_KEY = 'sb_publishable_miCOIXHtlxLkfDgpwE0N-g_BA1Q-x8y'
```

**After**:
```python
import os
SUPABASE_URL = os.environ.get('SUPABASE_URL', 'https://your-project.supabase.co')
SUPABASE_ANON_KEY = os.environ.get('SUPABASE_ANON_KEY', 'your-anon-key')
```

### Step 1.2: Create .env.example

```bash
# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here

# Paystack Configuration (if using)
PAYSTACK_SECRET_KEY=your_secret_key
PAYSTACK_PUBLIC_KEY=your_public_key

# Server Configuration
PORT=5001
ENVIRONMENT=development
DEBUG=true
```

### Step 1.4: Sanitize api_keys.json

**Before**:
```json
{
  "dev_test_key_12345": { ... }
}
```

**After**:
```json
{}
```

### Step 2.1-2.2: Enhanced .gitignore

```gitignore
# Environment
.env
.env.local
.env.*.local

# Models (large binary files)
*.ckpt-*
*.pkl
*.tar.gz
models/models/
models/*.task

# Images (large files)
*.png
!docs/*.png

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
venv/
.venv/

# IDE
.vscode/
.idea/
*.swp

# OS
.DS_Store
Thumbs.db

# Testing
.pytest_cache/
.coverage
htmlcov/

# Logs
*.log
```

### Step 2.3: Model Download Script (Reference to Existing)

The file `scripts/download_models.py` already exists. Verify it's complete and working.

---

## ⚠️ Important Notes

### Non-Destructive Approach:

1. **Git's history will contain old secrets** if they've been committed before
   - Option: Create fresh repository with `git rebase` or new repo
   - For existing repo: Must rewrite history which destroys old commits

2. **Current Remote**: `https://github.com/jacobthankGod/ai-body-measurement-service.git`
   - Decision: Push to same repo OR create new repo

3. **Large Files Already Pushed?** - Check git history:
   ```bash
   cd /Users/mac/ai-body-scan-saas
   git log --oneline --all
   git fsck --full
   ```

### Repository Size Estimate:

- Current size: ~50-100MB (mostly models and images)
- After cleanup: ~1-2MB (code only)

### Recommended Approach:

1. **For existing repo** (with history): 
   - Force push after cleanup may break other collaborators
   - Consider creating new branch or repo

2. **For clean slate**:
   - Option A: Push to new GitHub repository
   - Option B: Create new branch `clean-v2` and push

---

## 📝 TODO Checklist

- [ ] 1.1 Fix hardcoded Supabase credentials → environment variables
- [ ] 1.2 Create `.env.example` template file
- [ ] 1.3 Add `.env` to `.gitignore`
- [ ] 1.4 Sanitize `data/api_keys.json` to empty object
- [ ] 2.1 Add model files to `.gitignore`
- [ ] 2.2 Add large images to `.gitignore`  
- [ ] 2.3 Verify model download script
- [ ] 2.4 Update README with model setup
- [ ] 2.5 Remove binary files from git tracking
- [ ] 3.1 Restrict CORS in api/main.py
- [ ] 3.2 Add production config section
- [ ] 3.3 Add environment variable loading
- [ ] 4.1 Update README
- [ ] 4.2 Create/verify CONTRIBUTING.md
- [ ] 4.3 Verify LICENSE
- [ ] 4.4 Create .gitignore file
- [ ] 5.1 Stage safe files only
- [ ] 5.2 Create commit message
- [ ] 5.3 Push to GitHub

---

## 🚀 Execution Command Template

```bash
cd /Users/mac/ai-body-scan-saas

# Step 1: Check current state
git status

# Step 2: Run security fixes (manual edits required)
# (See implementation details above)

# Step 3: Verify .gitignore
cat .gitignore || echo "File not found - need to create"

# Step 4: Remove files from tracking
git rm --cached api/models/*.ckpt-* api/models/*.pkl api/models/*.tar.gz models/ body-capture.png homepage_image.png 2>/dev/null || true

# Step 5: Stage safe files only
git add api/routes/auth.py api/main.py config.yaml requirements.txt README.md .gitignore 2>/dev/null || true

# Step 6: Commit
git commit -m "security: Clean up secrets and binary files before GitHub push

- Remove hardcoded Supabase credentials (use env vars)
- Sanitize API keys file
- Remove large binary files from tracking
- Add proper .gitignore
- Restrict CORS policy"

# Step 7: Push
git push origin main
```

---

## 📞 Decisions Required

Before proceeding, please confirm:

1. **Repository**: Push to existing `jacobthankGod/ai-body-measurement-service` or create new repo?

2. **Supabase Credentials**: 
   - Have you already regenerated the exposed keys?
   - Should I use environment variables approach?

3. **Model Files**:
   - Option A: Use GitHub Releases (recommended)
   - Option B: Use Git LFS
   - Option C: Just remove and document download

4. **API Keys File**:
   - Confirm it's safe to sanitize/delete

5. **Timeline**: When should this be done?

---

*Plan created: 2024*
*Last updated: 2024*
