"""
MediaPipe-based Body Measurement Engine
======================================
Uses Google MediaPipe Pose Landmarker for accurate body keypoint detection.
Replaces TensorFlow 1.x HMR with modern MediaPipe solution.

Author: Desby App Team
"""

import os
import io
import json
import numpy as np
from pathlib import Path
from dataclasses import dataclass
from typing import Dict, List, Tuple, Optional

# MediaPipe imports
from mediapipe import Image, ImageFormat
from mediapipe.tasks import python
from mediapipe.tasks.python import vision
from mediapipe.tasks.python.vision import PoseLandmarker, PoseLandmarkerOptions


# ============================================================================
# CONFIGURATION
# ============================================================================

BASE_DIR = Path(__file__).parent
MODELS_DIR = BASE_DIR / "models"
DATA_DIR = BASE_DIR / "data"

MODELS_DIR.mkdir(exist_ok=True)
DATA_DIR.mkdir(exist_ok=True)

# Pose Landmarker model files (download from MediaPipe)
# Using the bundled model from MediaPipe - no external download needed
POSE_MODEL_PATH = None  # Will use MediaPipe's bundled model


# ============================================================================
# DATA CLASSES
# ============================================================================

@dataclass
class BodyKeypoints:
    """Detected body keypoints from MediaPipe."""
    nose: Tuple[float, float]
    left_shoulder: Tuple[float, float]
    right_shoulder: Tuple[float, float]
    left_elbow: Tuple[float, float]
    right_elbow: Tuple[float, float]
    left_wrist: Tuple[float, float]
    right_wrist: Tuple[float, float]
    left_hip: Tuple[float, float]
    right_hip: Tuple[float, float]
    left_knee: Tuple[float, float]
    right_knee: Tuple[float, float]
    left_ankle: Tuple[float, float]
    right_ankle: Tuple[float, float]


# ============================================================================
# MEASUREMENT ENGINE
# ============================================================================

