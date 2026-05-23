# Desktop Dashboard Audit - Missing Actions

**Date:** $(date +%Y-%m-%d)
**Issue:** Add Client, Create Order, Invite Apprentice missing in Desktop View

---

## Audit Summary by User Type

### 1. TAILOR Dashboard (tailor_dashboard.dart)

**Current Action Cards (4-grid):**
| Card | Label | Route | Status |
|------|-------|-------|--------|
| 1 | Setup shop | `/shop-setup` | ✅ Working |
| 2 | Marketplace | `/marketplace` | ✅ Working |
| 3 | Invite Talent | `/apprentice-onboarding` | ✅ Working |
| 4 | Sync Measure | `/unified-add-client` | ✅ Working |

**Current Nav Items (passed to Shell):**
```
Home → /dashboard (or just onTap)
Orders → /orders
Clients → /clients
Marketplace → /marketplace
My Shop → (empty onTap)
Pricing → /pricing-setup
Settings → (empty onTap)
Help → (empty onTap)
```

**MISSING for Tailor:**
| Missing Item | Should Route | Priority |
|-------------|--------------|----------|
| Add New Client | `/unified-add-client` | HIGH |
| Create New Order | `/order-create` | HIGH |
| Invite Apprentice | `/apprentice-onboarding` | Already in action cards, needs nav |

---

### 2. CLIENT Dashboard (client_dashboard.dart)

**Current Nav Items:**
```
Home → (empty)
Orders → (empty)
Find Tailor → TailorDiscoveryPage
Measurements → (empty)
Favorites → (empty)
Settings → (empty)
Help → (empty)
```

**MISSING for Client:**
| Missing Item | Should Route | Priority |
|-------------|--------------|----------|
| Find Tailor | `/tailor-discovery` | HIGH |
| Measurements | `/measurements-input` | MEDIUM |
| Favorites | (future feature) | LOW |
| Add to Portfolio | (future feature) | LOW |

---

### 3. FABRIC SELLER Dashboard (fabric_seller_dashboard.dart)

**Current Nav Items:**
```
Home → (empty)
Orders → (empty)
Upload → /fabric-upload
Analytics → (empty)
Messages → (empty)
Settings → (empty)
Help → (empty)
```

**MISSING for Fabric Seller:**
| Missing Item | Should Route | Priority |
|-------------|--------------|----------|
| Add New Fabric | `/fabric-upload` | Already in Quick Actions |
| Analytics | `/insights` | MEDIUM |
| Messages | (future - realtime) | LOW |

---

### 4. APPRENTICE Dashboard (apprentice_dashboard.dart)

**Current Nav Items:**
```
Home → (empty)
Tasks → (empty)
Curriculum → (empty)
Progress → (empty)
Mentors → (empty)
Settings → (empty)
Help → (empty)
```

**MISSING for Apprentice:**
| Missing Item | Should Route | Priority |
|-------------|--------------|----------|
| Tasks | (future) | MEDIUM |
| Curriculum | (future) | MEDIUM |
| Find Mentor | (future) | LOW |

---

## Desktop Shell Default Menu (Global)

**Current `_buildDefaultMenu()` returns:**
```
Dashboard → /dashboard
Orders → /orders
Clients → /clients
My Profile → /profile
Business Insights → /insights
Marketplace → /marketplace
Notifications → /notifications
System Settings → /settings
Upgrade Plan → /subscription
```

**Issues with Default Menu:**
- Doesn't adapt to user type
- Routes are hardcoded but most nav items pass empty onTap
- Missing routes to actual pages

---

## Fix Implementation Plan

### Step 1: Update DesktopDashboardShell
- Make navItems truly user-type aware
- Add required routes for empty nav items

### Step 2: Enhance Tailor Dashboard
- Add "Add Client" button 
- Add "Create Order" button
- Ensure nav items route correctly

### Step 3: Enhance Client Dashboard  
- Add Find Tailor → `/tailor-discovery`
- Add Measurements → `/measurements-input`

### Step 4: Enhance Fabric Seller Dashboard
- Make Analytics route to `/insights`

---

## Files to Modify

1. `lib/features/dashboard/presentation/widgets/desktop_dashboard_shell.dart`
2. `lib/features/dashboard/presentation/pages/tailor_dashboard.dart`
3. `lib/features/dashboard/presentation/pages/client_dashboard.dart`
4. `lib/features/dashboard/presentation/pages/fabric_seller_dashboard.dart`
