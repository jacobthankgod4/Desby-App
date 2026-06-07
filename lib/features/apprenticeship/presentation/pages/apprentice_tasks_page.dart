import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desby_app/theme/colors.dart';

class ApprenticeTasksPage extends ConsumerWidget {
  const ApprenticeTasksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1921),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1921),
        title: const Text('My Tasks', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: AppColors.amber),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTaskCard('Complete Measurement Training', 'Due Today', Icons.straighten_rounded),
          const SizedBox(height: 12),
          _buildTaskCard('Submit First Project', 'Due Tomorrow', Icons.assignment_rounded),
          const SizedBox(height: 12),
          _buildTaskCard('Review Fabric Types', 'Due in 3 days', Icons.texture_rounded),
          const SizedBox(height: 12),
          _buildTaskCard('Attend Live Session', 'Due in 5 days', Icons.live_tv_rounded),
        ],
      ),
    );
  }

  Widget _buildTaskCard(String title, String due, IconData icon) {
    final isOverdue = due.contains('Today');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isOverdue ? Colors.redAccent : Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.amber, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(due, style: TextStyle(color: isOverdue ? Colors.redAccent : Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline, color: AppColors.amber),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
