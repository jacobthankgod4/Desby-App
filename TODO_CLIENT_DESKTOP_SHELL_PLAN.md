# TODO_CLIENT_DESKTOP_SHELL_PLAN

## Goal
Ensure client desktop sidebar items render inside `DesktopDashboardShell` using shell-safe widgets (no `Navigator.pushNamed`), with consistent index mapping and clean, client-friendly terminology.

## Current Implementation (completed)
### Wired into Desktop shell (index-based)
File: `lib/features/dashboard/presentation/pages/main_page.dart`
- Desktop pages are rendered via `_getDesktopPages('client', userId)` and `DesktopDashboardShell(child: desktopPages[desktopIndex])`.
- Replaced the 4 placeholder slots (indices 5–8) with:
  - index 5: `ClientLiveMilestonesPage`
  - index 6: `ClientGarmentArchitecturePage`
  - index 7: `ClientPortfolioPage`
  - index 8: `ClientDigitalClosetPage`

### Shell-safe page widgets (no route pushes)
Added pages under `lib/features/clients/presentation/pages/`:
- `client_live_milestones_page.dart`
- `client_garment_architecture_page.dart`
- `client_portfolio_page.dart`
- `client_digital_closet_page.dart`

Behavior:
- Each uses Riverpod `ordersProvider(null)` and renders loading / error / empty states.
- No `Navigator.pushNamed` inside these client pages.

### Client-facing terminology
Updated headings/subheadings in the 4 client pages to be normal, user-facing language.

## Remaining Issues
1. `flutter analyze lib/features/dashboard/presentation/pages/main_page.dart` shows warnings:
   - unused imports:
     - `order_create_page.dart`
     - `notification_center_page.dart`
   (Non-blocking, but should be cleaned.)
2. Sidebar labels in `MainPage` were intentionally not changed to avoid index-mapping side effects.

## Next Fix Plan
### Step 1: Remove unused imports
File: `lib/features/dashboard/presentation/pages/main_page.dart`
- Remove unused imports for `order_create_page.dart` and `notification_center_page.dart`.
- Re-run `flutter analyze`.

### Step 2: Ensure all client-facing text is consistent
- Verify that any remaining user-facing strings in the four client pages (including status chips / empty states) are understandable.
- Keep technical/internal wording out of headings and descriptions.

### Step 3 (optional, future hardening): Index mapping verification
- Add a small internal consistency check (manual checklist):
  - When clicking each sidebar item, confirm the selected sidebar highlights and content index matches.

## Validation Checklist
- Desktop (>1000px):
  - Clicking Live Milestones shows `ClientLiveMilestonesPage` content.
  - Clicking Design & Fit Plan shows `ClientGarmentArchitecturePage` content.
  - Clicking Project Portfolio shows `ClientPortfolioPage` content.
  - Clicking Saved Garment Assets shows `ClientDigitalClosetPage` content.
- Switching away and back does not push new routes.
- Messages / Settings / Insights / My Profile still work and highlight correctly.

## Automated Checks
- `flutter analyze lib/features/dashboard/presentation/pages/main_page.dart` => no errors (warnings optional).

