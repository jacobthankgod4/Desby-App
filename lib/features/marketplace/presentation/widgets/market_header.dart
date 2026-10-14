import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/colors.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class MarketHeader extends ConsumerWidget {
  const MarketHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final user = ref.watch(currentUserProvider);
    final isSeller = user?.userType == 'fabric_seller';

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(color: colors.scaffoldBg),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'DESBY MARKET',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
          _HeaderIcon(
            icon: Icons.bookmark_border_rounded,
            onTap: () => ref.pushShell('/favorites', {}),
          ),
          _HeaderIcon(
            icon: Icons.chat_bubble_outline_rounded,
            onTap: () => ref.pushShell('/chats', {}),
          ),
          _HeaderIcon(
            icon: Icons.notifications_none_rounded,
            onTap: () => ref.pushShell('/notifications', {}),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 18,
            backgroundColor: colors.borderSubtle,
            child: Text(
              (user != null && user.name.isNotEmpty)
                  ? user.name[0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 24),
          if (isSeller)
            ElevatedButton(
              onPressed: () => ref.pushShell('/fabric-upload', {}),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amber,
                foregroundColor: AppColors.darkNavy,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
  final VoidCallback? onTap;
  const _HeaderIcon({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: IconButton(
        icon: Icon(icon, color: colors.textSecondary, size: 22),
        onPressed: onTap ?? () {},
        style: IconButton.styleFrom(
          backgroundColor: colors.borderSubtle,
          shape: const CircleBorder(),
        ),
      ),
    );
  }
}
