"""
Custom Body Points Integration Module
===================================
Parses customBodyPoints.txt files to extract body measurements
from landmark coordinates.

This module provides integration with the legacy Human Body 
Measurement control points from the original GitHub project.

Author: Desby App Team
"""

import os
from pathlib import Path
from typing import Dict, List, Tuple, Optional

import numpy as np


# ============================================================================
# CONFIGURATION
# ============================================================================

BASE_DIR = Path(__file__).parent
DATA_DIR = BASE_DIR / "data"

# Default paths
DEFAULT_MALE_POINTS = DATA_DIR / "customBodyPoints_male.txt"
DEFAULT_FEMALE_POINTS = DATA_DIR / "customBodyPoints_female.txt"


# ============================================================================
# CUSTOM BODY POINTS CLASS
# ============================================================================

class CustomBodyPoints:
    """
    Custom Body Points parser and measurement extractor.
    
    Loads control points from customBodyPoints files and calculates
    body measurements from 2D/3D landmark coordinates.
    """
    
    def __init__(self, gender: str = 'male'):
        """Initialize with gender-specific control points."""
        self.gender = gender.lower()
        self.control_points = {}
        self.loaded = False
        
        # Select appropriate file
        if self.gender == 'female':
            self.points_file = DEFAULT_FEMALE_POINTS
        else:
            self.points_file = DEFAULT_MALE_POINTS
        
        self.load()
    
    def load(self) -> bool:
        """Load control points from file."""
        if not self.points_file.exists():
            print(f"⚠️ CustomBodyPoints file not found: {self.points_file}")
            return False
        
        try:
            with open(self.points_file, 'r') as f:
                lines = f.readlines()
            
            # Parse control points (format: name x_ratio y_ratio z_ratio)
            for line in lines:
                line = line.strip()
                if not line or line.startswith('#'):
                    continue
                
                parts = line.split()
                if len(parts) >= 3:
                    name = parts[0]
                    x_ratio = float(parts[1])
                    y_ratio = float(parts[2])
                    z_ratio = float(parts[3]) if len(parts) > 3 else 0.0
                    
                    self.control_points[name] = {
                        'x': x_ratio,
                        'y': y_ratio,
                        'z': z_ratio
                    }
            
            self.loaded = True
            print(f"✅ Loaded {len(self.control_points)} control points for {self.gender}")
            return True
            
        except Exception as e:
            print(f"❌ Error loading CustomBodyPoints: {e}")
            return False
    
def get_point(self, name: str) -> Optional[Dict[str, float]]:
    """Get a control point by name."""
    return self.control_points.get(name)
    
    def get_all_points(self) -> Dict[str, Dict[str, float]]:
        """Get all control points."""
        return self.control_points
    
    def calculate_measurement(
        self, 
        point1: str, 
        point2: str, 
        scale_factor: float
    ) -> float:
        """
        Calculate distance between two control points.
        
        Args:
            point1: First control point name
            point2: Second control point name
            scale_factor: Pixels to cm conversion factor
            
        Returns:
            Distance in centimeters
        """
        p1 = self.get_point(point1)
        p2 = self.get_point(point2)
        
        if not p1 or not p2:
            return 0.0
        
        # Calculate Euclidean distance
        distance = np.sqrt(
            (p1['x'] - p2['x'])**2 +
            (p1['y'] - p2['y'])**2 +
            (p1['z'] - p2['z'])**2
        )
        
        return distance * scale_factor
    
    def calculate_circumference(
        self,
        point_names: List[str],
        scale_factor: float,
        multiplier: float = 1.0
    ) -> float:
        """
        Calculate circumference from multiple control points.
        
        Args:
            point_names: List of control points forming the circumference
            scale_factor: Pixels to cm conversion factor
            multiplier: Additional multiplier (e.g., 2*pi for full circle)
            
        Returns:
            Circumference in centimeters
        """
        if len(point_names) < 2:
            return 0.0
        
        # Calculate perimeter
        perimeter = 0.0
        for i in range(len(point_names)):
            p1 = self.get_point(point_names[i])
            p2 = self.get_point(point_names[(i + 1) % len(point_names)])
            
            if p1 and p2:
                perimeter += np.sqrt(
                    (p1['x'] - p2['x'])**2 +
                    (p1['y'] - p2['y'])**2 +
                    (p1['z'] - p2['z'])**2
                )
        
        return perimeter * scale_factor * multiplier


# ============================================================================
# MEASUREMENT EXTRACTION
# ============================================================================

def create_custom_body_points(gender: str = 'male') -> Optional[CustomBodyPoints]:
    """Create and initialize CustomBodyPoints."""
    points = CustomBodyPoints(gender)
    if points.loaded:
        return points
    return None


def extract_measurements_from_points(
    points: CustomBodyPoints,
    user_height_cm: float,
    image_height_px: int
) -> Dict[str, float]:
    """
    Extract body measurements from control points.
    
    Args:
        points: CustomBodyPoints instance
        user_height_cm: User's height in cm
        image_height_px: Image height in pixels
        
    Returns:
        Dict of measurement name -> value in cm
    """
    measurements = {}
    
    if not points.loaded:
        return measurements
    
    # Calculate scale factor
    scale_factor = image_height_px / user_height_cm
    
    # Define measurement mappings based on control points
    # These are examples - actual mappings depend on the control points file
    measurement_mappings = {
        'Shoulder': ('left_shoulder', 'right_shoulder', 1.0),
        'Chest': ('left_chest', 'right_chest', 2.2),  # Full circumference
        'Waist': ('left_waist', 'right_waist', 2.0),
        'Hip': ('left_hip', 'right_hip', 2.1),
    }
    
    for name, (p1, p2, mult) in measurement_mappings.items():
        try:
            dist = points.calculate_measurement(p1, p2, scale_factor)
            if mult != 1.0:
                dist *= mult
            measurements[name] = round(dist, 1)
        except Exception:
            pass
    
    # Add proportional measurements
    ratios = {
        'Neck Round': 0.224,
        'Half Length': 0.353,
        'Full Top Length': 0.441,
    }
    
    for name, ratio in ratios.items():
        measurements[name] = round(ratio * user_height_cm, 1)
    
    return measurements


# ============================================================================
# TEST / DEMO
# ============================================================================

if __name__ == '__main__':
    print("=" * 50)
    print("CustomBodyPoints Integration Test")
    print("=" * 50)
    
    # Try loading male control points
    male_points = CustomBodyPoints('male')
    if male_points.loaded:
        print(f"\n✅ Male control points loaded")
        print(f"   Total points: {len(male_points.control_points)}")
        
        # Show some example points
        example_points = ['nose', 'left_shoulder', 'right_shoulder', 'left_hip', 'right_hip']
        for name in example_points:
            pt = male_points.get_point(name)
            if pt:
                print(f"   {name}: x={pt['x']:.3f}, y={pt['y']:.3f}")
    else:
        print(f"\n⚠️ Male control points file not found or invalid")
        print(f"   Expected: {DEFAULT_MALE_POINTS}")
    
    # Try loading female control points
    female_points = CustomBodyPoints('female')
    if female_points.loaded:
        print(f"\n✅ Female control points loaded")
    else:
        print(f"\n⚠️ Female control points not available")
    
    print("\n" + "=" * 50)
