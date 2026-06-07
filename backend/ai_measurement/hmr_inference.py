"""
HMR (Human Mesh Regression) Inference Module
=====================================
Implements 3D body mesh regression using pre-trained HMR model.

This module loads the pre-trained HMR model and performs 3D body mesh
regression from 2D images, providing 3D vertex coordinates for accurate
body measurements.

Author: Desby App Team
"""

import os
import sys
import numpy as np
import pickle
from pathlib import Path
from typing import Dict, Optional, Tuple, List

# Try TensorFlow imports
try:
    # Try TF 2.x first
    import tensorflow as tf
    if int(tf.__version__.split('.')[0]) >= 2:
        # Use TF 2.x with compatibility for TF 1.x models
        import tensorflow.compat.v1 as tf1
        tf1.disable_v2_behavior()
        TF_VERSION = 2
    else:
        tf1 = tf
        TF_VERSION = 1
except ImportError:
    TF_VERSION = 0
    print("⚠️ TensorFlow not available")

# ============================================================================
# CONFIGURATION
# ============================================================================

BASE_DIR = Path(__file__).parent
MODELS_DIR = BASE_DIR.parent.parent / "ai-body-scan-saas" / "api" / "models"

# Model paths
HMR_CHECKPOINT = MODELS_DIR / "model.ckpt-667589"
SMPL_MODEL_PATH = MODELS_DIR / "neutral_smpl_with_cocoplus_reg.pkl"

# Verify models exist
HMR_AVAILABLE = HMR_CHECKPOINT.exists() and list(HMR_CHECKPOINT.parent.glob("model.ckpt*"))
SMPL_AVAILABLE = SMPL_MODEL_PATH.exists()

print(f"📦 HMR Model: {'✅ Available' if HMR_AVAILABLE else '❌ Not found'} at {HMR_CHECKPOINT}")
print(f"📦 SMPL Model: {'✅ Available' if SMPL_AVAILABLE else '❌ Not found'} at {SMPL_MODEL_PATH}")

# ============================================================================
# HMR MODEL CLASS
# ============================================================================

class HMRModel:
    """
    HMR (Human Mesh Regression) Model Wrapper.
    
    Loads pre-trained HMR model and performs 3D body mesh regression.
    """
    
    def __init__(self, model_path: str = None):
        """Initialize HMR model."""
        self.model_path = str(model_path or HMR_CHECKPOINT)
        self.smpl_path = str(SMPL_MODEL_PATH)
        self.session = None
        self.smpl_model = None
        self.input_joints = None
        self.verts = None
        self.camera = None
        self.session_started = False
        
    def load(self) -> bool:
        """Load HMR model and SMPL parameters."""
        if not HMR_AVAILABLE:
            print(f"❌ HMR checkpoint not found: {self.model_path}")
            return False
            
        try:
            # Load SMPL model (contains regression matrix for vertices)
            if SMPL_AVAILABLE:
                with open(self.smpl_path, 'rb') as f:
                    self.smpl_model = pickle.load(f, encoding='latin1')
                print("✅ SMPL model loaded")
            else:
                print("⚠️ SMPL model not found, using approximation")
                
            # Set up TensorFlow session
            if TF_VERSION >= 1:
                self._setup_session()
                
            return True
            
        except Exception as e:
            print(f"❌ Failed to load HMR model: {e}")
            return False
    
    def _setup_session(self):
        """Set up TensorFlow session for HMR inference."""
        try:
            # Create TF1 session
            self.session = tf1.Session()
            
            # Load the checkpoint
            saver = tf1.train.Saver()
            checkpoint_path = str(self.model_path)
            
            # Find the actual checkpoint prefix
            ckpt_files = list(Path(checkpoint_path).parent.glob("model.ckpt-*"))
            if ckpt_files:
                # Get the base path (without .index extension)
                base_path = str(ckpt_files[0]).rsplit('.', 1)[0]
                saver.restore(self.session, base_path)
                print(f"✅ HMR checkpoint loaded: {base_path}")
            else:
                print("⚠️ No checkpoint files found")
                
            self.session_started = True
            
        except Exception as e:
            print(f"⚠️ TF session setup failed: {e}")
            self.session_started = False
    
    def predict(self, image: np.ndarray) -> Optional[Dict]:
        """
        Run HMR inference on image.
        
        Args:
            image: Input image (H, W, 3) in BGR format
            
        Returns:
            Dict containing:
                - vertices: 3D mesh vertices (N, 3)
                - joints: 2D/3D keypoints (19, 3)
                - camera: Camera parameters
                - smpl_vertices: SMPL-aligned vertices
        """
        if not self.session_started:
            return None
            
        try:
            # Preprocess image
            image_rgb = self._preprocess_image(image)
            
            # Run inference
            joints, verts, camera = self.session.run(
                ['joints:0', 'vertices:0', 'camera:0'],
                feed_dict={'image:0': image_rgb}
            )
            
            return {
                'joints': joints,
                'verts': verts,
                'camera': camera,
                'smpl_model': self.smpl_model
            }
            
        except Exception as e:
            print(f"❌ HMR inference error: {e}")
            return None
    
    def _preprocess_image(self, image: np.ndarray) -> np.ndarray:
        """Preprocess image for HMR input."""
        # Resize to 224x224
        import cv2
        resized = cv2.resize(image, (224, 224))
        
        # Normalize to [-1, 1]
        normalized = resized.astype(np.float32) / 127.5 - 1.0
        
        return normalized
    
    def close(self):
        """Clean up resources."""
        if self.session:
            self.session.close()
            self.session = None


