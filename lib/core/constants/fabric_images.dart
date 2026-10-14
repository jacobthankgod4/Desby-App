import 'package:flutter/material.dart';

/// Maps fabric category names to local asset images
/// Used as fallback when no network image is available
class FabricImages {
  FabricImages._();

  static const Map<String, String> _assetMap = {
    'ankara': 'assets/images/fabrics/ankara.jpg',
    'cotton': 'assets/images/fabrics/cotton.jpg',
    'chiffon': 'assets/images/fabrics/chiffon.jpg',
    'velvet': 'assets/images/fabrics/velvet.jpg',
    'lace': 'assets/images/fabrics/lace.jpg',
    'denim': 'assets/images/fabrics/denim.jpg',
    'george': 'assets/images/fabrics/george.webp',
    'aso oke': 'assets/images/fabrics/aso_oke.jpg',
    'silk': 'assets/images/fabrics/silk.jpg',
    'linen': 'assets/images/fabrics/linen.jpg',
    'wool': 'assets/images/fabrics/wool.jpg',
    'crepe': 'assets/images/fabrics/silk.jpg',
    'satin': 'assets/images/fabrics/silk.jpg',
    'damask': 'assets/images/fabrics/george.webp',
  };

  static const Map<String, IconData> _iconMap = {
    'ankara': Icons.palette_rounded,
    'cotton': Icons.grass_rounded,
    'chiffon': Icons.air_rounded,
    'velvet': Icons.weekend_rounded,
    'lace': Icons.auto_awesome_rounded,
    'denim': Icons.workspaces_rounded,
    'george': Icons.diamond_rounded,
    'aso oke': Icons.star_rounded,
    'silk': Icons.dry_cleaning_rounded,
    'linen': Icons.texture_rounded,
    'wool': Icons.cloud_rounded,
    'crepe': Icons.water_drop_rounded,
    'satin': Icons.dry_cleaning_rounded,
    'damask': Icons.diamond_rounded,
  };

  /// Get asset path for a fabric category (case-insensitive)
  static String? getAsset(String category) {
    return _assetMap[category.toLowerCase()];
  }

  /// Get fallback icon for a fabric category
  static IconData getIcon(String category) {
    return _iconMap[category.toLowerCase()] ?? Icons.texture_rounded;
  }

  /// Get asset path or null if not found
  static String? tryGetAsset(String? category) {
    if (category == null) return null;
    return _assetMap[category.toLowerCase()];
  }
}
