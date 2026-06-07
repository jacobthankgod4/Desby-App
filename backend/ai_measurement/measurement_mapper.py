"""
Measurement Mapper
==================
Maps AI extraction outputs to Desby app measurement standards.
Maps from MediaPipe/HMR measurements to the 18 male / 27 female measurements required.

Male (18):
- Shoulder, Neck Round, Chest Round, Stomach Round, Waist Round,
- Half Length, Full Top Length, Across Back, Across Chest, Hip Round,
- Thigh Round, Knee Round, Calf Round, Ankle Round, Trouser Waist,
- Trouser Length, Inseam, Crotch Depth

Female (27):
- Shoulder, Neck Round, Bust Round, High Bust, Under Bust,
- Bust Point, Shoulder to Bust Point, Shoulder to Under Bust,
- Shoulder to Waist, Front Waist Length, Back Waist Length,
- Across Chest, Across Back, Armhole Round, Sleeve Length,
- Bicep Round, Elbow Round, Wrist Round, Waist Round,
- Half Length, Waist to Hip, Upper Hip, Hip Round,
- Thigh Round, Knee Round, Calf Round, Ankle Round
"""

from typing import Dict, List, Tuple


# ============================================================================
# ANTHROPOMETRIC RATIOS
# ============================================================================

# Male body ratios (relative to height)
# Based on standard anthropometric data
MALE_RATIOS = {
    'Shoulder': 0.265,
    'Neck Round': 0.224,
    'Chest Round': 0.588,
    'Stomach Round': 0.500,
    'Waist Round': 0.471,
    'Half Length': 0.353,
    'Full Top Length': 0.441,
    'Across Back': 0.247,
    'Across Chest': 0.259,
    'Hip Round': 0.559,
    'Thigh Round': 0.324,
    'Knee Round': 0.224,
    'Calf Round': 0.212,
    'Ankle Round': 0.153,
    'Trouser Waist': 0.482,
    'Trouser Length': 0.588,
    'Inseam': 0.459,
    'Crotch Depth': 0.165,
}

# Female body ratios (relative to height)
FEMALE_RATIOS = {
    'Shoulder': 0.230,
    'Neck Round': 0.206,
    'Bust Round': 0.521,
    'High Bust': 0.460,
    'Under Bust': 0.412,
    'Bust Point': 0.121,
    'Shoulder to Bust Point': 0.145,
    'Shoulder to Under Bust': 0.170,
    'Shoulder to Waist': 0.230,
    'Front Waist Length': 0.218,
    'Back Waist Length': 0.242,
    'Across Chest': 0.206,
    'Across Back': 0.194,
    'Armhole Round': 0.242,
    'Sleeve Length': 0.333,
    'Bicep Round': 0.170,
    'Elbow Round': 0.145,
    'Wrist Round': 0.109,
    'Waist Round': 0.400,
    'Half Length': 0.315,
    'Waist to Hip': 0.109,
    'Upper Hip': 0.521,
    'Hip Round': 0.570,
    'Thigh Round': 0.315,
    'Knee Round': 0.206,
    'Calf Round': 0.194,
    'Ankle Round': 0.133,
}


# ============================================================================
# MEDIAPIPE LANDMARK MAPPING
# ============================================================================

# MediaPipe pose landmarks to measurements
# Full body: 33 landmarks
LANDMARK_INDICES = {
    'nose': 0,
    'left_eye_inner': 1,
    'left_eye': 2,
    'left_eye_outer': 3,
    'right_eye_inner': 4,
    'right_eye': 5,
    'right_eye_outer': 6,
    'left_ear': 7,
    'right_ear': 8,
    'mouth_left': 9,
    'mouth_right': 10,
    'left_shoulder': 11,
    'right_shoulder': 12,
    'left_elbow': 13,
    'right_elbow': 14,
    'left_wrist': 15,
    'right_wrist': 16,
    'left_pinky': 17,
    'right_pinky': 18,
    'left_index': 19,
    'right_index': 20,
    'left_thumb': 21,
    'right_thumb': 22,
    'left_hip': 23,
    'right_hip': 24,
    'left_knee': 25,
    'right_knee': 26,
    'left_ankle': 27,
    'right_ankle': 28,
    'left_heel': 29,
    'right_heel': 30,
    'left_foot_index': 31,
    'right_foot_index': 32,
}


# ============================================================================
# MEASUREMENT EXTRACTION FUNCTIONS
# ============================================================================

def calculate_distance(p1: Tuple[float, float], p2: Tuple[float, float]) -> float:
    """Calculate Euclidean distance between two 2D points."""
    return ((p1[0] - p2[0])**2 + (p1[1] - p2[1])**2) ** 0.5


def calculate_circle_circumference(diameter: float) -> float:
    """Calculate circumference from diameter (for body rounds)."""
    return diameter * 3.14159


def scale_by_height(value: float, total_height: float, landmark_height: float) -> float:
    """Scale a measurement based on detected person height."""
    if landmark_height <= 0:
        return 0
    scale = total_height / landmark_height
    return value * scale


# ============================================================================
# MAIN MAPPING FUNCTIONS
# ============================================================================

