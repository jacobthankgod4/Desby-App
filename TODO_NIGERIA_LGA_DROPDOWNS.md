# TODO - Nigeria Country, State, and LGA Dropdowns Implementation

## Plan
1. ✅ Analyze codebase and identify files with Country, State, LGA fields
2. ✅ Get user confirmation on plan
3. ✅ Create Nigeria LGA data file (lib/core/constants/nigeria_lga_data.dart)
4. ✅ Update tailor_onboarding_page.dart with dropdowns
5. ✅ Update apprentice_onboarding_page.dart with dropdowns

## Files to Edit
- [x] lib/core/constants/nigeria_lga_data.dart (NEW FILE - COMPLETED)
- [x] lib/features/tailor/presentation/pages/tailor_onboarding_page.dart (COMPLETED)
- [x] lib/features/apprenticeship/presentation/pages/apprentice_onboarding_page.dart (COMPLETED)

## Implementation Complete ✅

### Changes Made:

#### 1. Created `lib/core/constants/nigeria_lga_data.dart`
- Complete Nigerian LGA database with all 774 LGAs
- Organized by 37 states (36 states + FCT)
- Each LGA mapped to its headquarters
- Helper methods:
  - `getLgasForState(state)` - Get all LGAs for a specific state
  - `getHeadquartersForLga(state, lga)` - Get headquarters for an LGA

#### 2. Updated `lib/features/tailor/presentation/pages/tailor_onboarding_page.dart`
- Replaced text fields with dropdowns for:
  - Country (Nigeria only - fixed selection)
  - State (all 37 states via `NigeriaLgaData.states`)
  - LGA (cascading - populates when state is selected)
- Added `_buildDropdown()` widget method
- Implemented cascade logic: selecting a state populates available LGAs
- Changed from text controllers to string variables:
  - `String? _selectedCountry = 'Nigeria'`
  - `String? _selectedState`
  - `String? _selectedLga`
  - `List<String> _availableLgas = []`
- Updated validation logic to check dropdown values
- Updated review step to display dropdown selections

#### 3. Updated `lib/features/apprenticeship/presentation/pages/apprentice_onboarding_page.dart`
- Replaced state text field with dropdown
- Changed from text controller to string variable:
  - `String? _selectedState`
- Added `_buildStateDropdown()` widget method
- Integrated with `NigeriaLgaData.states` for all 37 states
- Updated validation logic
- Updated profile save to use dropdown value

## Key Features:
✅ Complete 774 LGAs database
✅ Cascading state → LGA selection
✅ Proper validation for all fields
✅ Consistent UI with amber/dark theme
✅ Both onboarding flows updated

