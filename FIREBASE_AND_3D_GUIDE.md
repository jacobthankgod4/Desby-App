# Desby OS: Live Integration & 3D Mannequin Guide

This guide provides the final technical steps to connect **Desby OS** to your live Firebase backend and replace the 3D placeholder with a fully interactive model.

---

## Part 1: Firebase Database Activation

To activate your specific Firebase database and ensure real-time persistence, follow these detailed steps to download and place your configuration files correctly:

### 1. Access the Firebase Console
*   Navigate to the [Firebase Console](https://console.firebase.google.com/).
*   Select your existing project or click **Add project** to create a new one named `Desby OS`.

### 2. Download Configuration Files
*   **For Android**:
    *   In the Project Overview or Project Settings, find the "Your apps" section.
    *   If the app is not registered, click the **Android icon** and enter your package name: `com.desby.app`.
    *   Click the `google-services.json` button to download the file.
*   **For iOS**:
    *   Select the iOS app in the "Your apps" section.
    *   If needed, register it using your Apple bundle ID: `com.example.desbyApp`.
    *   Click `GoogleService-Info.plist` to download the file.
    *   **Pro Tip**: You can also use **Swift Package Manager** in Xcode by adding `https://github.com/firebase/firebase-ios-sdk` to your packages, but for Flutter, keeping Firebase in the `Podfile` is recommended for better plugin compatibility.

### 3. Place `google-services.json` (Android)
*   Locate your Flutter project's root folder.
*   Copy the `google-services.json` file.
*   Paste it into the following directory: `[Your Project]/android/app/`.

### 4. Place `GoogleService-Info.plist` (iOS)
*   **Crucial**: You must use Xcode to add this file so it is properly linked to the project build.
*   Open your project in Xcode (open `ios/Runner.xcworkspace`).
*   In the left-hand Project Navigator, right-click the **Runner** folder.
*   Select **Add Files to "Runner"...**.
*   Choose your `GoogleService-Info.plist` and ensure **"Copy items if needed"** is checked.

### 5. Add Firebase SDK (Android Gradle Configuration)
To make the `google-services.json` values accessible to the Firebase SDK, you must configure your Android Gradle files:

**A. Root-level Gradle file (`android/build.gradle.kts`)**
Add the Google services plugin to the `plugins` block:
```kotlin
plugins {
    // ... other plugins
    id("com.google.gms.google-services") version "4.4.2" apply false
}
```

**B. App-level Gradle file (`android/app/build.gradle.kts`)**
Add the plugin and the Firebase BoM (Bill of Materials) to manage versions:
```kotlin
plugins {
    id("com.android.application")
    id("com.google.gms.google-services") // Add this line
    // ... other plugins
}

dependencies {
    // Import the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:33.1.2"))

    // Add dependencies for Firebase products
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
}
```

### 6. Enable Backend Services
In the Firebase Console sidebar, ensure the following are enabled:
*   **Authentication**: Enable "Email/Password" sign-in provider.
*   **Firestore Database**: Create a database in "Production" or "Test" mode.

### 7. Restart the App
*   Stop any currently running instances of the app.
*   Run `flutter clean` in your terminal to clear old builds.
*   Run `flutter pub get`.
*   Start the app again using `flutter run` or your IDE's play button to apply the new configuration.

---

## Part 2: Interactive 3D Model Integration

To upgrade the measurement screen from a placeholder to a world-class interactive 3D mannequin, follow these steps:

### 1. Install the 3D Package
Add the following to your `pubspec.yaml` under dependencies:
```yaml
dependencies:
  o3d: ^3.1.0
```
Then run `flutter pub get` in your terminal.

### 2. Prepare your 3D Asset
*   Obtain a `.glb` mannequin model (e.g., from Sketchfab or a 3D designer).
*   Create a folder: `assets/models/`.
*   Place your file there: `assets/models/mannequin.glb`.
*   Register it in `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/images/
    - assets/models/mannequin.glb
```

### 3. Update the UI Code
In `lib/features/clients/presentation/pages/unified_add_client_page.dart`, update the code as follows:

**Step A: Import the package**
```dart
import 'package:o3d/o3d.dart';
```

**Step B: Add the Controller to your State class**
```dart
O3DController _o3dController = O3DController();
```

**Step C: Replace the placeholder in `_buildMeasurementStep`**
Replace the `Center(child: Container(...))` block with the real `O3D` widget:
```dart
O3D(
  controller: _o3dController,
  src: 'assets/models/mannequin.glb',
  autoRotate: true,
  backgroundColor: Colors.transparent,
  cameraTarget: CameraTarget(0, 1, 0),
  cameraOrbit: CameraOrbit(0, 75, 100),
)
```

### 4. Expert UI Tip: Dynamic Rotation
To make the app even more expert, tell the model to rotate when a tailor clicks a measurement field. 
**Example for "Back Length":**
```dart
TextField(
  onTap: () {
    // Rotates the model 180 degrees to show the back
    _o3dController.cameraOrbit(180, 75, 100); 
  },
  // ... rest of your field code
)
```

---

**Desby OS is now live and fully interactive!** 🧵✨🏆
