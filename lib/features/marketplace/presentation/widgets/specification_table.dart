import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';
import '../../domain/entities/fabric.dart';

class SpecificationTable extends StatelessWidget {
  final Fabric? fabric;
  const SpecificationTable({super.key, this.fabric});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final colorList = fabric?.availableColors ?? [];
    final firstColor = colorList.isNotEmpty ? colorList.first : null;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.borderDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _AttributeRow(
            label: 'Origin',
            value: fabric?.origin ?? 'N/A',
            isFirst: true,
          ),
          _AttributeRow(label: 'Type', value: fabric?.category ?? 'N/A'),
          _AttributeRow(label: 'Material', value: fabric?.composition ?? 'N/A'),
          _AttributeRow(label: 'Weight', value: fabric?.weight ?? 'N/A'),
          if (firstColor != null)
            _AttributeRow(label: 'Color', value: firstColor),
        ],
      ),
    );
  }
}

class _AttributeRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isFirst;

  const _AttributeRow({
    required this.label,
    required this.value,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      decoration: BoxDecoration(
        border: Border(
          top: isFirst ? BorderSide.none : BorderSide(color: colors.divider),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
