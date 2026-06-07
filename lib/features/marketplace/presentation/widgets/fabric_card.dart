import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';

/// Fabric Model (Stub - should be generated from domain layer)
class Fabric {
  final String id;
  final String name;
  final double pricePerYard;
  final int stockQuantity;
  final List<String> imageUrls;
  final String? sellerId;
  final String category;
  final String? description;
  final String? materialType;
  final double? rating;
  final int reviewCount;

  const Fabric({
    required this.id,
    required this.name,
    required this.pricePerYard,
    required this.stockQuantity,
    this.imageUrls = const [],
    this.sellerId,
    this.category = 'General',
    this.description,
    this.materialType,
    this.rating,
    this.reviewCount = 0,
  });

  factory Fabric.fromJson(Map<String, dynamic> json) {
    return Fabric(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      pricePerYard: (json['pricePerYard'] as num?)?.toDouble() ?? 0.0,
      stockQuantity: json['stockQuantity'] as int? ?? 0,
      imageUrls: (json['imageUrls'] as List<dynamic>?)?.cast<String>() ?? [],
      sellerId: json['sellerId'] as String?,
      category: json['category'] as String? ?? 'General',
      description: json['description'] as String?,
      materialType: json['materialType'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: json['reviewCount'] as int? ?? 0,
    );
  }
}

/// Fabric Card Widget
/// 
/// Displays a fabric item with image, name, price, and stock information.
class FabricCard extends StatelessWidget {
  final Fabric fabric;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;

  const FabricCard({
    super.key,
    required this.fabric,
    this.onTap,
    this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  // Fabric Image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: fabric.imageUrls.isNotEmpty
                        ? Image.network(
                            fabric.imageUrls.first,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
                  ),
                  // Favorite Button
                  if (onFavorite != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: onFavorite,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.darkNavy.withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.favorite_border, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  // Stock Badge
                  if (fabric.stockQuantity < 10)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'LOW STOCK',
                          style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fabric.name.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₦${fabric.pricePerYard.toStringAsFixed(0)}/yd',
                        style: const TextStyle(color: AppColors.amber, fontSize: 14, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        '${fabric.stockQuantity} yds',
                        style: TextStyle(
                          color: fabric.stockQuantity < 5 ? Colors.redAccent : Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white.withValues(alpha: 0.05),
      child: const Icon(Icons.texture_rounded, color: Colors.white24, size: 48),
    );
  }
}
