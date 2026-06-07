import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desby_app/theme/colors.dart';

class ApprenticeCurriculumPage extends ConsumerWidget {
  const ApprenticeCurriculumPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1921),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1921),
        title: const Text('My Curriculum', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: AppColors.amber),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildModule('Module 1: Basics of Sewing', 3, true),
          const SizedBox(height: 12),
          _buildModule('Module 2: Measurement Techniques', 5, true),
          const SizedBox(height: 12),
          _buildModule('Module 3: Fabric Selection', 4, false),
          const SizedBox(height: 12),
          _buildModule('Module 4: Pattern Cutting', 6, false),
          const SizedBox(height: 12),
          _buildModule('Module 5: Advanced Stitching', 8, false),
        ],
      ),
    );
  }

  Widget _buildModule(String title, int lessons, bool completed) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: completed ? Colors.greenAccent : Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (completed ? Colors.greenAccent : AppColors.amber).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              completed ? Icons.check_circle_rounded : Icons.menu_book_rounded,
              color: completed ? Colors.greenAccent : AppColors.amber,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('$lessons lessons', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Colors.white24),
        ],
      ),
    );
  }
}
