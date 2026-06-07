import 'package:flutter/material.dart';
import '../../presentation/providers/tailor_finder_provider.dart';
import '../../../../theme/colors.dart';
import '../../../../core/widgets/status_pill.dart';

/// Tailor Shop Card Widget
/// Displays individual tailor information for map markers and list views
/// Adapted from Uber car display
class TailorShopCard extends StatelessWidget {
  final TailorMarker tailor;
  final bool isSelected;
  final VoidCallback? onTap;

  const TailorShopCard({
    super.key,
    required this.tailor,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.amber.withValues(alpha: 0.1) : AppColors.uberCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.amber : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.amber.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: Avatar + Name + Rating
            Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: tailor.profileImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            tailor.profileImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Center(
                          child: Text(
                            tailor.name.isNotEmpty ? tailor.name[0].toUpperCase() : 'T',
                            style: const TextStyle(
                              color: AppColors.amber,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                // Name and address
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tailor.name,
                        style: const TextStyle(
                          color: AppColors.uberTextPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (tailor.shopAddress != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: AppColors.uberTextMuted,
                              size: 12,
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                tailor.shopAddress!,
                                style: const TextStyle(
                                  color: AppColors.uberTextMuted,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Rating badge
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: AppColors.amber,
                            size: 14,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            tailor.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: AppColors.amber,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${tailor.reviewCount} reviews',
                      style: const TextStyle(
                        color: AppColors.uberTextMuted,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Services chips
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tailor.availableServices.map((service) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    service.displayName,
                    style: const TextStyle(
                      color: AppColors.uberTextMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            // Bottom row: Availability + Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Availability status
                StatusPill(
                  status: tailor.isAvailable ? 'Available' : 'Busy',
                  isLive: tailor.isAvailable,
                ),
                // Starting price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'From',
                      style: TextStyle(
                        color: AppColors.uberTextMuted,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      '₦${tailor.startingPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: AppColors.amber,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Tailor marker card for map display (compact version)
class TailorMarkerCard extends StatelessWidget {
  final TailorMarker tailor;
  final bool isSelected;
  final VoidCallback? onTap;

  const TailorMarkerCard({
    super.key,
    required this.tailor,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.amber : AppColors.uberCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.amber : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (isSelected ? AppColors.amber : Colors.black).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.darkNavy 
                    : AppColors.amber.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  tailor.name.isNotEmpty ? tailor.name[0].toUpperCase() : 'T',
                  style: TextStyle(
                    color: isSelected ? AppColors.amber : AppColors.amber,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Name
            Text(
              tailor.name,
              style: TextStyle(
                color: isSelected ? AppColors.darkNavy : AppColors.uberTextPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Rating
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star_rounded,
                  color: isSelected ? AppColors.darkNavy : AppColors.amber,
                  size: 12,
                ),
                const SizedBox(width: 2),
                Text(
                  tailor.rating.toStringAsFixed(1),
                  style: TextStyle(
                    color: isSelected ? AppColors.darkNavy : AppColors.uberTextPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Status indicator
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: tailor.isAvailable ? AppColors.uberLive : AppColors.uberWarning,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
