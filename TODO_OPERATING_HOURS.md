# Profile Edit Page - Operating Hours Update

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
