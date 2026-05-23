import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';

class ShortcutCards extends StatelessWidget {
  const ShortcutCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ShortcutTile(
          title: 'Bulk Order Guide',
          sub: 'Learn about merchant discounts',
          icon: Icons.auto_stories_rounded,
          color: Colors.blue,
        ),
        const SizedBox(width: 16),
        _ShortcutTile(
          title: 'Verify as Dealer',
          sub: 'Get the verified merchant badge',
          icon: Icons.verified_rounded,
          color: Colors.green,
        ),
        const SizedBox(width: 16),
        _ShortcutTile(
          title: 'Import Request',
          sub: 'Can\'t find what you need?',
          icon: Icons.airplanemode_active_rounded,
          color: AppColors.amber,
        ),
      ],
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  final String title;
  final String sub;
  final IconData icon;
  final Color color;

  const _ShortcutTile({
    required this.title,
    required this.sub,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title functionality coming soon to Desby Marketplace.')),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[100]!),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.darkNavy),
                    ),
                    Text(
                      sub,
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
