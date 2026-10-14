import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desby_app/theme/colors.dart';
import 'package:desby_app/core/providers/navigation_provider.dart';
import '../../domain/entities/apprentice_module.dart';
import '../providers/apprenticeship_provider.dart';
import '../../../../core/widgets/shell_app_bar.dart';

class CurriculumSetupPage extends ConsumerStatefulWidget {
  const CurriculumSetupPage({super.key});

  @override
  ConsumerState<CurriculumSetupPage> createState() =>
      _CurriculumSetupPageState();
}

class _CurriculumSetupPageState extends ConsumerState<CurriculumSetupPage> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final curriculumAsync = ref.watch(curriculumProvider);

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: shellAppBar(
        context,
        title: 'Curriculum Builder',
        actions: [
          TextButton.icon(
            onPressed: () => _navigateToModuleCreate(context),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('ADD MODULE'),
            style: TextButton.styleFrom(foregroundColor: AppColors.amber),
          ),
        ],
      ),
      body: curriculumAsync.when(
        data: (modules) {
          if (modules.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    color: colors.iconMuted,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No modules yet',
                    style: TextStyle(
                      color: colors.textHint,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first module to start teaching',
                    style: TextStyle(color: colors.textHint, fontSize: 12),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToModuleCreate(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('CREATE MODULE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amber,
                      foregroundColor: AppColors.darkNavy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
            itemCount: modules.length,
            onReorder: (oldIndex, newIndex) =>
                _onReorderModules(modules, oldIndex, newIndex),
            itemBuilder: (context, index) {
              final module = modules[index];
              return _ModuleCard(
                key: ValueKey(module.id),
                module: module,
                index: index,
                onAddLesson: () => _navigateToLessonCreate(context, module),
                onEditModule: () => _navigateToModuleEdit(context, module),
                onDelete: () => _showDeleteModuleDialog(context, module),
                onEditLesson: (lesson) =>
                    _navigateToLessonEdit(context, module, lesson),
                onDeleteLesson: (lesson) =>
                    _showDeleteLessonDialog(context, lesson),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.amber),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Failed to load curriculum',
                style: TextStyle(color: colors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToModuleCreate(BuildContext context) {
    ref.pushShell('/module-create', {});
  }

  void _navigateToModuleEdit(BuildContext context, ApprenticeModule module) {
    ref.pushShell('/module-create', {
      'moduleId': module.id,
      'existingTitle': module.title,
      'existingDescription': module.description,
      'existingThumbnail': module.masterclassThumbnail,
    });
  }

  void _navigateToLessonCreate(BuildContext context, ApprenticeModule module) {
    ref.pushShell('/lesson-create', {
      'moduleId': module.id,
      'moduleName': module.title,
    });
  }

  void _navigateToLessonEdit(
    BuildContext context,
    ApprenticeModule module,
    ApprenticeLesson lesson,
  ) {
    ref.pushShell('/lesson-create', {
      'moduleId': module.id,
      'moduleName': module.title,
      'lessonId': lesson.id,
      'existingTitle': lesson.title,
      'existingContent': lesson.content,
      'existingVideoUrl': lesson.videoUrl,
      'existingShortDescription': lesson.shortDescription,
      'existingThumbnailUrl': lesson.thumbnailUrl,
      'existingDurationMinutes': lesson.durationMinutes,
      'existingLessonType': lesson.lessonType,
      'existingIsPublished': lesson.isPublished,
      'existingIsFreePreview': lesson.isFreePreview,
      'existingAttachments': lesson.attachments,
    });
  }

  Future<void> _onReorderModules(
    List<ApprenticeModule> modules,
    int oldIndex,
    int newIndex,
  ) async {
    if (oldIndex < newIndex) newIndex--;
    final reordered = List<ApprenticeModule>.from(modules);
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);
    final ids = reordered.map((m) => m.id).toList();
    final repo = ref.read(apprenticeshipRepositoryProvider);
    await repo.reorderModules(ids);
    ref.invalidate(curriculumProvider);
  }

  void _showDeleteModuleDialog(BuildContext context, ApprenticeModule module) {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'DELETE MODULE?',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          'This will permanently remove "${module.title}" and all its lessons.',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: colors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              final repo = ref.read(apprenticeshipRepositoryProvider);
              final result = await repo.deleteModule(module.id);
              if (ctx.mounted) Navigator.pop(ctx);
              if (result.isSuccess) {
                ref.invalidate(curriculumProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Module deleted'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteLessonDialog(BuildContext context, ApprenticeLesson lesson) {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'DELETE LESSON?',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          'This will permanently remove "${lesson.title}".',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: colors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              final repo = ref.read(apprenticeshipRepositoryProvider);
              final result = await repo.deleteLesson(lesson.id);
              if (ctx.mounted) Navigator.pop(ctx);
              if (result.isSuccess) {
                ref.invalidate(curriculumProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lesson deleted'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends ConsumerStatefulWidget {
  final ApprenticeModule module;
  final int index;
  final VoidCallback onAddLesson;
  final VoidCallback onEditModule;
  final VoidCallback onDelete;
  final Function(ApprenticeLesson) onEditLesson;
  final Function(ApprenticeLesson) onDeleteLesson;

  const _ModuleCard({
    super.key,
    required this.module,
    required this.index,
    required this.onAddLesson,
    required this.onEditModule,
    required this.onDelete,
    required this.onEditLesson,
    required this.onDeleteLesson,
  });

  @override
  ConsumerState<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends ConsumerState<_ModuleCard> {
  bool _isExpanded = false;
  List<ApprenticeLesson>? _localLessons;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final lessonsAsync = ref.watch(moduleLessonsProvider(widget.module.id));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.cardBorder),
      ),
      child: ExpansionTile(
        initiallyExpanded: _isExpanded,
        onExpansionChanged: (expanded) =>
            setState(() => _isExpanded = expanded),
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        iconColor: AppColors.amber,
        collapsedIconColor: colors.iconMuted,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              '${widget.index + 1}',
              style: TextStyle(
                color: AppColors.amber,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
        ),
        title: Text(
          widget.module.title.toUpperCase(),
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                widget.module.description.isNotEmpty
                    ? widget.module.description
                    : 'No description',
                style: TextStyle(color: colors.textMuted, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            lessonsAsync.when(
              data: (lessons) => Text(
                '${lessons.length} lesson${lessons.length == 1 ? '' : 's'}',
                style: TextStyle(
                  color: colors.textHint,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert_rounded,
            color: colors.iconMuted,
            size: 18,
          ),
          color: colors.popupMenuBg,
          surfaceTintColor: Colors.transparent,
          onSelected: (value) {
            if (value == 'edit') widget.onEditModule();
            if (value == 'delete') widget.onDelete();
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Text(
                'Edit Module',
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
        children: [
          lessonsAsync.when(
            data: (lessons) {
              final displayLessons = _localLessons ?? lessons;
              if (displayLessons.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'No lessons yet. Add your first lesson below.',
                    style: TextStyle(color: colors.textHint, fontSize: 12),
                  ),
                );
              }
              return ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: displayLessons.length,
                onReorder: (oldIndex, newIndex) =>
                    _onReorderLessons(displayLessons, oldIndex, newIndex),
                proxyDecorator: (child, index, animation) => Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.dialogBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.amber.withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: child,
                  ),
                ),
                itemBuilder: (context, index) {
                  final lesson = displayLessons[index];
                  return Container(
                    key: ValueKey(lesson.id),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colors.containerFill,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        ReorderableDragStartListener(
                          index: index,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.drag_handle_rounded,
                              color: colors.iconMuted,
                              size: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: lesson.videoUrl != null
                                ? AppColors.amber.withValues(alpha: 0.1)
                                : colors.inputFill,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            lesson.videoUrl != null
                                ? Icons.play_arrow_rounded
                                : Icons.article_outlined,
                            color: lesson.videoUrl != null
                                ? AppColors.amber
                                : colors.textMuted,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lesson.title,
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  _TypeBadge(lessonType: lesson.lessonType),
                                  if (lesson.durationMinutes != null &&
                                      lesson.durationMinutes! > 0) ...[
                                    const SizedBox(width: 6),
                                    _DurationBadge(
                                      minutes: lesson.durationMinutes!,
                                    ),
                                  ],
                                  if (!lesson.isPublished) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'DRAFT',
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (lesson.isFreePreview) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.amber.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'FREE',
                                        style: TextStyle(
                                          color: AppColors.amber,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color: colors.iconMuted,
                            size: 16,
                          ),
                          color: colors.popupMenuBg,
                          surfaceTintColor: Colors.transparent,
                          onSelected: (value) {
                            if (value == 'edit') widget.onEditLesson(lesson);
                            if (value == 'delete')
                              widget.onDeleteLesson(lesson);
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text(
                                'Edit',
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                'Delete',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.amber,
                ),
              ),
            ),
            error: (_, __) => const Text(
              'Failed to load lessons',
              style: TextStyle(color: Colors.redAccent, fontSize: 11),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onAddLesson,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('ADD LESSON'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.amber,
                side: BorderSide(color: AppColors.amber.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onReorderLessons(
    List<ApprenticeLesson> lessons,
    int oldIndex,
    int newIndex,
  ) async {
    if (oldIndex < newIndex) newIndex--;
    final reordered = List<ApprenticeLesson>.from(lessons);
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);

    // Update local state synchronously so ReorderableListView doesn't snap back
    setState(() => _localLessons = reordered);

    final ids = reordered.map((l) => l.id).toList();
    final repo = ref.read(apprenticeshipRepositoryProvider);
    final result = await repo.reorderLessons(widget.module.id, ids);

    if (result.isSuccess) {
      ref.invalidate(moduleLessonsProvider(widget.module.id));
    }
    // Clear local override so provider data takes over
    if (mounted) setState(() => _localLessons = null);
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
