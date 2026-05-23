import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';

class MarketHeader extends StatelessWidget {
  const MarketHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.darkNavy, // Strong brand-colored header block per spec
      ),
      child: Row(
        children: [
          // Wordmark Area
          const Text(
            'DESBY MARKET',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          
          // Icon Cluster
          _HeaderIcon(icon: Icons.bookmark_border_rounded),
          _HeaderIcon(icon: Icons.chat_bubble_outline_rounded),
          _HeaderIcon(icon: Icons.notifications_none_rounded),
          _HeaderIcon(icon: Icons.description_outlined),
          
          const SizedBox(width: 12),
          
          // Profile Access
          const CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white10,
            child: Icon(Icons.person_outline_rounded, color: Colors.white70, size: 20),
          ),
          
          const SizedBox(width: 24),
          
          // High-emphasis Primary CTA (Warm accent color per spec)
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amber,
              foregroundColor: AppColors.darkNavy,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text(
              'SELL FABRIC',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  const _HeaderIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: IconButton(
        icon: Icon(icon, color: Colors.white70, size: 22),
        onPressed: () {},
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          shape: const CircleBorder(),
        ),
      ),
    );
  }
}