# ============================================================================
# SMPL MESH HANDLER
# ============================================================================

class SMPLMesh:
    """
    SMPL (Skinned Multi-Person Linear) Mesh Handler.
    
    Provides utilities for extracting measurements from SMPL 3D mesh.
    """
    
    def __init__(self, smpl_model_path: str = None):
        """Initialize SMPL mesh handler."""
        self.smpl_path = str(smpl_model_path or SMPL_MODEL_PATH)
        self.smpl_model = None
        self.load()
    
    def load(self) -> bool:
        """Load SMPL model."""
        if not SMPL_AVAILABLE:
            return False
            
        try:
            with open(self.smpl_path, 'rb') as f:
                self.smpl_model = pickle.load(f, encoding='latin1')
            return True
        except Exception as e:
            print(f"❌ SMPL load error: {e}")
            return False
    
    def extract_measurements(self, vertices: np.ndarray) -> Dict[str, float]:
        """
        Extract body measurements from SMPL vertices.
        
        Args:
            vertices: (6890, 3) SMPL vertex array
            
        Returns:
            Dict of measurement name -> value in cm
        """
        if vertices is None or len(vertices) < 100:
            return {}
        
        # Define body segment indices (SMPL topology)
        # These are approximate indices - actual indices depend on SMPL model version
        
        measurements = {}
        
        try:
            # Body height (top of head to ground)
            if len(vertices) > 300:
                body_height = np.max(vertices[:, 1]) - np.min(vertices[:, 1])
                measurements['Body Height'] = body_height * 100  # Convert to cm (assuming normalized)
            
            # Key measurements from vertices
            
            # 1. Shoulder width (between shoulder vertices)
            # Approximate: vertices around y ~= shoulder height
            shoulder_verts = vertices[(vertices[:, 1] > 0.3) & (vertices[:, 1] < 0.5)]
            if len(shoulder_verts) > 10:
                shoulder_width = np.max(shoulder_verts[:, 0]) - np.min(shoulder_verts[:, 0])
                measurements['Shoulder'] = shoulder_width * 100
            
            # 2. Chest circumference (at chest height)
            chest_verts = vertices[(vertices[:, 1] > 0.1) & (vertices[:, 1] < 0.3)]
            if len(chest_verts) > 10:
                chest_width = np.max(chest_verts[:, 0]) - np.min(chest_verts[:, 0])
                chest_depth = np.max(chest_verts[:, 2]) - np.min(chest_verts[:, 2])
                # Approximate circumference
                measurements['Chest Round'] = 2 * np.pi * ((chest_width + chest_depth) / 2) * 100
            
            # 3. Waist (at hip height)
            waist_verts = vertices[(vertices[:, 1] > -0.1) & (vertices[:, 1] < 0.1)]
            if len(waist_verts) > 10:
                waist_width = np.max(waist_verts[:, 0]) - np.min(waist_verts[:, 0])
                waist_depth = np.max(waist_verts[:, 2]) - np.min(waist_verts[:, 2])
                measurements['Waist Round'] = 2 * np.pi * ((waist_width + waist_depth) / 2) * 100
            
            # 4. Hip circumference
            hip_verts = vertices[(vertices[:, 1] > -0.3) & (vertices[:, 1] < -0.1)]
            if len(hip_verts) > 10:
                hip_width = np.max(hip_verts[:, 0]) - np.min(hip_verts[:, 0])
                hip_depth = np.max(hip_verts[:, 2]) - np.min(hip_verts[:, 2])
                measurements['Hip Round'] = 2 * np.pi * ((hip_width + hip_depth) / 2) * 100
            
            # 5. Arm length (shoulder to wrist)
            # Approximate based on shoulder and wrist positions
            arm_measurements = self._calculate_arm_length(vertices)
            measurements.update(arm_measurements)
            
            # 6. Leg length / Inseam
            leg_measurements = self._calculate_leg_length(vertices)
            measurements.update(leg_measurements)
            
        except Exception as e:
            print(f"⚠️ Measurement extraction error: {e}")
        
        return measurements
    
    def _calculate_arm_length(self, vertices: np.ndarray) -> Dict[str, float]:
        """Calculate arm lengths from vertices."""
        measurements = {}
        
        # Find arm vertices (x > shoulder width)
        right_arm = vertices[vertices[:, 0] > 0.15]  # Right side
        left_arm = vertices[vertices[:, 0] < -0.15]   # Left side
        
        for side, arm_verts in [('Right', right_arm), ('Left', left_arm)]:
            if len(arm_verts) > 10:
                # Length from shoulder height to wrist height
                arm_length = np.max(arm_verts[:, 1]) - np.min(arm_verts[:, 1])
                measurements[f'{side} Arm Length'] = arm_length * 100
        
        # Average
        if 'Right Arm Length' in measurements and 'Left Arm Length' in measurements:
            measurements['Arm Length'] = (
                measurements['Right Arm Length'] + measurements['Left Arm Length']
) / 2
        
        return measurements
    
    def _calculate_leg_length(self, vertices: np.ndarray) -> Dict[str, float]:
        """Calculate leg lengths from vertices."""
        measurements = {}
        
        # Find leg vertices
        right_leg = vertices[(vertices[:, 0] > 0.05) & (vertices[:, 1] < -0.3)]
        left_leg = vertices[(vertices[:, 0] < -0.05) & (vertices[:, 1] < -0.3)]
        
        for side, leg_verts in [('Right', right_leg), ('Left', left_leg)]:
            if len(leg_verts) > 10:
                # Length from hip to ankle
                leg_length = np.max(leg_verts[:, 1]) - np.min(leg_verts[:, 1])
                measurements[f'{side} Leg Length'] = leg_length * 100
        
        # Inseam (inner leg)
        inner_leg = vertices[np.abs(vertices[:, 0]) < 0.05]
        if len(inner_leg) > 10:
            inseam = np.max(inner_leg[:, 1]) - np.min(inner_leg[:, 1])
            measurements['Inseam'] = inseam * 100
        
        return measurements


# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

def create_hmr_model() -> Optional[HMRModel]:
    """Create and initialize HMR model."""
    model = HMRModel()
    if model.load():
        return model
    return None


def run_hmr_inference(image: np.ndarray) -> Optional[Dict]:
    """
    Run full HMR inference on an image.
    
    Args:
        image: Input image in BGR format
        
    Returns:
        Dict with vertices, joints, measurements
    """
    model = create_hmr_model()
    if not model:
        return None
    
    try:
        # Run prediction
        result = model.predict(image)
        
        if result and result.get('verts') is not None:
            # Extract measurements from 3D vertices
            smpl = SMPLMesh()
            measurements = smpl.extract_measurements(result['verts'])
            
            result['measurements'] = measurements
            return result
        
    except Exception as e:
        print(f"❌ HMR inference failed: {e}")
    
    finally:
        model.close()
    
    return None


# ============================================================================
# TEST
# ============================================================================

if __name__ == '__main__':
    print("=" * 50)
    print("HMR Inference Module Test")
    print("=" * 50)
    
    print(f"\nTF Version: {TF_VERSION}")
    print(f"HMR Available: {HMR_AVAILABLE}")
    print(f"SMPL Available: {SMPL_AVAILABLE}")
    
    if HMR_AVAILABLE and SMPL_AVAILABLE:
        print("\n✅ Both HMR and SMPL models are available!")
        print("Ready for 3D body mesh regression.")
    elif HMR_AVAILABLE:
        print("\n⚠️ HMR available but SMPL missing - measurements will be approximate")
    else:
        print("\n❌ Models not found")
        print(f"Expected: {HMR_CHECKPOINT}")
    
    print("\n" + "=" * 50)
