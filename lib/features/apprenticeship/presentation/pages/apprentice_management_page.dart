import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desby_app/features/apprenticeship/domain/entities/apprentice_task.dart';
import 'package:desby_app/features/apprenticeship/presentation/providers/apprenticeship_provider.dart';
import '../widgets/create_task_dialog.dart';
import 'package:desby_app/features/auth/presentation/providers/auth_provider.dart';
import '../../../../theme/colors.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../domain/entities/apprenticeship.dart';

class ApprenticeManagementPage extends ConsumerWidget {
  const ApprenticeManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final currentUser = ref.watch(currentUserProvider);
    final tailorId = currentUser?.id ?? '';

    final apprenticeshipsAsync = ref.watch(
      tailorApprenticeshipsProvider(tailorId),
    );

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: apprenticeshipsAsync.when(
        data: (apprenticeships) {
          final pending = apprenticeships
              .where(
                (a) => a.status == ApprenticeshipStatus.awaitingMasterApproval,
              )
              .toList();
          final active = apprenticeships
              .where((a) => a.status == ApprenticeshipStatus.active)
              .toList();

          return CustomScrollView(
            slivers: [
              if (pending.isNotEmpty) ...[
                _buildSectionTitle('Enrollment Requests', colors),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _PendingRequestCard(apprenticeship: pending[index]),
                    childCount: pending.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
              _buildSectionTitle('Active Apprentices', colors),
              if (active.isEmpty && pending.isEmpty)
                SliverFillRemaining(child: _buildEmptyState(context))
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _ApprenticeCard(apprenticeship: active[index]),
                    childCount: active.length,
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.amber),
        ),
        error: (error, _) =>
            const ErrorStateWidget(message: 'Failed to sync academy database.'),
      ),
    );
  }

  Widget _buildSectionTitle(String title, DesbyThemeColors colors) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            color: colors.textHint,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 64, color: colors.iconMuted),
          const SizedBox(height: 16),
          Text(
            'No Active Apprenticeships',
            style: TextStyle(
              color: colors.textMuted,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingRequestCard extends ConsumerWidget {
  final Apprenticeship apprenticeship;
  const _PendingRequestCard({required this.apprenticeship});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final profile = apprenticeship.apprenticeProfile;
    final name =
        profile?.name ??
        'Candidate ${apprenticeship.apprenticeId.substring(0, 5)}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.amber,
            backgroundImage: profile?.profileImage != null
                ? NetworkImage(profile!.profileImage!)
                : null,
            child: profile?.profileImage == null
                ? Icon(Icons.person, color: colors.textPrimary)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'New Apprentice Invite Request',
                  style: TextStyle(
                    color: AppColors.amber,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  name,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              final updated = apprenticeship.copyWith(
                status: ApprenticeshipStatus.active,
              );
              await ref
                  .read(apprenticeshipRepositoryProvider)
                  .updateApprenticeship(updated);
              ref.invalidate(
                tailorApprenticeshipsProvider(apprenticeship.tailorId),
              );
            },
            icon: const Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.green,
            ),
          ),
          IconButton(
            onPressed: () async {
              final updated = apprenticeship.copyWith(
                status: ApprenticeshipStatus.terminated,
              );
              await ref
                  .read(apprenticeshipRepositoryProvider)
                  .updateApprenticeship(updated);
              ref.invalidate(
                tailorApprenticeshipsProvider(apprenticeship.tailorId),
              );
            },
            icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }
}

class _ApprenticeCard extends ConsumerWidget {
  final Apprenticeship apprenticeship;
  const _ApprenticeCard({required this.apprenticeship});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final profile = apprenticeship.apprenticeProfile;
    final name =
        profile?.name ??
        'Apprentice ${apprenticeship.apprenticeId.substring(0, 5)}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.cardBorder),
      ),
      child: InkWell(
        onTap: () {
          ref.pushShell('/apprentice-detail', {
            'apprenticeId': apprenticeship.apprenticeId,
            'apprenticeshipId': apprenticeship.id,
          });
        },
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: colors.inputFill,
                  backgroundImage: profile?.profileImage != null
                      ? NetworkImage(profile!.profileImage!)
                      : null,
                  child: profile?.profileImage == null
                      ? Icon(Icons.person_outline, color: colors.textSecondary)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Master-in-Training',
                        style: TextStyle(
                          color: AppColors.amber,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        name,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_task_rounded,
                    color: AppColors.amber,
                    size: 20,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) =>
                          CreateTaskDialog(apprenticeshipId: apprenticeship.id),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: colors.iconMuted,
                    size: 20,
                  ),
                  onPressed: () {
                    ref.pushShell('/chat-detail', {
                      'peerId': apprenticeship.apprenticeId,
                      'conversationId': 'apprentice_${apprenticeship.id}',
                    });
                  },
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: colors.iconMuted,
                    size: 20,
                  ),
                  onSelected: (value) async {
                    if (value == 'terminate') {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: colors.dialogBg,
                          title: Text(
                            'Terminate Apprenticeship?',
                            style: TextStyle(color: colors.textPrimary),
                          ),
                          content: Text(
                            'This will permanently end $name\'s apprenticeship.',
                            style: TextStyle(color: colors.textSecondary),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text(
                                'Terminate',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        final updated = apprenticeship.copyWith(
                          status: ApprenticeshipStatus.terminated,
                        );
                        await ref
                            .read(apprenticeshipRepositoryProvider)
                            .updateApprenticeship(updated);
                        ref.invalidate(
                          tailorApprenticeshipsProvider(
                            apprenticeship.tailorId,
                          ),
                        );
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'terminate',
                      child: Text(
                        'Terminate',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildTaskReviewSection(ref, context),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mastery Progress',
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${(apprenticeship.progress * 100).toInt()}%',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: apprenticeship.progress,
              backgroundColor: colors.divider,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.amber),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskReviewSection(WidgetRef ref, BuildContext context) {
    final colors = context.colors;
    final tasksAsync = ref.watch(
      apprenticeshipTasksProvider(apprenticeship.id),
    );
    return tasksAsync.when(
      data: (tasks) {
        final reviewable = tasks
            .where((t) => t.status == ApprenticeTaskStatus.underReview)
            .toList();
        if (reviewable.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Divider(color: colors.divider, height: 1),
            const SizedBox(height: 16),
            Text(
              '${reviewable.length} SUBMISSIONS AWAITING REVIEW',
              style: TextStyle(
                color: AppColors.amber,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            ...reviewable.map((t) => _buildReviewItem(ref, t, context)),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
    );
  }

  Widget _buildReviewItem(
    WidgetRef ref,
    ApprenticeTask task,
    BuildContext context,
  ) {
    final colors = context.colors;
    return InkWell(
      onTap: () {
        ref.pushShell('/apprentice-task-grading', {'task': task});
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.inputFill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.history_edu_rounded,
              color: AppColors.amber,
              size: 16,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                task.title.toUpperCase(),
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: colors.iconMuted,
              size: 10,
            ),
          ],
        ),
      ),
    );
  }
}