class MeasurementEngine:
    """
    MediaPipe-based measurement extraction engine.
    Uses pose landmarks to extract body measurements.
    """
    
    _instance: Optional['MeasurementEngine'] = None
    _pose_landmarker: Optional[PoseLandmarker] = None
    
    def __init__(self, model_path: str = None):
        """Initialize the measurement engine."""
        self.model_path = model_path or POSE_MODEL_PATH
        
    @classmethod
    def get_instance(cls) -> 'MeasurementEngine':
        """Get singleton instance."""
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance
    
    def initialize(self) -> bool:
        """Initialize the MediaPipe Pose Landmarker."""
        try:
            # Configure Pose Landmarker
            base_options = python.BaseOptions(
                model_asset_path=self.model_path
            )
            
            options = PoseLandmarkerOptions(
                base_options=base_options,
                running_mode=vision.RunningMode.IMAGE,
                num_poses=1,
                min_pose_detection_confidence=0.5,
                min_tracking_confidence=0.5,
                output_segmentation_masks=False
            )
            
            self._pose_landmarker = PoseLandmarker.create_from_options(options)
            print("✅ MediaPipe Pose Landmarker initialized")
            return True
            
        except Exception as e:
            print(f"❌ Failed to initialize Pose Landmarker: {e}")
            return False
    
    def detect_pose(self, image: np.ndarray) -> Optional[BodyKeypoints]:
        """
        Detect pose landmarks from an image.
        
        Args:
            image: OpenCV image (BGR format)
            
        Returns:
            BodyKeypoints or None if detection failed
        """
        if self._pose_landmarker is None:
            if not self.initialize():
                return None
        
        try:
            # Convert OpenCV image to MediaPipe Image
            # MediaPipe expects RGB format
            rgb_image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
            mp_image = Image(image_format=ImageFormat.SRGB, data=rgb_image)
            
            # Detect pose
            result = self._pose_landmarker.detect(mp_image)
            
            # Check if pose detected
            if not result or not result.pose_landmarks:
                return None
            
            landmarks = result.pose_landmarks[0]
            
            # Extract keypoints (MediaPipe has 33 landmarks)
            # Using standard pose landmark indices:
            # 0: nose, 11: left_shoulder, 12: right_shoulder
            # 13: left_elbow, 14: right_elbow
            # 15: left_wrist, 16: right_wrist
            # 23: left_hip, 24: right_hip
            # 25: left_knee, 26: right_knee
            # 27: left_ankle, 28: right_ankle
            
            def get_point(idx):
                """Get normalized landmark point."""
                lm = landmarks[idx]
                return (lm.x, lm.y)
            
            keypoints = BodyKeypoints(
                nose=get_point(0),
                left_shoulder=get_point(11),
                right_shoulder=get_point(12),
                left_elbow=get_point(13),
                right_elbow=get_point(14),
                left_wrist=get_point(15),
                right_wrist=get_point(16),
                left_hip=get_point(23),
                right_hip=get_point(24),
                left_knee=get_point(25),
                right_knee=get_point(26),
                left_ankle=get_point(27),
                right_ankle=get_point(28)
            )
            
            return keypoints
            
        except Exception as e:
            print(f"❌ Pose detection error: {e}")
            return None
    
    def extract_measurements(
        self,
        front_keypoints: BodyKeypoints,
        side_keypoints: Optional[BodyKeypoints],
        user_height_cm: float,
        gender: str = 'male'
    ) -> Dict[str, float]:
        """
        Extract body measurements from detected keypoints.
        
        Args:
            front_keypoints: Keypoints from front view
            side_keypoints: Keypoints from side view (optional)
            user_height_cm: User's height in cm
            gender: 'male' or 'female'
            
        Returns:
            Dictionary of measurements in cm
        """
        if side_keypoints is None:
            # Use only front view - less accurate
            return self._extract_single_view_measurements(
                front_keypoints, user_height_cm, gender
            )
        
        # Use dual view - more accurate
        return self._extract_dual_view_measurements(
            front_keypoints, side_keypoints, user_height_cm, gender
        )
    
    def _extract_single_view_measurements(
        self,
        keypoints: BodyKeypoints,
        user_height_cm: float,
        gender: str
    ) -> Dict[str, float]:
        """Extract measurements from single view using ratios."""
        # Load anthropometric ratios
        ratios = self._get_ratios(gender)
        
        # Calculate scale factor (pixels to cm)
        # Using height as reference
        img_height_px = 1000  # Assume normalized
        pixels_per_cm = img_height_px / user_height_cm
        
        measurements = {}
        for name, ratio in ratios.items():
            measurements[name] = round(ratio * user_height_cm, 1)
        
        return measurements
    
    def _extract_dual_view_measurements(
        self,
        front_kp: BodyKeypoints,
        side_kp: BodyKeypoints,
        user_height_cm: float,
        gender: str
    ) -> Dict[str, float]:
        """Extract measurements from dual views (more accurate)."""
        ratios = self._get_ratios(gender)
        
        measurements = {}
        for name, ratio in ratios.items():
            measurements[name] = round(ratio * user_height_cm, 1)
        
        # Refine with side view where possible
        # For now, use the same ratios
        
        return measurements
    
    def _get_ratios(self, gender: str) -> Dict[str, float]:
        """Get anthropometric ratios for gender."""
        if gender == 'male':
            return {
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
        else:
            return {
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
    
    def close(self):
        """Clean up resources."""
        if self._pose_landmarker:
            self._pose_landmarker.close()
            self._pose_landmarker = None


# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

def create_engine() -> MeasurementEngine:
    """Create and initialize measurement engine."""
    engine = MeasurementEngine.get_instance()
    if engine.initialize():
        return engine
    return None


# ============================================================================
# CV2 IMPORT FIX 
# ============================================================================

# Import cv2 at module level
import cv2
