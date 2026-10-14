import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/colors.dart';

class AcademyCard extends ConsumerWidget {
  final Widget child;
  final Widget? header;
  final VoidCallback? onTap;
  final Color? accentColor;
  final bool isGlowing;

  const AcademyCard({
    super.key,
    required this.child,
    this.header,
    this.onTap,
    this.accentColor,
    this.isGlowing = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (isGlowing && accentColor != null)
            BoxShadow(
              color: accentColor!.withValues(alpha: 0.15),
              blurRadius: 20,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (header != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceHover,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: header,
                  ),
                Padding(padding: const EdgeInsets.all(20), child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
