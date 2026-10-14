import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desby_app/theme/colors.dart';
import 'package:desby_app/core/providers/navigation_provider.dart';
import '../../domain/entities/apprentice_task.dart';
import '../providers/apprenticeship_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/academy_card.dart';

class ApprenticeTasksPage extends ConsumerWidget {
  const ApprenticeTasksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final user = ref.watch(currentUserProvider);
    final apprenticeId = user?.id ?? '';
    final apprenticeshipAsync = ref.watch(
      apprenticeApprenticeshipProvider(apprenticeId),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Text(
                'MY TASKS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: colors.textHint,
                ),
              ),
            ),
          ),
          apprenticeshipAsync.when(
            data: (apprenticeship) {
              if (apprenticeship == null) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          color: colors.iconMuted,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'NO ACADEMY ENROLLMENT',
                          style: TextStyle(
                            color: colors.textHint,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Join an academy to receive tasks',
                          style: TextStyle(
                            color: colors.textHint,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final tasksAsync = ref.watch(
                apprenticeshipTasksProvider(apprenticeship.id),
              );
              return tasksAsync.when(
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.task_alt_rounded,
                              color: colors.iconMuted,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'NO TASKS YET',
                              style: TextStyle(
                                color: colors.textHint,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your mentor will assign tasks here',
                              style: TextStyle(
                                color: colors.textHint,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final pending = tasks
                      .where(
                        (t) =>
                            t.status == ApprenticeTaskStatus.todo ||
                            t.status == ApprenticeTaskStatus.inProgress,
                      )
                      .toList();
                  final underReview = tasks
                      .where(
                        (t) => t.status == ApprenticeTaskStatus.underReview,
                      )
                      .toList();
                  final completed = tasks
                      .where((t) => t.status == ApprenticeTaskStatus.completed)
                      .toList();

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (pending.isNotEmpty) ...[
                          _buildSectionHeader(
                            context,
                            'IN PROGRESS',
                            pending.length,
                          ),
                          const SizedBox(height: 12),
                          ...pending.map(
                            (t) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _TaskTile(task: t),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        if (underReview.isNotEmpty) ...[
                          _buildSectionHeader(
                            context,
                            'UNDER REVIEW',
                            underReview.length,
                          ),
                          const SizedBox(height: 12),
                          ...underReview.map(
                            (t) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _TaskTile(task: t),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        if (completed.isNotEmpty) ...[
                          _buildSectionHeader(
                            context,
                            'COMPLETED',
                            completed.length,
                          ),
                          const SizedBox(height: 12),
                          ...completed.map(
                            (t) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _TaskTile(task: t),
                            ),
                          ),
                        ],
                      ]),
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.amber),
                  ),
                ),
                error: (err, _) => SliverFillRemaining(
                  child: Center(
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
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () => ref.invalidate(
                            apprenticeshipTasksProvider(apprenticeship.id),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 10,
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
                                fontSize: 11,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.amber),
              ),
            ),
            error: (err, _) => SliverFillRemaining(
              child: Center(
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
                      'Could not load your academy data',
                      style: TextStyle(color: colors.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => ref.invalidate(
                        apprenticeApprenticeshipProvider(apprenticeId),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 10,
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
                            fontSize: 11,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    final colors = context.colors;
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: colors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: AppColors.amber,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _TaskTile extends ConsumerWidget {
  final ApprenticeTask task;
  const _TaskTile({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final bool isReview = task.status == ApprenticeTaskStatus.underReview;
    final bool isCompleted = task.status == ApprenticeTaskStatus.completed;

    return AcademyCard(
      accentColor: isReview ? AppColors.amber : null,
      isGlowing: isReview,
      onTap: () {
        if (!isCompleted && !isReview) {
          ref.pushShell('/apprentice-task-submission', {'task': task});
        }
      },
      child: Row(
        children: [
          _buildStatusIndicator(context, task.status),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted ? colors.textMuted : colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isReview
                      ? 'AWAITING MENTOR VERIFICATION'
                      : 'DEADLINE: ${task.dueDate.day}/${task.dueDate.month}',
                  style: TextStyle(
                    color: isReview ? AppColors.amber : colors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          if (task.score != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${task.score!.toInt()}%',
                style: TextStyle(
                  color: AppColors.successGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
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
    );
  }

  Widget _buildStatusIndicator(BuildContext context, ApprenticeTaskStatus status) {
    final colors = context.colors;
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
      case ApprenticeTaskStatus.inProgress:
        icon = Icons.play_circle_rounded;
        color = Colors.blueAccent;
        break;
      default:
        icon = Icons.pending_actions_rounded;
        color = colors.textMuted;
    }

    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}
