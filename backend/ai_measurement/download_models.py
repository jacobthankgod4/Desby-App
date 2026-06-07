#!/usr/bin/env python3
"""
Model Download Script
==================
Downloads MediaPipe Pose Landmarker models for body measurement extraction.

Usage:
    python download_models.py

Models will be saved to: backend/ai_measurement/models/
"""

import os
import sys
import requests
from pathlib import Path
from tqdm import tqdm


# MediaPipe Pose Landmarker model URLs
MODELS = {
    'pose_lite': {
        'url': 'https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_lite/float16/1/pose_landmarker.task',
        'expected_size': 10_000_000,  # ~10MB
    },
    'pose_full': {
        'url': 'https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_full/float32/1/pose_landmarker.task',
        'expected_size': 25_000_000,  # ~25MB
    },
    'pose_heavy': {
        'url': 'https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_heavy/float32/1/pose_landmarker.task',
        'expected_size': 50_000_000,  # ~50MB
    },
}


def download_file(url: str, dest_path: Path, expected_size: int = None) -> bool:
    """Download a file with progress bar."""
    try:
        print(f"\n📥 Downloading: {dest_path.name}")
        print(f"   URL: {url}")
        
        # Send HTTP request
        response = requests.get(url, stream=True, timeout=60)
        response.raise_for_status()
        
        total_size = int(response.headers.get('content-length', expected_size or 0))
        
        # Download with progress
        chunk_size = 8192
        
        with open(dest_path, 'wb') as f:
            downloaded = 0
            for chunk in response.iter_content(chunk_size=chunk_size):
                if chunk:
                    f.write(chunk)
                    downloaded += len(chunk)
                    
                    if total_size > 0:
                        percent = (downloaded / total_size) * 100
                        bar = '█' * int(percent / 5) + '░' * (20 - int(percent / 5))
                        print(f"\r   [{bar}] {percent:.1f}%", end='', flush=True)
        
        print()  # New line after progress
        
        # Verify file
        if dest_path.exists():
            actual_size = dest_path.stat().st_size
            print(f"   ✅ Downloaded: {actual_size:,} bytes")
            
            if expected_size and actual_size < expected_size * 0.5:
                print(f"   ⚠️ Warning: File smaller than expected")
                return False
            return True
        else:
            print(f"   ❌ Download failed - file not found")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"   ❌ Download error: {e}")
        return False
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return False


def main():
    """Main download function."""
    # Get script directory
    script_dir = Path(__file__).parent
    models_dir = script_dir / 'models'
    
    # Create models directory
    models_dir.mkdir(exist_ok=True)
    
    print("=" * 60)
    print("AI Body Measurement - Model Downloader")
    print("=" * 60)
    print(f"\n📁 Models directory: {models_dir}")
    
    # Check what we already have
    existing = list(models_dir.glob('*.task'))
    if existing:
        print(f"\n📦 Already downloaded:")
        for f in existing:
            print(f"   - {f.name} ({f.stat().st_size:,} bytes)")
    
    # Download each model
    print(f"\n📥 Starting download...")
    
    success_count = 0
    for model_name, model_info in MODELS.items():
        model_path = models_dir / f"{model_name}.task"
        
        # Skip if already exists and valid
        if model_path.exists() and model_path.stat().st_size > 1000000:
            print(f"\n⏭️  Skipping {model_name} (already exists)")
            success_count += 1
            continue
        
        if download_file(model_info['url'], model_path, model_info['expected_size']):
            success_count += 1
        else:
            # Clean up failed download
            if model_path.exists():
                model_path.unlink()
    
    # Summary
    print("\n" + "=" * 60)
    if success_count > 0:
        print(f"✅ Downloaded {success_count}/{len(MODELS)} models successfully")
        
        # List final models
        print("\n📦 Available models:")
        for f in models_dir.glob('*.task'):
            size_mb = f.stat().st_size / 1_000_000
            print(f"   - {f.name} ({size_mb:.1f} MB)")
    else:
        print("❌ No models downloaded")
        print("\n📋 Fallback: Using proportional calculations")
        print("   The service will work with anthropometric ratios")
    
    print("=" * 60)
    
    return success_count > 0


if __name__ == '__main__':
    main()
