# PHASE 1 SETUP GUIDE: Dependency Management & Build Configuration

## Overview
This guide walks through completing SETUP PHASE 1 with all verification steps.

**Status**: Phase 1 Files Created ✅
**Next**: Execute verification steps below

---

## STEP 1: Verify Flutter Installation & PATH

### Check Flutter Installation
```bash
# Find Flutter installation
which flutter

# If not found, check common locations
ls -la ~/flutter/bin/flutter
ls -la /usr/local/flutter/bin/flutter
```

### Add Flutter to PATH (if needed)

**Option A: Temporary (current session only)**
```bash
export PATH="$PATH:$HOME/flutter/bin"
flutter --version
```

**Option B: Permanent (add to shell profile)**

For **zsh** (macOS default):
```bash
# Open your shell profile
nano ~/.zshrc

# Add this line at the end
export PATH="$PATH:$HOME/flutter/bin"

# Save and reload
source ~/.zshrc
flutter --version
```

For **bash**:
```bash
nano ~/.bash_profile
# Add: export PATH="$PATH:$HOME/flutter/bin"
source ~/.bash_profile
```

### Verify Flutter Setup
```bash
flutter --version
flutter doctor
```

**Expected Output**:
```
Flutter 3.x.x • channel stable
Dart 3.x.x
```

---

## STEP 2: Download Dependencies

Once Flutter is in PATH:

```bash
cd /Users/mac/desby_app

# Clean previous state (optional but recommended)
flutter clean

# Get all dependencies
flutter pub get
```

**Expected Output**:
```
Running "flutter pub get" in desby_app...
Resolving dependencies...
+ build_runner 2.4.6
+ cupertino_icons 1.0.8
+ device_info_plus 9.1.1
+ dio 5.3.1
+ equatable 2.0.5
+ flutter 3.x.x
+ flutter_dotenv 5.1.0
+ flutter_lints 6.0.0
+ flutter_riverpod 2.4.0
+ flutter_secure_storage 9.0.0
+ freezed 2.4.1
+ freezed_annotation 2.4.1
+ google_fonts 6.1.0
+ hive 2.2.3
+ hive_flutter 1.1.0
+ intl 0.19.0
+ json_annotation 4.8.1
+ json_serializable 6.7.1
+ logger 2.0.1
+ mockito 5.4.4
+ mocktail 1.0.0
+ package_info_plus 5.0.1
+ pretty_dio_logger 1.3.1
+ retrofit 4.1.0
+ retrofit_generator 8.1.0
+ riverpod 2.4.0
+ riverpod_annotation 2.3.0
+ riverpod_generator 2.3.9
+ shared_preferences 2.2.2
Got dependencies!
```

---

## STEP 3: Verify Dependency Resolution

### Check for Conflicts
```bash
flutter pub outdated
```

**Expected Output**:
- No packages listed (all at latest stable versions)
- Or packages listed as "up-to-date"

### Analyze Project
```bash
flutter analyze
```

**Expected Output**:
```
Analyzing desby_app...
No issues found! (in X files)
```

---

## STEP 4: Setup Environment File

### Create .env from template
```bash
cd /Users/mac/desby_app

# Copy template to .env
cp .env.example .env

# Edit with your values (optional for now)
nano .env
```

**Verify .env is in .gitignore**:
```bash
grep "\.env" .gitignore
```

**Expected Output**:
```
.env
.env.local
.env.*.local
```

---

## STEP 5: Verify Generated Files Ignored

### Check .gitignore includes generated files
```bash
grep -E "\.g\.dart|\.freezed\.dart|\.config\.dart" .gitignore
```

**Expected Output**:
```
*.g.dart
*.freezed.dart
*.config.dart
```

---

## STEP 6: Verify pubspec.lock Created

```bash
ls -lh /Users/mac/desby_app/pubspec.lock
```

**Expected Output**:
```
-rw-r--r--  1 user  group  XXX KB  [DATE] pubspec.lock
```

---

## STEP 7: Test Build (Optional but Recommended)

### Test Android build
```bash
flutter build apk --debug 2>&1 | head -20
```

### Test iOS build
```bash
flutter build ios --debug 2>&1 | head -20
```

### Test Web build
```bash
flutter build web 2>&1 | head -20
```

---

## STEP 8: Commit to Git

