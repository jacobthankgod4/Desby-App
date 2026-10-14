import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../theme/colors.dart';
import '../../../../core/widgets/shell_app_bar.dart';

final masterclassProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  try {
    final supabase = Supabase.instance.client;

    final response = await supabase
        .from('curriculum_modules')
        .select(
          'id, title, description, masterclass_thumbnail, tailor_id, lesson_ids',
        )
        .not('masterclass_thumbnail', 'is', null)
        .order('order_index');

    final results = <Map<String, dynamic>>[];
    for (final mod in (response as List)) {
      final tailor = await supabase
          .from('users')
          .select('name, profile_image')
          .eq('id', mod['tailor_id'])
          .maybeSingle();

      results.add({
        ...mod,
        'tailor_name': tailor?['name'] ?? 'Master Tailor',
        'tailor_image': tailor?['profile_image'],
        'lesson_count': (mod['lesson_ids'] as List?)?.length ?? 0,
      });
    }
    return results;
  } catch (e) {
    return [];
  }
});

class MasterclassPage extends ConsumerWidget {
  const MasterclassPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final masterclassAsync = ref.watch(masterclassProvider);

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: shellAppBar(
        context,
        title: 'MASTERCLASSES',
        foregroundColor: colors.textPrimary,
      ),
      body: masterclassAsync.when(
        data: (classes) {
          if (classes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.play_circle_outline,
                    size: 64,
                    color: colors.textHint,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No masterclasses available yet',
                    style: TextStyle(color: colors.textHint, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back soon for exclusive content',
                    style: TextStyle(color: colors.textMuted, fontSize: 13),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: classes.length,
            itemBuilder: (_, i) => _MasterclassCard(data: classes[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('Could not load masterclasses')),
      ),
    );
  }
}

class _MasterclassCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _MasterclassCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              image: data['masterclass_thumbnail'] != null
                  ? DecorationImage(
                      image: NetworkImage(data['masterclass_thumbnail']),
                      fit: BoxFit.cover,
                    )
                  : null,
              gradient: data['masterclass_thumbnail'] == null
                  ? LinearGradient(
                      colors: [
                        AppColors.amber.withValues(alpha: 0.2),
                        AppColors.darkNavy,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
            ),
            child: data['masterclass_thumbnail'] == null
                ? Center(
                    child: Icon(
                      Icons.play_circle_outline,
                      size: 48,
                      color: colors.textMuted,
                    ),
                  )
                : Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.amber,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${data['lesson_count']} lessons',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'] ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  data['description'] ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textMuted,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: colors.borderDefault,
                      backgroundImage: data['tailor_image'] != null
                          ? NetworkImage(data['tailor_image'])
                          : null,
                      child: data['tailor_image'] == null
                          ? Icon(Icons.person, size: 12, color: colors.textHint)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      data['tailor_name'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
