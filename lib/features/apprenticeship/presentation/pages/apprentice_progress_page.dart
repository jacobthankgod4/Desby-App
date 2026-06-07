import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desby_app/theme/colors.dart';

class ApprenticeProgressPage extends ConsumerWidget {
  const ApprenticeProgressPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1921),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1921),
        title: const Text('My Progress', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: AppColors.amber),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.amber),
              ),
              child: Column(
                children: [
                  const Text('65%', style: TextStyle(color: AppColors.amber, fontSize: 48, fontWeight: FontWeight.bold)),
                  const Text('Course Complete', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 24),
                  LinearProgressIndicator(
                    value: 0.65,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation(AppColors.amber),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildStatCard('Tasks', '12', Icons.assignment_rounded),
                const SizedBox(width: 12),
                _buildStatCard('Completed', '8', Icons.check_circle_rounded),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildStatCard('In Progress', '4', Icons.pending_rounded),
                const SizedBox(width: 12),
                _buildStatCard('Skills', '5', Icons.star_rounded),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.amber, size: 32),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
