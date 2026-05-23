# Tailor Shop Enhancement Plan

## Task: Image Upload, Drag-and-Drop, CRUD Operations on Tailor Dashboard

### Steps to Complete:

1. [ ] Add Firebase Storage dependency to pubspec.yaml
2. [ ] Create Firebase Storage service for image uploads
3. [ ] Update ShopProduct entity for image handling
4. [ ] Update shop_setup_page.dart with:
   - [ ] Image upload functionality (camera + gallery)
   - [ ] Display product images in list
   - [ ] Full CRUD (Edit/Update products)
   - [ ] Drag-and-drop for reordering
5. [ ] Update tailor_dashboard.dart to show product images

---

## Dependencies Needed:
- firebase_storage: ^11.6.0
- image_picker: ^1.0.0 (already available)

## Files to Modify:
1. pubspec.yaml - Add firebase_storage
2. lib/core/services/image_upload_service.dart - New service
3. lib/features/tailor/domain/entities/shop_product.dart - Already has imageUrls
4. lib/features/tailor/presentation/pages/shop_setup_page.dart - Main update
5. lib/features/dashboard/presentation/pages/tailor_dashboard.dart - Add products section

