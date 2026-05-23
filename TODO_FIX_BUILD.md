# Build Fix TODO

## Status: In Progress

### Completed
- [x] 1. Added missing fields to UserProfile entity:
  - businessState
  - latitude  
  - longitude
  - workingHoursByDay (BusinessHours class)
- [x] 2. Updated copyWith, toJson, fromJson, props for new fields
- [x] 3. Fixed syntax errors in main_page.dart (indentation)

### In Progress
- [ ] 4. Run flutter clean and verify build

### Remaining Issues
- [ ] Check test file error (unrelated to main task)

## Notes
- The main_page.dart syntax error at line 81 appears to be a false positive after fixes
- Need to run flutter clean to clear any cached analysis
