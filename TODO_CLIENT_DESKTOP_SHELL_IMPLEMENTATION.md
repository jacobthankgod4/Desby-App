# TODO_CLIENT_DESKTOP_SHELL_IMPLEMENTATION

## Background
Client desktop navigation is driven by `MainPage` rendering inside `DesktopDashboardShell` via fixed index → widget mapping:
- `MainPage` client sidebar items (Live Milestones, Garment Architecture, Portfolio, Digital Closet) must correspond to concrete widgets in `MainPage._getDesktopPages('client', ...)`.
- The shell requires that clicks load **inside the same desktop shell** (no new routes/shell wrappers).

`ClientDashboard` already contains *visual sections* for these concepts, but the user request requires the sidebar items to load content **as pages inside the shell**.

## Current State (Observed)
- `lib/features/dashboard/presentation/pages/main_page.dart` currently has `const Placeholder()` slots at client desktop indices for:
  - Live Milestones
  - Garment Architecture
  - Portfolio
  - Digital Closet
- These placeholders must be replaced with real widgets.

## Goal
Implement dedicated client page widgets for:
1. Live Milestones
2. Garment Architecture
3. Portfolio
4. Digital Closet

All four must:
- Render inside `DesktopDashboardShell` (no `Navigator.pushNamed` that navigates outside the shell).
- Fetch and display user-specific data from Firebase.
- Be wired into `MainPage._getDesktopPages('client', ...)` at the correct indices.

## Data / Firebase Expectations (to verify during implementation)
### Live Milestones / Garment Architecture
Likely source: existing `ordersProvider` + `OrderEntity` contains:
- `createdAt`
- `status`
- `items.first.garmentType`
- `materialAssetUrl`
- (maybe) `milestones` or milestone-like information

Action:
- Inspect `ordersProvider` (and underlying repository) to confirm how milestones are represented in Firestore/Realtime DB.

### Portfolio / Digital Closet
Likely source: `OrderEntity` again provides:
- `materialAssetUrl` for visual portfolio assets
- `items.first.garmentType` for categorization

Action:
- Inspect `OrderEntity` + repository mapping for how closet/portfolio assets are stored.

## Implementation Plan

### Step 1 — Create client page widgets (shell-safe)
Create four new widget files under:
- `lib/features/clients/presentation/pages/`

Proposed widgets:
- `client_live_milestones_page.dart`
- `client_garment_architecture_page.dart`
- `client_portfolio_page.dart`
- `client_digital_closet_page.dart`

Each page must accept (or derive) the `userId` and render inside the shell.

Non-destructive rendering contract:
- Pages must be pure widgets (no route pushes).
- They must not assume scaffold/app bar ownership (the shell provides header + sidebar).

### Step 2 — Create Riverpod providers (client-scoped)
For each page:
- Add a provider that fetches required data (likely orders + profile data)

Preferred approach (minimize new infra):
- Reuse existing providers already used by `ClientDashboard`:
  - `ordersProvider(null)`
  - `userProfileProvider(userId)`

If reuse is not sufficient:
- Create dedicated providers that return derived views, e.g.:
  - `clientMilestonesProvider(userId)`
  - `clientArchitectureProvider(userId)`
  - `clientPortfolioProvider(userId)`
  - `clientClosetProvider(userId)`

### Step 3 — Wire page widgets into `MainPage._getDesktopPages('client', ...)`
Update `lib/features/dashboard/presentation/pages/main_page.dart`:
- Replace the `const Placeholder()` widgets with the new page widgets.
- Ensure indices match sidebar onTap mappings:
  - Live Milestones → index 5
  - Garment Architecture → index 6
  - Portfolio → index 7
  - Digital Closet → index 8

Also ensure Messages/Settings/Insights/My Profile indices remain consistent.

### Step 4 — Remove any remaining route-based behavior for these sidebar items
Ensure client sidebar item onTap handlers use:
- `setState(() => _currentIndex = <index>)`

No `Navigator.pushNamed` for these items.

### Step 5 — Implement Firestore fetching + loading/error states
Each page must provide:
- Loading state: skeleton/progress UI
- Error state: user-friendly error widget

Use established patterns from existing code (e.g., `ErrorStateWidget`, async value handling).

### Step 6 — Validate with desktop shell behavior
Manual test checklist:
- On desktop (width > 1000): clicking each sidebar item updates content inside shell.
- Switching between the 4 items does not open new routes.
- Messages/Settings/Insights/My Profile still work and highlight correctly.

### Step 7 — Automated checks
- `flutter analyze` must pass.
- Add/extend widget tests only if existing test harness covers this navigation.

## Files to Change / Add
### Change
- `lib/features/dashboard/presentation/pages/main_page.dart`

### Add
- `lib/features/clients/presentation/pages/client_live_milestones_page.dart`
- `lib/features/clients/presentation/pages/client_garment_architecture_page.dart`
- `lib/features/clients/presentation/pages/client_portfolio_page.dart`
- `lib/features/clients/presentation/pages/client_digital_closet_page.dart`

Optional (if not reusing existing providers):
- `lib/features/clients/presentation/providers/client_*_provider.dart`

## Open Questions (to resolve while implementing)
1. How are “milestones” represented in Firestore/Realtime? (orders status? separate milestone collection?)
2. Which existing providers give the correct data for portfolio/closet visuals?
3. Do these pages need pagination or filtering by status/date?

