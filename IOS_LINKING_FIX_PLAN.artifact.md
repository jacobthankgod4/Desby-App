# Expert Remediation Plan: iOS Abseil Linking Failure

## 1. Issue Analysis
The build is failing because the **Abseil (absl)** C++ library is being compiled as a framework, but the symbols are not being exported correctly to the main application binary. This results in "Undefined symbol" errors for critical utilities like `SimpleAtod` and `Base64Escape`.

## 2. Technical Audit Findings
*   **Version**: `abseil 1.20240722.0` (LTS July 2024).
*   **Status**: The `absl.framework` is successfully built in the `build/ios` directory but is "invisible" to the linker during the final assembly of the `desby_app.app`.
*   **Root Cause**: A known conflict in CocoaPods where C++ heavy pods (gRPC/Abseil) fail to propagate their symbols when used alongside `use_frameworks!` in a Flutter environment.

---

## 3. Remediation Strategy: The "Surgical Linker" Approach

### Step 1: Force Static Linkage
We will modify the `Podfile` to force `abseil` and `gRPC` to be linked as **Static Frameworks**. This ensures all symbols are embedded directly into the binary instead of being looked up at runtime.

### Step 2: Inject Explicit Search Paths
We will update the `LIBRARY_SEARCH_PATHS` and `FRAMEWORK_SEARCH_PATHS` in the `post_install` hook to point directly to the Abseil build output.

### Step 3: Hard-code Linker Flags
We will manually add `-lc++` and `-framework "abseil"` to the `OTHER_LDFLAGS` to ensure the Apple Clang linker doesn't skip these dependencies.

---

## 4. Implementation Tasks

1.  **Modify [Podfile](file:///Users/mac/desby_app/ios/Podfile)**:
    *   Add a logic block to `post_install` to identify `abseil` targets.
    *   Set `MACH_O_TYPE = 'staticlib'` for all Abseil-related pods.
    *   Ensure `CLANG_CXX_LANGUAGE_STANDARD = 'gnu++17'`.

2.  **Environment Cleanup**:
    *   Delete `ios/Pods` and `ios/Podfile.lock`.
    *   Run `pod cache clean --all`.
    *   Run `flutter pub get` and `pod install`.

3.  **Xcode Synchronization**:
    *   Verify the `xcconfig` files in `ios/Flutter` correctly inherit the new Pods flags.

## 5. Verification Command
```bash
cd ios && pod install
flutter build ios --simulator --debug
```

---
**Status**: Ready for execution. No user input required.
