import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../theme/colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/widgets/shell_app_bar.dart';

final portfolioProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  try {
    final supabase = Supabase.instance.client;

    // Get completed tasks with images
    final tasks = await supabase
        .from('apprentice_tasks')
        .select('id, title, description, score, proof_image_urls, completed_at')
        .eq('apprentice_id', user.id)
        .eq('status', 'completed')
        .order('completed_at', ascending: false);

    return (tasks as List)
        .where((t) {
          final images = t['proof_image_urls'];
          return images != null && (images as List).isNotEmpty;
        })
        .map((t) => Map<String, dynamic>.from(t as Map))
        .toList();
  } catch (e) {
    return [];
  }
});

class ApprenticePortfolioPage extends ConsumerWidget {
  const ApprenticePortfolioPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final portfolioAsync = ref.watch(portfolioProvider);

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: shellAppBar(
        context,
        title: 'MY PORTFOLIO',
        foregroundColor: colors.textPrimary,
      ),
      body: portfolioAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.work_outline, size: 64, color: colors.textHint),
                  const SizedBox(height: 16),
                  Text(
                    'No portfolio items yet',
                    style: TextStyle(color: colors.textHint, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete tasks with photos to build your portfolio',
                    style: TextStyle(color: colors.textMuted, fontSize: 13),
                  ),
                ],
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) => _PortfolioCard(item: items[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Could not load portfolio')),
      ),
    );
  }
}

class _PortfolioCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _PortfolioCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final images = (item['proof_image_urls'] as List?) ?? [];
    final score = item['score'] as double?;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                image: images.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(images.first),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : colors.surfaceAlt,
              ),
              child: images.isEmpty
                  ? const Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 32,
                        color: Colors.grey,
                      ),
                    )
                  : score != null
                  ? Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.successGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${score.toInt()}%',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
          ),
          // Info
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: colors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Text(
                    '${images.length} photo${images.length == 1 ? '' : 's'}',
                    style: TextStyle(fontSize: 10, color: colors.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
