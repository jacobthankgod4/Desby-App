import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/colors.dart';

class TailorAvailabilityPage extends ConsumerWidget {
  final Map<String, dynamic> tailor;

  const TailorAvailabilityPage({super.key, required this.tailor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1921),
      appBar: AppBar(
        title: const Text('Appointments', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Offline Card
          _buildAvailabilityCard(
            status: 'Offline',
            statusColor: Colors.redAccent,
            actionLabel: 'Get Directions',
            actionIcon: Icons.directions_rounded,
            onAction: () {},
          ),
          const SizedBox(height: 24),
          
          // Online Card
          _buildAvailabilityCard(
            status: 'Online',
            statusColor: Colors.greenAccent,
            showSecondAction: true,
            actionLabel: 'Call',
            actionIcon: Icons.phone_rounded,
            secondActionLabel: 'Book Appointment',
            secondActionIcon: Icons.calendar_today_rounded,
            onAction: () {},
            onSecondAction: () => Navigator.pushNamed(context, '/booking-cart', arguments: tailor),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityCard({
    required String status,
    required Color statusColor,
    required String actionLabel,
    required IconData actionIcon,
    required VoidCallback onAction,
    bool showSecondAction = false,
    String? secondActionLabel,
    IconData? secondActionIcon,
    VoidCallback? onSecondAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.amber,
                child: Text(
                  (tailor['name'] ?? 'T')[0].toString().toUpperCase(),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.darkNavy),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tailor['name'] ?? 'Tailor Name',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      tailor['location'] ?? 'Shop Address',
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.phone_outlined, color: AppColors.amber, size: 18),
              const SizedBox(width: 12),
              Text(
                tailor['phone'] ?? '+234 800 000 0000',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.access_time_rounded, color: AppColors.amber, size: 18),
              SizedBox(width: 12),
              Text(
                '09:00 AM - 06:00 PM',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onAction,
                  icon: Icon(actionIcon, size: 18),
                  label: Text(actionLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: showSecondAction ? Colors.white10 : AppColors.amber,
                    foregroundColor: showSecondAction ? Colors.white : AppColors.darkNavy,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              if (showSecondAction) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onSecondAction,
                    icon: Icon(secondActionIcon!, size: 18),
                    label: Text(secondActionLabel!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amber,
                      foregroundColor: AppColors.darkNavy,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
