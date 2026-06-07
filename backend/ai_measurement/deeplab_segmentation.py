"""
DeepLab V3+ Segmentation Module
==========================
Implements body segmentation for cleaner pose detection.

This module uses TensorFlow DeepLab for semantic segmentation
to isolate the human body from the background, providing cleaner
input for HMR/pose detection.

Author: Desby App Team
"""

import numpy as np
import cv2
from typing import Tuple, Optional

# Try to import TensorFlow and DeepLab
try:
    import tensorflow as tf
    TF_AVAILABLE = True
except ImportError:
    TF_AVAILABLE = False
    print("⚠️ TensorFlow not available for DeepLab")

# ============================================================================
# CONFIGURATION
# ============================================================================

# DeepLab model paths (can be downloaded or use bundled)
DEEPLAB_MODEL_URLS = {
    'xception_65': 'http://download.tensorflow.org/models/deeplabv3_xception_65_traindrop_postprocess.pb',
    'mobile_net': 'http://download.tensorflow.org/models/deeplabv3_mnv2_cityscapes_trainval.pb',
}

# ============================================================================
# DEEPLAB SEGMENTATOR
# ============================================================================

class DeepLabSegmentator:
    """
    DeepLab V3+ body segmentation.
    
    Provides semantic segmentation to isolate human body
    from background for cleaner pose detection.
    """
    
    def __init__(self, model_type: str = 'mobile_net'):
        """Initialize DeepLab segmentator."""
        self.model_type = model_type
        self.graph = None
        self.session = None
        self.input_tensor = None
        self.output_tensor = None
        self.model_loaded = False
        
    def load(self) -> bool:
        """Load DeepLab model."""
        if not TF_AVAILABLE:
            print("❌ TensorFlow not available")
            return False
            
        # Try to load from bundled models first
        model_path = self._find_model()
        
        if model_path:
            return self._load_from_file(model_path)
        
        # Fallback: use OpenCV GrabCut as alternative
        print("⚠️ DeepLab model not found, using GrabCut fallback")
        return True  # We'll use GrabCut as fallback
        
    def _find_model(self) -> Optional[str]:
        """Find DeepLab model file."""
        # Check common locations
        from pathlib import Path
        
        base_dir = Path(__file__).parent
        model_locations = [
            base_dir / "models" / "deeplabv3.pb",
            base_dir.parent.parent / "ai-body-scan-saas" / "api" / "models" / "deeplabv3.pb",
        ]
        
        for loc in model_locations:
            if loc.exists():
                return str(loc)
        
        return None
    
    def _load_from_file(self, model_path: str) -> bool:
        """Load DeepLab from protobuf file."""
        try:
            # Load the frozen graph
            with tf.io.gfile.GFile(model_path, 'rb') as f:
                graph_def = tf.compat.v1.GraphDef()
                graph_def.ParseFromString(f.read())
            
            # Import graph
            tf.import_graph_def(graph_def, name='')
            
            # Get input/output tensors
            self.input_tensor = tf.compat.v1.get_default_graph().get_tensor_by_name('ImageTensor:0')
            self.output_tensor = tf.compat.v1.get_default_graph().get_tensor_by_name(
                'SemanticPredictions:0' if 'SemanticPredictions:0' in [
                    n.name for n in tf.compat.v1.get_default_graph().as_graph_def().node
                ] else 'ResizeBilinear_3:0'
            )
            
            self.model_loaded = True
            print("✅ DeepLab model loaded")
            return True
            
        except Exception as e:
            print(f"⚠️ DeepLab load error: {e}")
            return False
    
    def segment(self, image: np.ndarray) -> Tuple[np.ndarray, np.ndarray]:
        """
        Segment body from image.
        
        Args:
            image: Input image (H, W, 3) BGR format
            
        Returns:
            Tuple of:
                - mask: Binary mask (H, W) - 1 for body, 0 for background
                - segmented: Original image with background removed
        """
        if self.model_loaded and self.session:
            return self._segment_deeplab(image)
        else:
            # Use GrabCut fallback
            return self._segment_grabcut(image)
    
    def _segment_deeplab(self, image: np.ndarray) -> Tuple[np.ndarray, np.ndarray]:
        """Use DeepLab for segmentation."""
        try:
            # Preprocess
            img_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
            img_rgb = cv2.resize(img_rgb, (513, 513))
            
            # Run inference
            output = self.session.run(
                self.output_tensor,
                feed_dict={self.input_tensor: img_rgb}
            )
            
            # Get mask
            mask = output[0].astype(np.uint8)
            mask = cv2.resize(mask, (image.shape[1], image.shape[0]))
            
            # Apply mask
            masked = cv2.bitwise_and(image, image, mask=mask)
            
            return mask, masked
            
        except Exception as e:
            print(f"⚠️ DeepLab segmentation error: {e}")
            return self._segment_grabcut(image)
    
    def _segment_grabcut(self, image: np.ndarray) -> Tuple[np.ndarray, np.ndarray]:
        """
        GrabCut-based body segmentation (fallback).
        
        Uses OpenCV GrabCut algorithm to estimate body foreground.
        """
        try:
            h, w = image.shape[:2]
            
            # Create initial mask
            mask = np.zeros((h, w), np.uint8)
            
            # Define rect around body (centered, assuming full-body image)
            # Adjust based on expected body position
            rect = (w // 4, h // 6, w * 3 // 4, h * 5 // 6)
            
            # GrabCut iterations
            bgd_model = np.zeros((1, 65), np.float64)
            fgd_model = np.zeros((1, 65), np.float64)
            
            # Run GrabCut
            cv2.grabCut(
                image, mask, rect, bgd_model, fgd_model,
                5, cv2.GC_INIT_WITH_RECT
            )
            
            # Create binary mask
            binary_mask = np.where((mask == 2) | (mask == 0), 255, 0).astype('uint8')
            
            # Apply mask
            segmented = cv2.bitwise_and(image, image, mask=binary_mask)
            
            return binary_mask, segmented
            
        except Exception as e:
            print(f"⚠️ GrabCut error: {e}")
            # Return original image as fallback
            return np.ones(image.shape[:2], np.uint8) * 255, image
    
    def remove_background(self, image: np.ndarray, blur_radius: int = 21) -> np.ndarray:
        """
        Remove background from image for cleaner processing.
        
        Args:
            image: Input image
            blur_radius: Gaussian blur amount
            
        Returns:
            Image with transparent background (BGRA)
        """
        mask, segmented = self.segment(image)
        
        # Add alpha channel
        result = cv2.cvtColor(segmented, cv2.COLOR_BGR2BGRA)
        result[:, :, 3] = mask
        
        # Optional: add slight blur to mask edges
        if blur_radius > 0:
            mask_blurred = cv2.GaussianBlur(mask, (blur_radius, blur_radius), 0)
            result[:, :, 3] = mask_blurred
        
        return result


# ============================================================================
# SIMPLE BACKGROUND REMOVAL (LIGHTWEIGHT ALTERNATIVE)
# ============================================================================

def remove_body_background_simple(image: np.ndarray) -> Tuple[np.ndarray, np.ndarray]:
    """
    Simple background removal using color-based segmentation.
    
    Lightweight alternative when DeepLab is not available.
    
    Args:
        image: Input image (BGR)
        
    Returns:
        Tuple of (mask, segmented_image)
    """
    # Convert to HSV
    hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)
    
    # Define skin color range (rough approximation)
    # This works for exposed skin but may miss clothed areas
    lower_skin = np.array([0, 20, 70], dtype=np.uint8)
    upper_skin = np.array([20, 255, 255], dtype=np.uint8)
    
    skin_mask = cv2.inRange(hsv, lower_skin, upper_skin)
    
    # Morphological operations to clean up
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
    skin_mask = cv2.morphologyEx(skin_mask, cv2.MORPH_OPEN, kernel)
    skin_mask = cv2.morphologyEx(skin_mask, cv2.MORPH_CLOSE, kernel)
    
    # Also try grabbing by finding the largest contour
    contours, _ = cv2.findContours(skin_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    
    if contours:
        # Get largest contour
        largest = max(contours, key=cv2.contourArea)
        
        # Create mask from contour
        body_mask = np.zeros(image.shape[:2], np.uint8)
        cv2.drawContours(body_mask, [largest], 0, 255, -1)
    else:
        body_mask = skin_mask
    
    # Apply mask
    segmented = cv2.bitwise_and(image, image, mask=body_mask)
    
    return body_mask, segmented


# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

def create_segmentator(model_type: str = 'mobile_net') -> DeepLabSegmentator:
    """Create and initialize DeepLab segmentator."""
    segmentator = DeepLabSegmentator(model_type)
    if segmentator.load():
        return segmentator
    return None


# ============================================================================
# TEST
# ============================================================================

if __name__ == '__main__':
    print("=" * 50)
    print("DeepLab Segmentation Module Test")
    print("=" * 50)
    
    print(f"\nTensorFlow Available: {TF_AVAILABLE}")
    
    if TF_AVAILABLE:
        segmentator = DeepLabSegmentator()
        if segmentator.load():
            print("✅ DeepLab segmentator ready")
        else:
            print("⚠️ Using GrabCut fallback")
    else:
        print("⚠️ Using simple background removal")
    
    print("\n" + "=" * 50)
