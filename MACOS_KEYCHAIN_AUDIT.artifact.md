# Atomic Audit: macOS [firebase_auth/keychain-error]

## 1. Issue Description
The Desby App fails to authenticate on macOS in Debug mode with the error `[firebase_auth/keychain-error]`. This occurs despite disabling the App Sandbox and attempting to set Firebase persistence to `Persistence.NONE`.

## 2. Technical Root Causes

### A. Persistence Race Condition
*   **Audit**: `setPersistence(Persistence.NONE)` is called in the `AuthStateNotifier` constructor but is **not awaited**.
*   **Risk**: If `signInWithEmailAndPassword` is triggered immediately (e.g., via auto-login or fast user action), the Firebase SDK may still be initialized with the default `LOCAL` persistence, which attempts to access the Keychain.

### B. Apple ID Prefix Mismatch
*   **Audit**: Even with Sandbox disabled, macOS security policies often require a valid `AppIdentifierPrefix` to access the system keychain for non-signed binaries.
*   **Finding**: The project is using `com.desby.app` but lacks a "Team ID" prefix in the `GoogleService-Info.plist` or entitlements, causing the Keychain to reject access from an "Unknown" source.

### C. Dependency Noise
*   **Audit**: `flutter_secure_storage` is also used in the project.
*   **Risk**: If `flutter_secure_storage` is invoked before or during auth, it will also throw a Keychain error, which might be masking or compounding the Firebase issue.

---

## 3. Remediation Strategy

### Step 1: Sequential Initialization
Move the `setPersistence` call to the very beginning of the `main()` function in `lib/main.dart` and **await** it. This ensures the entire app is running in "In-Memory" mode before any UI or repository is created.

### Step 2: Persistence Force-Switch
Instead of `Persistence.NONE`, try `Persistence.INDEXED_DB` (if available via fallback) or explicitly ensuring `firebase_auth` is configured *after* the persistence switch is confirmed.

### Step 3: Bundle Identifier Verification
Confirm that `PRODUCT_BUNDLE_IDENTIFIER` in `macos/Runner/Configs/AppInfo.xcconfig` matches the `com.desby.app` identifier in the Firebase console exactly.

---

## 4. Immediate Action Plan

1.  **Modify `lib/main.dart`**: Move and await `setPersistence` before `Firebase.initializeApp` or immediately after.
2.  **Add Logger**: Log the exact result of the persistence switch to confirm it passed.
3.  **Clean Cache**: Delete `~/Library/Caches/com.desby.app` to clear any corrupted local storage states.
