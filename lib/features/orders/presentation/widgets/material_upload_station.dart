import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../theme/colors.dart';

class MaterialUploadStation extends StatefulWidget {
  final Function(XFile?) onImagePicked;
  final bool isCompleted;

  /// Renders as a small square tile rather than the full-width drop zone, so it
  /// can sit inside a grid of reference cards.
  final bool compact;

  const MaterialUploadStation({
    super.key,
    required this.onImagePicked,
    this.isCompleted = false,
    this.compact = false,
  });

  @override
  State<MaterialUploadStation> createState() => _MaterialUploadStationState();
}

class _MaterialUploadStationState extends State<MaterialUploadStation> {
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
    final colors = context.colors;
    if (widget.compact) {
      return Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _pickImage(ImageSource.gallery),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_outlined,
                    size: 22, color: colors.textMuted),
                const SizedBox(height: 6),
                Text('Add',
                    style: TextStyle(
                        fontSize: 11, color: colors.textMuted)),
              ],
            ),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: widget.isCompleted
              ? AppColors.amber.withValues(alpha: 0.4)
              : colors.borderSubtle,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'STEP 2: MATERIAL ASSETS',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              if (widget.isCompleted)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.amber,
                  size: 16,
                ),
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

  Widget _buildUploadOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.amber, size: 28),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    final colors = context.colors;
    return Column(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: colors.overlayLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // WEB & MOBILE COMPATIBLE IMAGE LOADER
                Positioned.fill(
                  child: Image.memory(_webImageBytes!, fit: BoxFit.cover),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        colors.scaffoldBg,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.successGreen,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Photo added',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
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
            });
            widget.onImagePicked(null);
          },
          child: const Text(
            'Replace photo',
            style: TextStyle(
              color: AppColors.amber,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }
}
