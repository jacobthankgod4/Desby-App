import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';

/// A high-precision widget that displays anatomical guidance images.
/// Features a 'Smart Extension Fallback' to ensure assets load correctly
/// regardless of whether they have .jpg, .jpeg, or .jpg.jpeg extensions.
class StaticGuidedCrop extends StatelessWidget {
  final String imagePath;
  final double borderRadius;

  const StaticGuidedCrop({
    super.key,
    required this.imagePath,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        color: colors.scaffoldBg,
        child: Stack(
          children: [
            // 1. SMART IMAGE LOADER
            // Tries multiple extensions to prevent 404 errors during transitions
            Positioned.fill(
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback 1: If .jpg.jpeg failed, try .jpg
                  final String fallbackPath = imagePath.endsWith('.jpg.jpeg')
                      ? imagePath.replaceAll('.jpg.jpeg', '.jpg')
                      : imagePath;

                  return Image.asset(
                    fallbackPath,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => _buildMissingState(context),
                  );
                },
              ),
            ),

            // 2. HOLOGRAPHIC OVERLAY
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: colors.borderSubtle),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.02),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.2),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissingState(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.borderSubtle,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
            ),
            child: const Icon(
              Icons.add_photo_alternate_outlined,
              color: Colors.amber,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'ASSET REQUIRED',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            imagePath.split('/').last,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 7,
              fontFamily: 'Monospace',
            ),
          ),
        ],
      ),
    );
  }
}
