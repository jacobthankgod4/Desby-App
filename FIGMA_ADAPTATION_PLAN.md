# Figma Marketplace UI/UX Adaptation Plan

## Objective
Adapt the Figma pixel-perfect marketplace specifications to the existing Fabric Marketplace, strictly adhering to Desby brand colors.

## Brand Color Mapping (Figma → Desby)

| Figma Color Name | Figma Value | Desby AppColors Mapping |
|------------------|-------------|------------------------|
| Nav Green | #1AAF38 | AppColors.darkGreen (#1B3022) |
| CTA Orange | #F4A62A | AppColors.amber (#FFC107) |
| Background | #EAF2F7 | AppColors.backgroundLight (#FAFAFA) |
| Sidebar BG | transparent | AppColors.bgSidebar (#F5F7FA) |
| Divider | #DCE4EA | AppColors.borderLight (#D9E2EA) |
| Active Header | #18A739 | AppColors.success (#4CAF50) |
| Card Border | #DDE3E8 | AppColors.borderLight (#D9E2EA) |
| Card Fill | #FFFFFF | AppColors.surfaceLight (#FFFFFF) |
| Text Primary | #1F2933 | AppColors.textPrimary (#0F172A) |
| Text Secondary | #7B8794 | AppColors.textSecondary (#64748B) |

## Figma Layout Specifications (to implement)

```
ROOT FRAME: 537w × 2048h
├── LEFT SIDEBAR: 145px width
├── CONTENT GUTTER: 6px
├── MAIN CONTENT: 356px width
└── RIGHT MARGIN: 30px
```

## Implementation Tasks

### Task 1: Update AppColors with Figma Mappings
- Add `figmaNavGreen` = #1B3022 (mapped to darkGreen)
- Add `figmaBackground` = #FAFAFA
- Add `figmaDivider` = #D9E2EA

### Task 2: Refactor fabric_catalog_page.dart
- Implement desktop 3-column layout per Figma spec
- TopNav with branding, search, icons, CTA button
- Left filter sidebar (145px width)
- Main content area with 3-column grid

### Task 3: Create Reusable Components
- MarketTopNav widget
- FilterSidebar widget (fabric categories)
- ProductCard widget (114×170 per spec)
- PromoTile widget

### Task 4: Fabric Category Mapping
| Figma Filter (Car) | → | Fabric Filter |
|--------------------|---|----------------|
| Make | → | Material (Cotton, Silk, Linen...) |
| Year | → | Season/Collection |
| Condition | → | Quality Grade |
| Transmission | → | Weave Type |
| Mileage | → | Stock Quantity |
| Body | → | Application |

## Status: IN PROGRESS

## Dependent Files to Edit
- lib/theme/colors.dart
- lib/features/marketplace/presentation/pages/fabric_catalog_page.dart
- lib/features/marketplace/presentation/widgets/fabric_card_grid.dart

## Followup Steps
1. Run flutter build to verify compilation
2. Test responsive desktop layout
3. Verify brand color consistency