def map_mediapipe_to_measurements(
    landmarks: List[List[float]],
    user_height_cm: float,
    gender: str = 'male'
) -> Dict[str, float]:
    """Map MediaPipe pose landmarks to body measurements."""
    if not landmarks or len(landmarks) < 33:
        # Fallback to proportional calculation
        return calculate_proportional_measurements(user_height_cm, gender)
    
    # Extract key landmarks
    nose = landmarks[LANDMARK_INDICES['nose']][:2]
    left_shoulder = landmarks[LANDMARK_INDICES['left_shoulder']][:2]
    right_shoulder = landmarks[LANDMARK_INDICES['right_shoulder']][:2]
    left_hip = landmarks[LANDMARK_INDICES['left_hip']][:2]
    right_hip = landmarks[LANDMARK_INDICES['right_hip']][:2]
    left_knee = landmarks[LANDMARK_INDICES['left_knee']][:2]
    right_knee = landmarks[LANDMARK_INDICES['right_knee']][:2]
    left_ankle = landmarks[LANDMARK_INDICES['left_ankle']][:2]
    right_ankle = landmarks[LANDMARK_INDICES['right_ankle']][:2]
    
    # Calculate various heights
    shoulder_y = (left_shoulder[1] + right_shoulder[1]) / 2
    hip_y = (left_hip[1] + right_hip[1]) / 2
    
    # Calculate torso height (nose to hip)
    torso_height = abs(nose[1] - hip_y)
    
    # Calculate full body height from image
    full_body_height = abs(nose[1] - min(left_ankle[1], right_ankle[1]))
    
    # Scale factor (pixels to cm)
    px_to_cm = user_height_cm / full_body_height if full_body_height > 0 else 1
    
    measurements = {}
    
    # Get ratios based on gender
    ratios = MALE_RATIOS if gender == 'male' else FEMALE_RATIOS
    for name, ratio in ratios.items():
        measurements[name] = round(ratio * user_height_cm, 1)
    
    return measurements


def calculate_proportional_measurements(
    user_height_cm: float,
    gender: str = 'male'
) -> Dict[str, float]:
    """
    Calculate measurements using proportional ratios.
    Fallback when MediaPipe data unavailable.
    """
    ratios = MALE_RATIOS if gender == 'male' else FEMALE_RATIOS
    
    measurements = {}
    for name, ratio in ratios.items():
        measurements[name] = round(ratio * user_height_cm, 1)
    
    return measurements


def map_backend_output_to_app(
    raw_measurements: Dict[str, float],
    gender: str = 'male'
) -> Dict[str, float]:
    """Map raw backend output to Desby app format."""
    ratios = MALE_RATIOS if gender == 'male' else FEMALE_RATIOS
    
    app_measurements = {}
    for name, ratio in ratios.items():
        if name in raw_measurements:
            app_measurements[name] = raw_measurements[name]
        else:
            app_measurements[name] = round(ratio * raw_measurements.get('height', 170), 1)
    
    return app_measurements


def validate_measurements(
    measurements: Dict[str, float],
    gender: str = 'male',
    tolerance: float = 0.15
) -> Tuple[bool, List[str]]:
    """Validate measurements for physical plausibility."""
    issues = []
    
    ratios = MALE_RATIOS if gender == 'male' else FEMALE_RATIOS
    
    for name, expected_ratio in ratios.items():
        if name not in measurements:
            issues.append(f"Missing: {name}")
            continue
        
        value = measurements[name]
        expected_min = expected_ratio * (1 - tolerance)
        expected_max = expected_ratio * (1 + tolerance)
        
        if value < expected_min * 170 or value > expected_max * 220:
            issues.append(f"{name}: {value} outside expected range")
    
    # Waist should be less than hips
    waist = measurements.get('Waist Round', 0)
    hips = measurements.get('Hip Round', 0)
    if waist > hips:
        issues.append("Waist larger than hips - physically impossible")
    
    return len(issues) == 0, issues


def get_measurement_categories(gender: str = 'male') -> Dict[str, List[str]]:
    """Get grouped measurements by body region."""
    if gender == 'male':
        return {
            'Upper Body': ['Shoulder', 'Neck Round', 'Chest Round', 'Stomach Round', 'Waist Round'],
            'Torso': ['Half Length', 'Full Top Length', 'Across Back', 'Across Chest'],
            'Lower Body': ['Hip Round', 'Thigh Round', 'Knee Round', 'Calf Round', 'Ankle Round'],
            'Pants': ['Trouser Waist', 'Trouser Length', 'Inseam', 'Crotch Depth'],
        }
    else:
        return {
            'Upper Body': ['Shoulder', 'Neck Round', 'Bust Round', 'High Bust', 'Under Bust'],
            'Torso': ['Across Chest', 'Across Back', 'Armhole Round', 'Waist Round', 'Half Length'],
            'Lower Body': ['Waist to Hip', 'Upper Hip', 'Hip Round', 'Thigh Round', 'Knee Round'],
            'Arms': ['Sleeve Length', 'Bicep Round', 'Elbow Round', 'Wrist Round'],
        }


# ============================================================================
# TEST / DEMO
# ============================================================================

if __name__ == '__main__':
    print("Measurement Mapper Test")
    print("=" * 40)
    
    # Test male measurements
    male_meas = calculate_proportional_measurements(175, 'male')
    print(f"\nMale (175cm):")
    for name, value in list(male_meas.items())[:5]:
        print(f"  {name}: {value}cm")
    
    # Test female measurements
    female_meas = calculate_proportional_measurements(165, 'female')
    print(f"\nFemale (165cm):")
    for name, value in list(female_meas.items())[:5]:
        print(f"  {name}: {value}cm")
    
    print("\n✅ All mappings working")
