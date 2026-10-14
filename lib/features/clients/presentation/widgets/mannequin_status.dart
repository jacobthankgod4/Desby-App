import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';
import '../../../../core/widgets/luxury_glass_card.dart';

class MannequinStatus extends StatelessWidget {
  final String gender;
  final Map<String, String>? measurements;

  const MannequinStatus({super.key, required this.gender, this.measurements});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bool hasMeasurements =
        measurements != null && measurements!.isNotEmpty;

    return LuxuryGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'GARMENT ARCHITECTURE',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: hasMeasurements
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  hasMeasurements ? 'READY' : 'INCOMPLETE',
                  style: TextStyle(
                    color: hasMeasurements ? Colors.green : Colors.red,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      AppColors.amber.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // SYMBOLIC MANNEQUIN REPRESENTATION (Placeholder for 3D O3D Widget)
              Icon(
                gender == 'FEMALE' ? Icons.woman : Icons.man,
                size: 160,
                color: colors.textPrimary.withValues(alpha: 0.05),
              ),
              Positioned(
                top: 20,
                child: _buildArchitectureTag(
                  'SHOULDER: ${measurements?['shoulder'] ?? '--'}',
                  context,
                ),
              ),
              Positioned(
                top: 80,
                child: _buildArchitectureTag(
                  'CHEST: ${measurements?['chest'] ?? '--'}',
                  context,
                ),
              ),
              Positioned(
                bottom: 40,
                child: _buildArchitectureTag(
                  'LENGTH: ${measurements?['length'] ?? '--'}',
                  context,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'NEURAL SCAN SYNC: ${hasMeasurements ? "ACTIVE" : "PENDING"}',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchitectureTag(String label, BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.amber,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
