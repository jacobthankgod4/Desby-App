# Dashboard Desktop Mode Fix Plan

## Issues Identified:
1. **ClientDashboard**: Uses `ordersProvider(null)` - passing null for userId causes crashes
2. **ApprenticeDashboard**: Returns early without DesktopDashboardShell when apprenticeship is null, breaking layout
3. **TailorDashboard**: Provider errors can cause red screens on desktop mode
4. **Pattern**: Inconsistent error handling across user type dashboards
5. **UI Brand**: Desktop shell didn't use Amber (#FFC107) and Deep Navy Green (#0A1921, #1B3022) colors

## Fix Plan:
- [x] 1. Fix ClientDashboard - proper null check for userId
- [x] 2. Fix ApprenticeDashboard - always wrap in DesktopDashboardShell 
- [x] 3. Fix TailorDashboard - add null safety for providers
- [x] 4. Verify FabricSellerDashboard patterns
- [x] 5. Fix DesktopDashboardShell UI colors to use brand colors:
   - Scaffold background: AppColors.darkNavy (#0A1921)
   - Header: AppColors.darkNavy with amber border
   - Sidebar: AppColors.darkGreen (#1B3022)
   - NavItem: Amber highlight for active, white for inactive
   - Logo block: Amber accent
