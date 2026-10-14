import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/curriculum_progress_hud.dart';
import '../../domain/entities/apprentice_task.dart';
import '../../domain/entities/apprentice_module.dart';
import '../providers/apprenticeship_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../theme/colors.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/providers/navigation_provider.dart';

class ApprenticeLearningPage extends ConsumerWidget {
  const ApprenticeLearningPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final currentUser = ref.watch(currentUserProvider);
    final apprenticeId = currentUser?.id ?? '';
    final apprenticeshipAsync = ref.watch(
      apprenticeApprenticeshipProvider(apprenticeId),
    );
    final curriculumAsync = ref.watch(curriculumProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 1000;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 32),
              child: apprenticeshipAsync.when(
                data: (app) {
                  final level = app?.level ?? 'Beginner';
                  final nextTarget = _computeNextTarget(app, curriculumAsync);
                  return CurriculumProgressHud(
                    progress: app?.progress ?? 0.0,
                    level: 'Rank: $level',
                    nextTarget: nextTarget,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => const SizedBox(),
              ),
            ),
          ),
          _buildSliverHeader('ACADEMY SYLLABUS', colors),
          curriculumAsync.when(
            data: (modules) {
              if (modules.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.menu_book_outlined,
                            color: colors.textHint,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No modules yet',
                            style: TextStyle(
                              color: colors.textHint,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isWide ? 3 : 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _ModuleGridCard(module: modules[index]),
                    childCount: modules.length,
                  ),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => const SliverToBoxAdapter(
              child: ErrorStateWidget(message: 'Could not load curriculum.'),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
          _buildSliverHeader('OPERATIONAL TASKS', colors),
          _buildTasksSliver(ref, apprenticeId),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  String _computeNextTarget(
    dynamic app,
    AsyncValue<List<ApprenticeModule>> curriculumAsync,
  ) {
    if (app == null || curriculumAsync is! AsyncData<List<ApprenticeModule>>)
      return 'No curriculum loaded';
    final modules = curriculumAsync.value;
    if (modules.isEmpty) return 'No modules available';
    final completedCount = (app.progress * modules.length).floor();
    if (completedCount >= modules.length) return 'All modules completed!';
    return modules[completedCount].title;
  }

  Widget _buildSliverHeader(String title, DesbyThemeColors colors) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: colors.textHint,
          ),
        ),
      ),
    );
  }

  Widget _buildTasksSliver(WidgetRef ref, String apprenticeId) {
    final apprenticeshipAsync = ref.watch(
      apprenticeApprenticeshipProvider(apprenticeId),
    );
    return apprenticeshipAsync.when(
      data: (apprenticeship) {
        if (apprenticeship == null)
          return const SliverToBoxAdapter(child: SizedBox());
        final tasksAsync = ref.watch(
          apprenticeshipTasksProvider(apprenticeship.id),
        );
        return tasksAsync.when(
          data: (tasks) => SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _ModernTaskTile(task: tasks[index]),
                childCount: tasks.length,
              ),
            ),
          ),
          loading: () => const SliverToBoxAdapter(child: SizedBox()),
          error: (err, _) => const SliverToBoxAdapter(child: SizedBox()),
        );
      },
      loading: () => const SliverToBoxAdapter(child: SizedBox()),
      error: (err, _) => const SliverToBoxAdapter(child: SizedBox()),
    );
  }
}

class _ModuleGridCard extends ConsumerWidget {
  final ApprenticeModule module;
  const _ModuleGridCard({required this.module});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = ref.watch(currentUserProvider);
    final apprenticeId = currentUser?.id ?? '';
    final apprenticeshipAsync = ref.watch(
      apprenticeApprenticeshipProvider(apprenticeId),
    );

    return apprenticeshipAsync.when(
      data: (app) {
        final completedAsync = app != null
            ? ref.watch(completedLessonsProvider(app.id))
            : null;
        final totalLessons = module.lessonIds.length;

        return GestureDetector(
          onTap: () => ref.pushShell('/module-detail', {'moduleId': module.id}),
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                if (!isDark) ...[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.white,
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
                if (isDark) ...[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Module icon header
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                AppColors.amber.withValues(alpha: 0.15),
                                colors.surface,
                              ]
                            : [
                                AppColors.amber.withValues(alpha: 0.08),
                                colors.surface,
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.menu_book_rounded,
                          color: AppColors.amber.withValues(alpha: 0.4),
                          size: 44,
                        ),
                        if (completedAsync != null)
                          completedAsync.when(
                            data: (completed) {
                              final done = module.lessonIds
                                  .where((id) => completed.contains(id))
                                  .length;
                              if (done == totalLessons && totalLessons > 0) {
                                return Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.successGreen,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                      child: Text(
                                       'DONE',
                                       style: TextStyle(
                                         color: colors.textPrimary,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                            loading: () => const SizedBox(),
                            error: (_, __) => const SizedBox(),
                          ),
                      ],
                    ),
                  ),
                ),
                // Module info
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          module.title.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 0.3,
                            color: colors.textPrimary,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Text(
                            module.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 10,
                              height: 1.4,
                            ),
                          ),
                        ),
                        if (completedAsync != null && totalLessons > 0) ...[
                          const SizedBox(height: 6),
                          completedAsync.when(
                            data: (completed) {
                              final done = module.lessonIds
                                  .where((id) => completed.contains(id))
                                  .length;
                              final isComplete = done == totalLessons;
                              return Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(3),
                                      child: LinearProgressIndicator(
                                        value: done / totalLessons,
                                        backgroundColor: isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.06,
                                              )
                                            : colors.surfaceAlt,
                                        valueColor: AlwaysStoppedAnimation(
                                          isComplete
                                              ? AppColors.successGreen
                                              : AppColors.amber,
                                        ),
                                        minHeight: 4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$done/$totalLessons',
                                    style: TextStyle(
                                      color: isComplete
                                          ? AppColors.successGreen
                                          : colors.textMuted,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              );
                            },
                            loading: () => const SizedBox(),
                            error: (_, __) => const SizedBox(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }
}

class _ModernTaskTile extends ConsumerWidget {
  final ApprenticeTask task;
  const _ModernTaskTile({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final bool isReview = task.status == ApprenticeTaskStatus.underReview;
    final bool isCompleted = task.status == ApprenticeTaskStatus.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isReview
            ? AppColors.amber.withValues(alpha: 0.05)
            : colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isReview
              ? AppColors.amber.withValues(alpha: 0.2)
              : colors.borderDefault,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (!isCompleted && !isReview) {
              ref.pushShell('/apprentice-task-submission', {'task': task});
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              _buildStatusIndicator(task.status, colors),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: isCompleted
                            ? colors.textHint
                            : colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isReview
                          ? 'AWAITING MENTOR VERIFICATION'
                          : 'DEADLINE: ${task.dueDate.day}/${task.dueDate.month}',
                      style: TextStyle(
                        color: isReview ? AppColors.amber : colors.textHint,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isCompleted && !isReview)
                const Icon(
                  Icons.add_circle_outline_rounded,
                  color: AppColors.amber,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(ApprenticeTaskStatus status, DesbyThemeColors colors) {
    IconData icon;
    Color color;
    switch (status) {
      case ApprenticeTaskStatus.completed:
        icon = Icons.check_circle_rounded;
        color = AppColors.successGreen;
        break;
      case ApprenticeTaskStatus.underReview:
        icon = Icons.hourglass_top_rounded;
        color = AppColors.amber;
        break;
      default:
        icon = Icons.pending_actions_rounded;
        color = colors.textMuted;
    }
    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
