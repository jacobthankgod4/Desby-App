import 'package:flutter/material.dart';
import '../../domain/entities/service_tier.dart';
import '../providers/tailor_finder_provider.dart';
import '../../../../theme/colors.dart';

/// Tailor card widget - modern, beautifully designed
/// Amber highlight when selected with premium styling
class TailorCard extends StatelessWidget {
  final TailorMarker tailor;
  final bool isSelected;
  final VoidCallback onTap;
  final int? distanceMinutes;

  const TailorCard({
    super.key,
    required this.tailor,
    required this.isSelected,
    required this.onTap,
    this.distanceMinutes,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        // Premium card styling with shadow and border
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.amber : Colors.transparent,
            width: 2,
          ),
boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.12 : 0.06),
              blurRadius: isSelected ? 16 : 12,
              offset: Offset(0, isSelected ? 6 : 4),
              spreadRadius: isSelected ? 1 : 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image container - larger, with gradient overlay
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image
                    Container(
                      color: AppColors.surfaceDark,
                      child: tailor.profileImage != null
                          ? Image.network(
                              tailor.profileImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: AppColors.surfaceDark,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.amber,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) => _buildPlaceholder(),
                            )
                          : _buildPlaceholder(),
                    ),
                    // Gradient overlay for text readability
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.5),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Premium badge - only when selected
                    if (isSelected)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.amber,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 12,
                                color: AppColors.darkNavy,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'SELECTED',
                                style: TextStyle(
                                  color: AppColors.darkNavy,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
// Text content - modern typography with proper spacing
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Name with premium typography
                      Text(
                        tailor.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
// Price + Distance row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Price - wrapped in Flexible
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '₦${_formatPrice(tailor.startingPrice)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected 
                                        ? AppColors.darkNavy 
                                        : AppColors.amber,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // AI Scan badge for premium tailors
                                if (tailor.aiScanEnabled == true)
                                  _buildAiScanBadge(),
                              ],
                            ),
                          ),
                          // Distance/Time badge
                          if (distanceMinutes != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.amber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.near_me_rounded, 
                                    size: 9, 
                                    color: AppColors.amber,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${distanceMinutes}min',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.amber,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      // AI Scan badge - only for premium tailors (BUSINESS tier)
                      if (tailor.aiScanEnabled)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.smartphone,
                                  size: 12,
                                  color: AppColors.amber,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'AI Scan ✓',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.amber,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surfaceDark,
      child: Center(
        child: Icon(
          Icons.content_cut,
          size: 40,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  /// AI Scan badge for premium tailors (Business tier)
  /// Shows on finder cards to indicate AI measurement is available
  Widget _buildAiScanBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.smartphone,
            size: 10,
            color: AppColors.amber,
          ),
          const SizedBox(width: 4),
          Text(
            'AI Scan',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.amber,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // Format price with proper separators
  String _formatPrice(double price) {
    if (price >= 1000) {
      final formatted = price.toStringAsFixed(0);
      final result = StringBuffer();
      for (int i = 0; i < formatted.length; i++) {
        if (i > 0 && (formatted.length - i) % 3 == 0) {
          result.write(',');
        }
        result.write(formatted[i]);
      }
      return result.toString();
    }
    return price.toStringAsFixed(0);
  }
}
