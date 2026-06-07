# TODO: Fix Dart Analyzer Errors

Based on the analysis of the Dart analyzer output, here are the errors that need to be fixed:

## Priority 1 - Critical Errors (severity 8)

### 1. seller_orders_page.dart (line 13)
- **Error**: `FutureProviderFamily<List<OrderEntity>, OrderStatus?>` can't be assigned to `ProviderListenable<dynamic>`
- **Cause**: Using `ordersProvider` without a parameter when it's a family provider
- **Fix**: Pass null as status parameter: `ordersProvider(null)`

### 2. search_hero.dart (line 151)
- **Error**: Named parameter 'scrollController' isn't defined
- **Cause**: DraggableScrollableSheet doesn't accept scrollController
- **Fix**: Remove scrollController parameter

### 3. uber_logistics_repository_impl.dart (multiple lines)
- **Error**: ServerFailure can't be assigned to Failure<dynamic>
- **Cause**: Type mismatch in Failure handling
- **Fix**: Create proper typed failure or cast appropriately

### 4. order_detail_page.dart (multiple issues)
- **Error**: Local variable referenced before declaration (_buildAdaptiveLogisticsCard, _buildFezTimeline)
- **Cause**: Methods defined after use
- **Fix**: Move method definitions before use

## Priority 2 - Major Errors (severity 4)

### 5. tailor_finder_desktop.dart (line 29)
- **Error**: Missing type annotation, syntax issues
- **Fix**: Add proper type annotation

### 6. Various unused imports/elements
- Fix by removing unused imports

## Priority 3 - Minor Issues (severity 2)

### 7. Various lint warnings
- Fix as needed

---

## Execution Plan

### Step 1: Fix seller_orders_page.dart
- Change `ordersProvider` to `ordersProvider(null)`

### Step 2: Fix search_hero.dart  
- Remove scrollController from DraggableScrollableSheet

### Step 3: Fix uber_logistics_repository_impl.dart
- Add proper typing for Failure

### Step 4: Fix order_detail_page.dart
- Reorganize method definitions
- Fix dead code issues

### Step 5: Fix tailor_finder_desktop.dart
- Fix line 29 syntax
