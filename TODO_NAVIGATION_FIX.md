# Navigation Fix Plan

## Issues Identified:

### 1. "Designer Shop Setup" - Already Exists in Sidebar
- **Status**: Already in Desktop Dashboard sidebar as "My Shop" (route: `/shop-setup`)
- **Files**: `lib/features/dashboard/presentation/widgets/desktop_dashboard_shell.dart`, `lib/main.dart`
- **Action**: Remove duplicate entry from settings page (already done per comments)

### 2. Find Tailor Navigation Issue (Main Problem)
- **Current behavior**: When clicking "Find Tailor" in desktop shell, it opens TailorFinderDesktop but without the full desktop shell navigation
- **Expected behavior**: Should load the same dashboard main menu and header (desktop shell) and just load the tailor finder content inside it
- **Files**: `lib/main.dart` route `/tailor-finder`
- **Root cause**: The route uses DesktopShellWrapper but the desktop shell navigation isn't consistent with main_page navigation

### 3. Missing Features (Not Yet Implemented)
- Live Milestones
- Garment Architecture  
- Portfolio
- Digital Closet
- Need placeholder/coming soon pages

## Action Plan:

### Fix 1: Ensure /tailor-finder uses full DesktopShellWrapper properly
- Update route to use consistent DesktopShellWrapper with client nav items (same as main_page)

### Fix 2: Add missing features to client navigation in DesktopDashboardShell
- Add: Live Milestones, Garment Architecture, Portfolio, Digital Closet
- These should show "Coming Soon" placeholder pages

### Fix 3: Ensure consistent navigation between routes
- All desktop routes using DesktopShellWrapper should have the same sidebar structure as main_page
