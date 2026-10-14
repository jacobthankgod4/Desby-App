import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../theme/colors.dart';
import '../../../../core/widgets/shell_app_bar.dart';

final showcaseProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  try {
    final supabase = Supabase.instance.client;

    // Get top apprentices by progress
    final response = await supabase
        .from('apprenticeships')
        .select('id, apprentice_id, level, progress, skill_ids')
        .eq('status', 'active')
        .order('progress', ascending: false)
        .limit(20);

    final results = <Map<String, dynamic>>[];
    for (final app in (response as List)) {
      final profile = await supabase
          .from('users')
          .select('id, name, profile_image, user_type')
          .eq('id', app['apprentice_id'])
          .maybeSingle();

      if (profile != null) {
        results.add({
          ...profile,
          'level': app['level'] ?? 'Beginner',
          'progress': app['progress'] ?? 0,
          'skill_count': (app['skill_ids'] as List?)?.length ?? 0,
        });
      }
    }
    return results;
  } catch (e) {
    return [];
  }
});

class ShowcasePage extends ConsumerWidget {
  const ShowcasePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final showcaseAsync = ref.watch(showcaseProvider);

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: shellAppBar(
        context,
        title: 'APPRENTICE SHOWCASE',
        foregroundColor: colors.textPrimary,
      ),
      body: showcaseAsync.when(
        data: (apprentices) {
          if (apprentices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_outline, size: 64, color: colors.textHint),
                  const SizedBox(height: 16),
                  Text(
                    'No apprentices to showcase yet',
                    style: TextStyle(color: colors.textHint, fontSize: 16),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: apprentices.length,
            itemBuilder: (_, i) =>
                _ShowcaseCard(data: apprentices[i], rank: i + 1),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Could not load showcase')),
      ),
    );
  }
}

class _ShowcaseCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final int rank;
  const _ShowcaseCard({required this.data, required this.rank});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = (data['progress'] as num? ?? 0).toDouble();
    final progressPercent = (progress * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: rank <= 3
            ? Border.all(color: AppColors.amber.withValues(alpha: 0.3))
            : null,
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rank <= 3
                  ? AppColors.amber.withValues(alpha: 0.15)
                  : colors.borderDefault.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: rank <= 3 ? AppColors.amber : colors.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: colors.borderDefault,
            backgroundImage: data['profile_image'] != null
                ? NetworkImage(data['profile_image'])
                : null,
            child: data['profile_image'] == null
                ? Icon(Icons.person, color: colors.textHint, size: 20)
                : null,
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'] ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${data['level']} • ${data['skill_count']} skills',
                  style: TextStyle(fontSize: 11, color: colors.textMuted),
                ),
              ],
            ),
          ),
          // Progress
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Text(
                  '$progressPercent%',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppColors.amber,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: colors.borderDefault,
                    valueColor: const AlwaysStoppedAnimation(AppColors.amber),
                    minHeight: 3,
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
