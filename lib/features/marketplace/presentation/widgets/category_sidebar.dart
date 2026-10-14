import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';

class CategorySidebar extends StatelessWidget {
  const CategorySidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(right: BorderSide(color: colors.sidebarBorder)),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Text(
              'CATEGORIES',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: colors.textMuted,
                letterSpacing: 1.5,
              ),
            ),
          ),
          _CategoryItem(
            icon: Icons.auto_awesome_rounded,
            label: 'New Arrivals',
            count: '42',
            isSelected: true,
          ),
          _CategoryItem(
            icon: Icons.star_outline_rounded,
            label: 'Top Rated',
            count: '128',
          ),
          _CategoryItem(
            icon: Icons.texture_rounded,
            label: 'Silk Fabrics',
            count: '56',
          ),
          _CategoryItem(
            icon: Icons.waves_rounded,
            label: 'Cotton Blends',
            count: '94',
          ),
          _CategoryItem(
            icon: Icons.grid_4x4_rounded,
            label: 'Linen & Lace',
            count: '31',
          ),
          _CategoryItem(
            icon: Icons.category_outlined,
            label: 'Accessories',
            count: '205',
          ),

          const SizedBox(height: 40),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Text(
              'FILTERS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: colors.textMuted,
                letterSpacing: 1.5,
              ),
            ),
          ),
          _CategoryItem(
            icon: Icons.color_lens_outlined,
            label: 'Color Palette',
          ),
          _CategoryItem(icon: Icons.payments_outlined, label: 'Price Range'),
          _CategoryItem(
            icon: Icons.verified_user_outlined,
            label: 'Verified Sellers',
          ),
        ],
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? count;
  final bool isSelected;

  const _CategoryItem({
    required this.icon,
    required this.label,
    this.count,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(
        icon,
        size: 18,
        color: isSelected ? AppColors.amber : colors.iconMuted,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? AppColors.darkNavy : colors.textPrimary,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (count != null)
            Text(
              count!,
              style: TextStyle(fontSize: 10, color: colors.textMuted),
            ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, size: 14, color: colors.iconMuted),
        ],
      ),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label filter coming soon'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
    );
  }
}
