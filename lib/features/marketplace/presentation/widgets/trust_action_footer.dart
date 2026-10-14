import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/providers/layout_provider.dart';
import '../../../../theme/colors.dart';

class TrustActionFooter extends ConsumerWidget {
  final double? amount;
  final String? orderId;
  const TrustActionFooter({super.key, this.amount, this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final isMobile = !ref.watch(isDesktopProvider);

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colors.scaffoldBg,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 40),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure Ecosystem Guarantee',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your payments are held in secure escrow until you physically verify the fabric quality.',
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to cart instead of direct checkout (order doesn't exist yet)
                      ref.pushShell('/marketplace-cart', {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amber,
                      foregroundColor: AppColors.darkNavy,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'PURCHASE NOW',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Contact the seller directly to negotiate pricing.',
                          ),
                          backgroundColor: colors.snackbarBg,
                        ),
                      );
                    },
                    child: const Text(
                      'MAKE AN OFFER',
                      style: TextStyle(
                        color: AppColors.amber,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Secure Ecosystem Guarantee',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your payments are held in secure escrow until you physically verify the fabric quality.',
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 60),
                ElevatedButton(
                  onPressed: () {
                    ref.pushShell('/marketplace-cart', {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    foregroundColor: AppColors.darkNavy,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 22,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'PURCHASE NOW',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Contact the seller directly to negotiate pricing.',
                        ),
                        backgroundColor: colors.snackbarBg,
                      ),
                    );
                  },
                  child: const Text(
                    'MAKE AN OFFER',
                    style: TextStyle(
                      color: AppColors.amber,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
