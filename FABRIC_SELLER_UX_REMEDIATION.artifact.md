# Fabric Seller Ecosystem: UI/UX Hyper-Atomic Remediation Plan

This roadmap outlines the technical fixes and feature implementations required to bring the **Fabric Seller** journey to parity with the **Client** and **Tailor** "Ultra-Luxury" standards.

---

## 1. Phase P0: Navigation & Structural Stability

**Target File**: [`lib/features/dashboard/presentation/pages/main_page.dart`](file:///Users/mac/desby_app/lib/features/dashboard/presentation/pages/main_page.dart)

### 1.1 Index Alignment
*   **Issue**: `_getPages` (4 widgets) vs `_getNavItems` (5 items) creates index mismatch.
*   **Action**: Update `_getPages` for `fabric_seller` to include the missing 5th view.
*   **Proposed Stack**:
    1.  `FabricSellerDashboard` (Home)
    2.  `SellerInventoryPage` (My Shop - **NEW**)
    3.  `SellerOrdersPage` (Merchant Orders - **NEW**)
    4.  `ChatListPage` (Messages)
    5.  `ProfileViewPage` (My Identity)

### 1.2 Label & Icon Refinement
*   **Action**: Update `_getNavItems` for `fabric_seller` to use accurate business terminology:
    *   `OS` -> `SHOP`
    *   `ORDERS` -> `INVENTORY`
    *   `MARKET` -> `ORDERS`
    *   `CHATS` -> `CHATS`
    *   `PROFILE` -> `IDENTITY`

---

## 2. Phase P1: Core Business Operations

### 2.1 Inventory Management Page (**NEW**)
**Target File**: `lib/features/marketplace/presentation/pages/seller_inventory_page.dart`
*   **Features**:
    *   High-density list of all uploaded fabrics.
    *   Inline **Stock Adjustment** (Quick-update yardage).
    *   "Sold Out" toggle status.
    *   Delete/Archive fabric functionality.
*   **Provider**: `fabricRepositoryProvider`

### 2.2 Marketplace Fulfillment Engine (**NEW**)
**Target File**: `lib/features/marketplace/presentation/pages/seller_orders_page.dart`
*   **Features**:
    *   List of orders where `fabricSellerId == currentUserId`.
    *   **Uber/Fez Integration**: Adaptive logistics card directly inside the seller's order view.
    *   "Pack for Pickup" status button (Triggers the Uber/Fez dispatch).
    *   Buyer contact bridge (Context-aware chat).

---

## 3. Phase P2: UX Intelligence & Parity

### 3.1 Live Analytics Dashboard
**Target File**: [`lib/features/dashboard/presentation/pages/fabric_seller_dashboard.dart`](file:///Users/mac/desby_app/lib/features/dashboard/presentation/pages/fabric_seller_dashboard.dart)
*   **Fix**: Remove static StatCards (`$4.2k`, `12 orders`).
*   **Action**: Implement `RevenueStreamProvider` and `SellerOrderCounterProvider`.
*   **Feature**: "Low Stock Alert" list—shows fabrics with < 5 yards remaining.

### 3.2 Discoverability Linkage
**Target File**: [`lib/features/profile/presentation/pages/profile_view_page.dart`](file:///Users/mac/desby_app/lib/features/profile/presentation/pages/profile_view_page.dart)
*   **Feature**: When viewing a Seller's profile, add a **"BROWSE MERCHANT CATALOG"** button.
*   **Logic**: Navigator pushes to `FabricCatalogPage` filtered by `sellerId`.

---

## 4. Atomic Task List & Status

- [ ] **T-NAV-01**: Align `main_page.dart` indices and labels.
- [ ] **T-INV-01**: Implement `SellerInventoryPage.dart` (UI Only).
- [ ] **T-INV-02**: Wire `fabricRepository.deleteFabric` and `updateStock` logic.
- [ ] **T-ORD-01**: Implement `SellerOrdersPage.dart` with Uber/Fez card support.
- [ ] **T-DB-01**: Connect `fabric_seller_dashboard.dart` to live Firestore streams.
- [ ] **T-PROF-01**: Add "View Shop" bridge to `ProfileViewPage`.

---

## 5. Summary Table (Parity Audit)

| Feature | Client | Tailor | Seller (Current) | Seller (Target) |
| :--- | :--- | :--- | :--- | :--- |
| **Orders** | Active | Active | ❌ Missing | ✅ Phase P1 |
| **Inventory** | N/A | Active (Portfolio) | ❌ Missing | ✅ Phase P1 |
| **Logistics** | Native | Native | ⚠️ Mock Only | ✅ Integrated |
| **Analytics** | N/A | Business Insights | ⚠️ Mock Only | ✅ Phase P2 |

---

## Status: READY FOR ATOMIC EXECUTION
*This plan represents 100% parity across the Desby OS user spectrum.*
