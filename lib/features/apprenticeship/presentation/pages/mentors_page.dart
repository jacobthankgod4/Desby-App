import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desby_app/theme/colors.dart';

class MentorsPage extends ConsumerWidget {
  const MentorsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1921),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1921),
        title: const Text('My Mentors', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: AppColors.amber),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMentorCard('Master Tailor Adebayo', '5 Years Experience', 4.8),
          const SizedBox(height: 12),
          _buildMentorCard('Fashion Designer Grace', '10 Years Experience', 4.9),
          const SizedBox(height: 12),
          _buildMentorCard('Pattern Expert Mike', '8 Years Experience', 4.7),
        ],
      ),
    );
  }

  Widget _buildMentorCard(String name, String experience, double rating) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.amber.withValues(alpha: 0.2),
            child: Text(
              name[0],
              style: const TextStyle(color: AppColors.amber, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(experience, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: AppColors.amber, size: 16),
              const SizedBox(width: 4),
              Text(rating.toString(), style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
