import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../theme/colors.dart';

class CurriculumProgressHud extends ConsumerWidget {
  final double progress;
  final String level;
  final String nextTarget;

  const CurriculumProgressHud({
    super.key,
    required this.progress,
    required this.level,
    required this.nextTarget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final percent = (progress * 100).toInt();
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (!isDark) ...[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.white,
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
          if (isDark) ...[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ],
      ),
      child: Row(
        children: [
          // Circular Progress
          SizedBox(
            height: 88,
            width: 88,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                SizedBox(
                  height: 88,
                  width: 88,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 8,
                    strokeCap: StrokeCap.round,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : colors.surfaceAlt,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.transparent,
                    ),
                  ),
                ),
                // Progress circle
                SizedBox(
                  height: 88,
                  width: 88,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    strokeCap: StrokeCap.round,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      percent >= 100 ? AppColors.successGreen : AppColors.amber,
                    ),
                  ),
                ),
                // Percentage text
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$percent%',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        height: 1,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'DONE',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: colors.textHint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Info Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Level badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    level.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.amber,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Next milestone
                Text(
                  nextTarget,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: colors.textPrimary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // Continue button
                GestureDetector(
                  onTap: () => ref.pushShell('/curriculum'),
                  child: Row(
                    children: [
                      Text(
                        'Continue Training',
                        style: TextStyle(
                          color: AppColors.amber,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.amber,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
