import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';

class CategorySidebar extends StatelessWidget {
  const CategorySidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey[200]!)),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Text(
              'CATEGORIES',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.grey,
                letterSpacing: 1.5,
              ),
            ),
          ),
          _CategoryItem(icon: Icons.auto_awesome_rounded, label: 'New Arrivals', count: '42', isSelected: true),
          _CategoryItem(icon: Icons.star_outline_rounded, label: 'Top Rated', count: '128'),
          _CategoryItem(icon: Icons.texture_rounded, label: 'Silk Fabrics', count: '56'),
          _CategoryItem(icon: Icons.waves_rounded, label: 'Cotton Blends', count: '94'),
          _CategoryItem(icon: Icons.grid_4x4_rounded, label: 'Linen & Lace', count: '31'),
          _CategoryItem(icon: Icons.category_outlined, label: 'Accessories', count: '205'),
          
          const SizedBox(height: 40),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Text(
              'FILTERS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.grey,
                letterSpacing: 1.5,
              ),
            ),
          ),
          _CategoryItem(icon: Icons.color_lens_outlined, label: 'Color Palette'),
          _CategoryItem(icon: Icons.payments_outlined, label: 'Price Range'),
          _CategoryItem(icon: Icons.verified_user_outlined, label: 'Verified Sellers'),
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
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(
        icon, 
        size: 18, 
        color: isSelected ? AppColors.amber : Colors.grey[600],
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? AppColors.darkNavy : Colors.grey[800],
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (count != null)
            Text(
              count!,
              style: TextStyle(fontSize: 10, color: Colors.grey[400]),
            ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, size: 14, color: Colors.grey),
        ],
      ),
      onTap: () {},
    );
  }
}
