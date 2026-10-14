import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desby_app/theme/colors.dart';
import 'package:desby_app/core/providers/navigation_provider.dart';
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;
import '../../domain/entities/apprentice_module.dart' show ApprenticeLesson;
import '../providers/apprenticeship_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/widgets/shell_app_bar.dart';
import '../../../../core/widgets/app_network_image.dart';

class ModuleDetailPage extends ConsumerWidget {
  final String moduleId;
  const ModuleDetailPage({super.key, required this.moduleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final currentUser = ref.watch(currentUserProvider);
    final apprenticeId = currentUser?.id ?? '';
    final apprenticeshipAsync = ref.watch(
      apprenticeApprenticeshipProvider(apprenticeId),
    );
    final lessonsAsync = ref.watch(moduleLessonsProvider(moduleId));
    final curriculumAsync = ref.watch(curriculumProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 1000;

    final module = curriculumAsync.whenOrNull(
      data: (modules) => modules.where((m) => m.id == moduleId).firstOrNull,
    );

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: shellAppBar(
        context,
        title: (module?.title ?? 'Module').toUpperCase(),
      ),
      body: Column(
        children: [
          if (module != null && module.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(
                module.description,
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
            ),
          Expanded(
            child: lessonsAsync.when(
              data: (lessons) {
                if (lessons.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.article_outlined,
                          color: colors.iconMuted,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No lessons yet',
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return apprenticeshipAsync.when(
                  data: (app) {
                    final completedAsync = app != null
                        ? ref.watch(completedLessonsProvider(app.id))
                        : null;
                    if (completedAsync == null)
                      return _buildLessonGrid(
                        lessons,
                        isWide,
                        onLessonTap: (id) => ref.pushShell(
                          '/apprentice-lesson-detail',
                          {'lessonId': id},
                        ),
                      );
                    return completedAsync.when(
                      data: (completed) => GridView.builder(
                        padding: const EdgeInsets.all(24),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isWide ? 3 : 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: lessons.length,
                        itemBuilder: (context, index) => _LessonGridCard(
                          lesson: lessons[index],
                          index: index,
                          isCompleted: completed.contains(lessons[index].id),
                          onTap: () {
                            ref.pushShell('/apprentice-lesson-detail', {
                              'lessonId': lessons[index].id,
                            });
                          },
                        ),
                      ),
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.amber,
                        ),
                      ),
                      error: (_, __) => _buildLessonGrid(
                        lessons,
                        isWide,
                        onLessonTap: (id) => ref.pushShell(
                          '/apprentice-lesson-detail',
                          {'lessonId': id},
                        ),
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.amber),
                  ),
                  error: (_, __) => _buildLessonGrid(
                    lessons,
                    isWide,
                    onLessonTap: (id) => ref.pushShell(
                      '/apprentice-lesson-detail',
                      {'lessonId': id},
                    ),
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.amber),
              ),
              error: (err, _) => Center(
                child: Text(
                  'Failed to load lessons',
                  style: TextStyle(color: colors.textSecondary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonGrid(
    List<ApprenticeLesson> lessons,
    bool isWide, {
    Set<String> completedIds = const {},
    required void Function(String lessonId) onLessonTap,
  }) {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWide ? 3 : 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: lessons.length,
      itemBuilder: (context, index) => _LessonGridCard(
        lesson: lessons[index],
        index: index,
        isCompleted: completedIds.contains(lessons[index].id),
        onTap: () => onLessonTap(lessons[index].id),
      ),
    );
  }
}

class _LessonGridCard extends StatelessWidget {
  final ApprenticeLesson lesson;
  final int index;
  final bool isCompleted;
  final VoidCallback onTap;

  const _LessonGridCard({
    required this.lesson,
    required this.index,
    required this.isCompleted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasVideo = lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty;
    final hasThumbnail =
        lesson.thumbnailUrl != null && lesson.thumbnailUrl!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isCompleted
              ? AppColors.successGreen.withValues(alpha: 0.05)
              : colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCompleted
                ? AppColors.successGreen.withValues(alpha: 0.2)
                : colors.cardBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colors.scaffoldBg,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (hasThumbnail)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          child: AppNetworkImage(
                            url: lesson.thumbnailUrl!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    else if (hasVideo)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          child: _VideoPosterFrame(videoUrl: lesson.videoUrl!),
                        ),
                      )
                    else
                      _buildFallbackIcon(context, false),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colors.scaffoldBg,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.amber.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: AppColors.amber,
                        size: 28,
                      ),
                    ),
                    if (isCompleted)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.successGreen,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'DONE',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: _TypeBadge(lessonType: lesson.lessonType),
                    ),
                    if (lesson.durationMinutes != null &&
                        lesson.durationMinutes! > 0)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: _DurationBadge(minutes: lesson.durationMinutes!),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? AppColors.successGreen.withValues(alpha: 0.15)
                                : AppColors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: isCompleted
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: AppColors.successGreen,
                                    size: 14,
                                  )
                                : Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: AppColors.amber,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            lesson.title,
                            style: TextStyle(
                              color: isCompleted
                                  ? colors.textMuted
                                  : colors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isCompleted ? 'Completed' : 'Tap to start',
                      style: TextStyle(
                        color: isCompleted
                            ? AppColors.successGreen
                            : colors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackIcon(BuildContext context, bool hasVideo) {
    final colors = context.colors;
    return Container(
      color: colors.scaffoldBg,
      child: Center(
        child: Icon(
          hasVideo ? Icons.videocam_rounded : Icons.article_outlined,
          color: AppColors.amber.withValues(alpha: 0.3),
          size: 36,
        ),
      ),
    );
  }
}

class _VideoPosterFrame extends StatefulWidget {
  final String videoUrl;
  const _VideoPosterFrame({required this.videoUrl});

  @override
  State<_VideoPosterFrame> createState() => _VideoPosterFrameState();
}

class _VideoPosterFrameState extends State<_VideoPosterFrame> {
  late String _viewId;

  @override
  void initState() {
    super.initState();
    _viewId = 'video-thumb-${widget.videoUrl.hashCode}';
    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int id) {
      final video = web.HTMLVideoElement()
        ..src = widget.videoUrl
        ..preload = 'metadata'
        ..muted = true
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';
      return video;
    });
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewId);
  }
}

const _typeLabels = {
  'video': 'Video',
  'text': 'Text',
  'assignment': 'Task',
  'download': 'File',
};
const _typeIcons = {
  'video': Icons.videocam_rounded,
  'text': Icons.article_outlined,
  'assignment': Icons.assignment_turned_in_rounded,
  'download': Icons.download_rounded,
};

class _TypeBadge extends StatelessWidget {
  final String lessonType;
  const _TypeBadge({required this.lessonType});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _typeIcons[lessonType] ?? Icons.circle,
            color: AppColors.amber,
            size: 9,
          ),
          const SizedBox(width: 3),
          Text(
            _typeLabels[lessonType] ?? lessonType,
            style: TextStyle(
              color: AppColors.amber.withValues(alpha: 0.7),
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DurationBadge extends StatelessWidget {
  final int minutes;
  const _DurationBadge({required this.minutes});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final label = h > 0 ? '${h}h ${m}m' : '${m}m';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, color: colors.iconMuted, size: 9),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: colors.iconMuted,
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
