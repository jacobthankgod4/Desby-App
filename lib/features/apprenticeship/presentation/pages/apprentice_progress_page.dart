import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desby_app/theme/colors.dart';
import 'package:desby_app/core/providers/navigation_provider.dart';
import '../../domain/entities/apprentice_task.dart';
import '../../domain/entities/apprentice_module.dart';
import '../providers/apprenticeship_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/widgets/shell_app_bar.dart';

class ApprenticeProgressPage extends ConsumerStatefulWidget {
  const ApprenticeProgressPage({super.key});

  @override
  ConsumerState<ApprenticeProgressPage> createState() =>
      _ApprenticeProgressPageState();
}

class _ApprenticeProgressPageState
    extends ConsumerState<ApprenticeProgressPage> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final user = ref.watch(currentUserProvider);
    final apprenticeId = user?.id ?? '';
    final apprenticeshipAsync = ref.watch(
      apprenticeApprenticeshipProvider(apprenticeId),
    );
    final tasksAsync = ref.watch(
      apprenticeshipTasksProvider(apprenticeshipAsync.valueOrNull?.id ?? ''),
    );
    final curriculumAsync = ref.watch(curriculumProvider);

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: shellAppBar(context, title: 'My Progress'),
      body: apprenticeshipAsync.when(
        data: (apprenticeship) {
          if (apprenticeship == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.school_outlined,
                    color: colors.iconMuted,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'NO ACADEMY ENROLLMENT',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Join an academy to track your progress',
                    style: TextStyle(color: colors.textHint, fontSize: 12),
                  ),
                ],
              ),
            );
          }

          return tasksAsync.when(
            data: (tasks) {
              final totalTasks = tasks.length;
              final completedTasks = tasks
                  .where((t) => t.status == ApprenticeTaskStatus.completed)
                  .length;
              final inProgressTasks = tasks
                  .where((t) => t.status == ApprenticeTaskStatus.inProgress)
                  .length;
              final underReviewTasks = tasks
                  .where((t) => t.status == ApprenticeTaskStatus.underReview)
                  .length;
              final skills = apprenticeship.skillIds.length;
              final curriculumProgress = apprenticeship.progress;
              final level = apprenticeship.level ?? 'Beginner';

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildHeroProgress(curriculumProgress, level, colors),
                    const SizedBox(height: 24),
                    _buildStatsGrid(
                      totalTasks,
                      completedTasks,
                      inProgressTasks + underReviewTasks,
                      skills,
                    ),
                    const SizedBox(height: 24),
                    if (curriculumAsync is AsyncData) ...[
                      _buildSectionHeader('CURRICULUM MODULES'),
                      const SizedBox(height: 12),
                      ...curriculumAsync.valueOrNull?.map(
                            (module) => _buildModuleProgress(
                              ref,
                              module,
                              apprenticeship.id,
                              colors,
                            ),
                          ) ??
                          [],
                      const SizedBox(height: 24),
                    ],
                    if (tasks.isNotEmpty) ...[
                      _buildSectionHeader('RECENT TASKS'),
                      const SizedBox(height: 12),
                      ...tasks
                          .take(5)
                          .map((task) => _buildTaskTile(task, colors)),
                    ],
                    const SizedBox(height: 100),
                  ],
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.amber),
            ),
            error: (err, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sync_problem_rounded,
                    color: colors.textMuted,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'SYNC ERROR',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Could not load tasks',
                    style: TextStyle(color: colors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => ref.invalidate(
                      apprenticeshipTasksProvider(apprenticeship.id),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.amber,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'RETRY',
                        style: TextStyle(
                          color: AppColors.darkNavy,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.amber),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sync_problem_rounded,
                color: colors.textMuted,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'SYNC ERROR',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Could not load progress',
                style: TextStyle(color: colors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroProgress(
    double progress,
    String level,
    DesbyThemeColors colors,
  ) {
    final percent = (progress * 100).toInt();
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.amber.withValues(alpha: 0.08), colors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 10,
                  backgroundColor: colors.divider,
                  valueColor: const AlwaysStoppedAnimation(AppColors.amber),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$percent%',
                    style: const TextStyle(
                      color: AppColors.amber,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'COMPLETE',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.amber,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'RANK: ${level.toUpperCase()}',
                  style: const TextStyle(
                    color: AppColors.amber,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$percent% of all curriculum lessons completed',
            style: TextStyle(color: colors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(int total, int completed, int active, int skills) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _buildStatCard(
          'TOTAL TASKS',
          '$total',
          Icons.assignment_rounded,
          AppColors.amber,
        ),
        _buildStatCard(
          'COMPLETED',
          '$completed',
          Icons.check_circle_rounded,
          AppColors.successGreen,
        ),
        _buildStatCard(
          'IN PROGRESS',
          '$active',
          Icons.pending_rounded,
          Colors.blue,
        ),
        _buildStatCard(
          'SKILLS',
          '$skills',
          Icons.star_rounded,
          AppColors.amber,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.amber,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildModuleProgress(
    WidgetRef ref,
    ApprenticeModule module,
    String apprenticeshipId,
    DesbyThemeColors colors,
  ) {
    final completedAsync = ref.watch(
      completedLessonsProvider(apprenticeshipId),
    );
    final totalLessons = module.lessonIds.length;

    return completedAsync.when(
      data: (completed) {
        final done = module.lessonIds
            .where((id) => completed.contains(id))
            .length;
        final progress = totalLessons > 0 ? done / totalLessons : 0.0;
        final isComplete = done == totalLessons;

        return GestureDetector(
          onTap: () => ref.pushShell('/module-detail', {'moduleId': module.id}),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isComplete
                  ? AppColors.successGreen.withValues(alpha: 0.05)
                  : colors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isComplete
                    ? AppColors.successGreen.withValues(alpha: 0.2)
                    : colors.cardBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isComplete
                            ? AppColors.successGreen.withValues(alpha: 0.15)
                            : AppColors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: isComplete
                            ? const Icon(
                                Icons.check_rounded,
                                color: AppColors.successGreen,
                                size: 18,
                              )
                            : Icon(
                                Icons.menu_book_rounded,
                                color: AppColors.amber.withValues(alpha: 0.7),
                                size: 16,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            module.title.toUpperCase(),
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$done of $totalLessons lessons',
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        color: isComplete
                            ? AppColors.successGreen
                            : AppColors.amber,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: colors.divider,
                    valueColor: AlwaysStoppedAnimation(
                      isComplete ? AppColors.successGreen : AppColors.amber,
                    ),
                    minHeight: 4,
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

  Widget _buildTaskTile(ApprenticeTask task, DesbyThemeColors colors) {
    Color statusColor;
    IconData statusIcon;
    String statusLabel;
    switch (task.status) {
      case ApprenticeTaskStatus.completed:
        statusColor = AppColors.successGreen;
        statusIcon = Icons.check_circle_rounded;
        statusLabel = 'COMPLETED';
        break;
      case ApprenticeTaskStatus.inProgress:
        statusColor = Colors.blue;
        statusIcon = Icons.play_circle_rounded;
        statusLabel = 'IN PROGRESS';
        break;
      case ApprenticeTaskStatus.underReview:
        statusColor = Colors.orange;
        statusIcon = Icons.rate_review_rounded;
        statusLabel = 'UNDER REVIEW';
        break;
      case ApprenticeTaskStatus.failed:
        statusColor = Colors.red;
        statusIcon = Icons.cancel_rounded;
        statusLabel = 'FAILED';
        break;
      default:
        statusColor = colors.textMuted;
        statusIcon = Icons.radio_button_unchecked;
        statusLabel = 'PENDING';
    }

    return GestureDetector(
      onTap: () => ref.pushShell('/apprentice-task-submission', {'task': task}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: statusColor.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(statusIcon, color: statusColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            if (task.score != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${task.score!.toInt()}%',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
