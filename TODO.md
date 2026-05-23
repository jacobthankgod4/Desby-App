# [P0] Firebase Storage CORS Fix - Profile Image Upload Blocked

## Task
Fix CORS error when uploading profile images from localhost development. The app cannot access Firebase Storage from `http://localhost:49977` due to CORS policy blocking the request.

## Root Cause
1. The `cors.json` file exists in the project but was never applied to the Firebase Storage bucket
2. The bucket `desby-os.firebasestorage.app` doesn't exist yet (requires creation/upgrade in Firebase Console)
3. Even after creating the bucket, CORS config must be explicitly deployed

## Steps

- [ ] 1. Create bucket in Firebase Console: https://console.firebase.google.com/project/desby-os/storage
      - Go to "Build" → "Storage" → "Get Started"
      - Choose a plan (Blaze with billing or use test mode)
  - OR create a new Firebase project if needed
- [ ] 2. Apply CORS config to the bucket:
      ```bash
      gsutil cors set cors.json gs://[bucket-name]
      ```
- [ ] 3. Verify CORS is applied:
      ```bash
      gsutil cors get gs://[bucket-name]
      ```

## Updated cors.json (already applied)
```json
[
  {
    "origin": ["*"],
    "method": ["GET", "POST", "PUT", "DELETE", "HEAD", "OPTIONS"],
    "responseHeader": ["Content-Type", "x-goog-resumable", "Authorization", "Content-Length", "Accept", "Origin", "X-Requested-With", "Access-Control-Request-Method", "Access-Control-Request-Headers"],
    "maxAgeSeconds": 3600
  }
]
```

## Alternative Workaround (for local testing)
If bucket is not available, modify `image_upload_service.dart` to use a different upload method or mock service.

---

# Profile Edit Page - Operating Hours Update Plan

## Task
Replace the simple text input for operating hours in profile_edit_page.dart with the modern toggle + time picker UI.

## Steps

- [ ] 1. Fix the corrupted import line at the beginning of the file
- [ ] 2. Add state fields for working hours: _dayOpen, _openTimes, _closeTimes Maps
- [ ] 3. Add _buildWorkingHoursSection() method with toggle + time picker UI for each day
- [ ] 4. Add _buildDayRow() helper method
- [ ] 5. Add _buildTimeChip() helper method
- [ ] 6. Add _getHoursSummary() helper method
- [ ] 7. Update _initializeControllers() to parse existing workingHoursByDay data
- [ ] 8. Update _saveProfile() to save workingHoursByDay as BusinessHours object
- [ ] 9. Replace the simple text field with _buildWorkingHoursSection() in the form
- [ ] 10. Fix dispose() to remove _workingHoursController

## Reference
See tailor_onboarding_page.dart for the working hours UI implementation pattern.
