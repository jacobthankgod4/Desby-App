# TODO - AI Body Scan Homepage Implementation

## Overview
Create a full Figma-style landing page for AI Body Scan SaaS with Sign Up/Sign In using Supabase.

## Supabase Configuration
- URL: `https://blsettabymllulsxtziw.supabase.co`
- Publishable Key: `sb_publishable_miCOIXHtlxLkfDgpwE0N-g_BA1Q-x8y`

---

## Frontend - Landing Page

### File: `/ai-body-scan-saas/index.html`

- [ ] 1. Create header with logo, nav links, Sign In/Sign Up CTAs
- [ ] 2. Create Hero Section with:
  - [ ] Headline text
  - [ ] Mannequin (centered 3D body model)
  - [ ] Floating analytics cards (6 cards):
    - [ ] Body Fat % card (upper-left)
    - [ ] Skeletal Muscle Mass card
    - [ ] Posture Angles card (lower-left)
    - [ ] KPI: Bust card (right grid)
    - [ ] KPI: Hip card
    - [ ] KPI: Belly/Waist card
    - [ ] KPI: Thigh card
  - [ ] CTA Card at bottom
- [ ] 3. Create Platform Section (2-column: text + phone mockups)
- [ ] 4. Create Case Studies Section
- [ ] 5. Create Benefits Section
- [ ] 6. Create Demo CTA Section
- [ ] 7. Create Wellness Section
- [ ] 8. Create Audience Cards
- [ ] 9. Create Final CTA Banner
- [ ] 10. Create Footer
- [ ] 11. Add Sign In Modal (Supabase auth)
- [ ] 12. Add Sign Up Modal (Supabase auth)
- [ ] 13. Link to developer docs page

---

## Backend - Supabase Auth API Routes

### File: `/ai-body-scan-saas/api/routes/auth.py`
- [ ] POST /auth/signup - Sign up with email/password
- [ ] POST /auth/signin - Sign in with email/password  
- [ ] POST /auth/signout - Sign out
- [ ] GET /auth/me - Get current user
- [ ] POST /auth/reset-password - Password reset

### File: `/ai-body-scan-saas/api/config/supabase.py`
- [ ] Supabase client configuration

---

## Dependencies
- [ ] Update requirements.txt with supabase package

---

## Verification
- [ ] Test landing page loads correctly
- [ ] Test Sign In modal opens
- [ ] Test Sign Up modal opens
- [ ] Verify API routes respond correctly
