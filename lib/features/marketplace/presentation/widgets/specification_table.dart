import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';

class SpecificationTable extends StatelessWidget {
  const SpecificationTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // Re-introducing white for readability
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          const _AttributeRow(label: 'Brand', value: 'Italian Silk Masters', isFirst: true),
          const _AttributeRow(label: 'Type', value: 'Charmeuse Luxury'),
          const _AttributeRow(label: 'Material', value: '100% Pure Mulberry Silk'),
          const _AttributeRow(label: 'Weight', value: '19 momme'),
          const _AttributeRow(label: 'Width', value: '45 inches'),
          const _AttributeRow(label: 'Color', value: 'Midnight Navy'),
          const _AttributeRow(label: 'Finish', value: 'High Sheen Gloss'),
          
          InkWell(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                border: Border(top: BorderSide(color: Colors.grey[100]!)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('EXPLORE FULL METADATA', style: TextStyle(color: AppColors.darkNavy, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                  SizedBox(width: 8),
                  Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.darkNavy, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttributeRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isFirst;

  const _AttributeRow({required this.label, required this.value, this.isFirst = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      decoration: BoxDecoration(
        border: Border(top: isFirst ? BorderSide.none : BorderSide(color: Colors.grey[50]!)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label.toUpperCase(), style: TextStyle(color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: AppColors.darkNavy, fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