```bash
cd /Users/mac/desby_app

# Check what will be committed
git status

# Add files
git add pubspec.yaml pubspec.lock build.yaml .env.example .gitignore PHASE_1_CHECKLIST.md SETUP_PHASES.md

# Commit
git commit -m "SETUP PHASE 1: Dependency Management & Build Configuration

- Added Riverpod ecosystem for state management
- Added Dio for networking with interceptors
- Added Hive for local storage
- Added Freezed for immutable models
- Added code generation configuration
- Added environment management
- Updated .gitignore for generated files"

# Verify
git log --oneline -5
```

---

## VERIFICATION CHECKLIST

Run through this checklist to confirm Phase 1 is complete:

```bash
# 1. Flutter is accessible
flutter --version
# ✅ Should show version 3.x.x

# 2. Dependencies resolved
flutter pub get
# ✅ Should complete without errors

# 3. No conflicts
flutter pub outdated
# ✅ Should show no deprecated packages

# 4. Project analyzes
flutter analyze
# ✅ Should show "No issues found!"

# 5. pubspec.lock exists
ls pubspec.lock
# ✅ Should exist

# 6. .env file exists
ls .env
# ✅ Should exist

# 7. .env is ignored
git check-ignore .env
# ✅ Should return .env (meaning it's ignored)

# 8. Generated files will be ignored
grep "\.g\.dart" .gitignore
# ✅ Should find the pattern

# 9. build.yaml exists
ls build.yaml
# ✅ Should exist

# 10. All files committed
git status
# ✅ Should show "nothing to commit, working tree clean"
```

---

## TROUBLESHOOTING

### Issue: "flutter: command not found"
**Solution**: Add Flutter to PATH (see Step 1)

### Issue: "version conflict" in pub get
**Solution**:
```bash
flutter pub upgrade
flutter pub get
```

### Issue: "Could not find package X"
**Solution**:
```bash
flutter pub cache clean
flutter pub get
```

### Issue: "build.yaml not recognized"
**Solution**: Ensure it's in project root:
```bash
ls -la build.yaml
# Should be in /Users/mac/desby_app/build.yaml
```

### Issue: ".env not loading"
**Solution**: This will be fixed in Phase 9 when we configure main.dart

### Issue: "pubspec.lock conflicts"
**Solution**:
```bash
rm pubspec.lock
flutter pub get
```

---

## WHAT'S BEEN CREATED

### Files Created
✅ `pubspec.yaml` - Updated with all dependencies
✅ `build.yaml` - Code generation configuration
✅ `.env.example` - Environment template
✅ `.gitignore` - Updated with generated files
✅ `PHASE_1_CHECKLIST.md` - Detailed checklist
✅ `SETUP_PHASES.md` - Full setup phases guide

### Dependencies Added (35 total)

**Production (24)**:
- riverpod, flutter_riverpod, riverpod_annotation
- dio, retrofit, pretty_dio_logger
- hive, hive_flutter, shared_preferences
- flutter_secure_storage
- freezed_annotation, json_annotation, equatable
- logger, intl, connectivity_plus, device_info_plus, package_info_plus
- flutter_dotenv, google_fonts, cupertino_icons

**Development (11)**:
- build_runner, riverpod_generator, freezed, json_serializable, retrofit_generator
- mockito, mocktail, flutter_lints, flutter_test

---

## NEXT PHASE

Once Phase 1 is verified and committed:

**→ SETUP PHASE 2: Project Architecture & Folder Structure**

This will create:
- Complete lib/ folder hierarchy
- Feature module templates
- Core infrastructure folders
- README documentation for each folder

---

## QUICK REFERENCE

### Essential Commands
```bash
# Get dependencies
flutter pub get

# Check for issues
flutter analyze

# Check outdated packages
flutter pub outdated

# Clean and rebuild
flutter clean && flutter pub get

# Run code generation (Phase 8)
flutter pub run build_runner build

# Watch mode for development (Phase 8)
flutter pub run build_runner watch
```

### File Locations
```
/Users/mac/desby_app/
├── pubspec.yaml          ← Dependencies
├── pubspec.lock          ← Locked versions
├── build.yaml            ← Code generation
├── .env                  ← Environment (local, not committed)
├── .env.example          ← Environment template
└── .gitignore            ← Git ignore rules
```

---

**Ready to proceed with Phase 2?**

Once you've completed the verification steps above, let me know and I'll create the complete project architecture and folder structure.
