import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../theme/colors.dart';

class MaterialUploadStation extends StatefulWidget {
  final Function(XFile?) onImagePicked;
  final bool isCompleted;

  const MaterialUploadStation({
    super.key, 
    required this.onImagePicked,
    this.isCompleted = false,
  });

  @override
  State<MaterialUploadStation> createState() => _MaterialUploadStationState();
}

class _MaterialUploadStationState extends State<MaterialUploadStation> {
  XFile? _selectedXFile;
  Uint8List? _webImageBytes;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        // CROSS-PLATFORM: Handle bytes for web/mobile compatibility
        final bytes = await pickedFile.readAsBytes();
        
        setState(() {
          _selectedXFile = pickedFile;
          _webImageBytes = bytes;
        });
        widget.onImagePicked(pickedFile);
      }
    } catch (e) {
      debugPrint('❌ [MEDIA] Pick failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: widget.isCompleted 
              ? AppColors.amber.withValues(alpha: 0.4) 
              : Colors.white.withValues(alpha: 0.05), 
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'STEP 2: MATERIAL ASSETS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              if (widget.isCompleted)
                const Icon(Icons.check_circle_rounded, color: AppColors.amber, size: 16),
            ],
          ),
          const SizedBox(height: 16),
          if (_webImageBytes == null)
            Row(
              children: [
                Expanded(
                  child: _buildUploadOption(
                    icon: Icons.camera_enhance_rounded,
                    label: 'TAKE PHOTO',
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildUploadOption(
                    icon: Icons.photo_library_rounded,
                    label: 'GALLERY',
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            )
          else
            _buildImagePreview(),
        ],
      ),
    );
  }

  Widget _buildUploadOption({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.amber, size: 28),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Column(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // WEB & MOBILE COMPATIBLE IMAGE LOADER
                Positioned.fill(child: Image.memory(_webImageBytes!, fit: BoxFit.cover)),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                    ),
                  ),
                ),
                const Positioned(
                  bottom: 16,
                  left: 16,
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Color(0xFF00FF7F), size: 16),
                      SizedBox(width: 8),
                      Text('ASSET LOCKED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            setState(() {
              _webImageBytes = null;
              _selectedXFile = null;
            });
            widget.onImagePicked(null);
          },
          child: const Text('REPLACE ASSET', style: TextStyle(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
      ],
    );
  }
}
