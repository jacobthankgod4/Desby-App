import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/luxury_stat_card.dart';
import 'package:desby_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:desby_app/features/apprenticeship/presentation/providers/apprenticeship_provider.dart';
import 'package:desby_app/features/apprenticeship/domain/entities/apprentice_task.dart';
import 'package:desby_app/core/widgets/luxury_glass_card.dart';
import 'package:desby_app/core/widgets/animated_entry.dart';
import 'package:desby_app/core/widgets/dashboard_shimmer.dart';
import 'package:desby_app/core/providers/navigation_provider.dart';
import '../../../../theme/colors.dart';
import '../widgets/quick_action_tile.dart';

class ApprenticeDashboard extends ConsumerStatefulWidget {
  const ApprenticeDashboard({super.key});

  @override
  ConsumerState<ApprenticeDashboard> createState() =>
      _ApprenticeDashboardState();
}

class _ApprenticeDashboardState extends ConsumerState<ApprenticeDashboard> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final currentUser = ref.watch(currentUserProvider);
    final userId = currentUser?.id ?? '';
    final apprenticeshipAsync = ref.watch(
      apprenticeApprenticeshipProvider(userId),
    );

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(apprenticeApprenticeshipProvider(userId));
        },
        color: AppColors.amber,
        child: apprenticeshipAsync.when(
          data: (apprenticeship) {
            if (apprenticeship == null) {
              return _buildNoSessionState();
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedEntry(
                    index: 0,
                    child: _buildHeader(currentUser?.name),
                  ),
                  const SizedBox(height: 24),

                  // Craft Mastery HUD
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      AnimatedEntry(
                        index: 1,
                        child: LuxuryStatCard(
                          title: 'Learning Sync',
                          value: '${(apprenticeship.progress * 100).toInt()}%',
                          icon: Icons.school_rounded,
                          color: Colors.purpleAccent,
                        ),
                      ),
                      AnimatedEntry(
                        index: 2,
                        child: LuxuryStatCard(
                          title: 'Skill Badges',
                          value: '${apprenticeship.skillIds.length}',
                          icon: Icons.verified_rounded,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // QUICK ACTIONS — the apprentice dashboard previously had a
                  // GridView, but every child was a non-tappable
                  // LuxuryStatCard, so there was no tile grid anywhere on the
                  // page and the curriculum had to be reached via a header chip.
                  AnimatedEntry(index: 3, child: _buildQuickActions()),
                  const SizedBox(height: 32),

                  // Mentor Access
                  AnimatedEntry(
                    index: 3,
                    child: _buildMentorHUD(
                      apprenticeship.tailorId,
                      apprenticeship.tailorProfile?.name,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Task Queue
                  AnimatedEntry(
                    index: 4,
                    child: _buildSectionHeader('My Tasks', '/tasks'),
                  ),
                  const SizedBox(height: 16),
                  AnimatedEntry(
                    index: 5,
                    child: _buildTasksManifest(ref, apprenticeship.id),
                  ),

                  const SizedBox(height: 32),

                  // Curriculum Sync
                  AnimatedEntry(
                    index: 6,
                    child: _buildSectionHeader(
                      'Learning Modules',
                      '/curriculum',
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedEntry(index: 7, child: _buildCurriculumHUD(ref)),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
          loading: () => DashboardShimmer(statCount: 2, listCount: 3),
          error: (error, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colors.textMuted.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.sync_problem_rounded,
                    color: colors.textMuted,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'SYNC ERROR',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Could not load academy data',
                  style: TextStyle(color: colors.textMuted, fontSize: 11),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () =>
                      ref.invalidate(apprenticeApprenticeshipProvider(userId)),
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
    );
  }

  Widget _buildNoSessionState() {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.school_rounded,
              color: AppColors.amber,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'NO ACTIVE COURSE',
            style: TextStyle(
              color: colors.textMuted,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Contact your mentor to get started',
            style: TextStyle(color: colors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String? name) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ACADEMY',
          style: TextStyle(
            color: AppColors.amber,
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Hello, ${name ?? 'Apprentice'}',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  /// Apprentice quick actions. All routes already exist in the shell switch.
  Widget _buildQuickActions() {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossCount = screenWidth < 600 ? 3 : 4;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const QuickActionsHeading(),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: crossCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.92,
          children: [
            QuickActionTile(
              icon: Icons.menu_book_rounded,
              label: 'Curriculum',
              onTap: () => ref.setShell('/curriculum'),
              index: 0,
            ),
            QuickActionTile(
              icon: Icons.task_alt_rounded,
              label: 'My Tasks',
              onTap: () => ref.setShell('/tasks'),
              index: 1,
            ),
            QuickActionTile(
              icon: Icons.workspace_premium_rounded,
              label: 'Badges',
              onTap: () => ref.setShell('/badges'),
              index: 2,
            ),
            QuickActionTile(
              icon: Icons.trending_up_rounded,
              label: 'Progress',
              onTap: () => ref.setShell('/progress'),
              index: 3,
            ),
            QuickActionTile(
              icon: Icons.school_rounded,
              label: 'Masterclass',
              onTap: () => ref.setShell('/masterclass'),
              index: 4,
            ),
            QuickActionTile(
              icon: Icons.folder_copy_rounded,
              label: 'Portfolio',
              onTap: () => ref.setShell('/portfolio'),
              index: 5,
            ),
            QuickActionTile(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Mentor Chat',
              onTap: () => ref.pushShell('/chats'),
              index: 6,
            ),
            QuickActionTile(
              icon: Icons.forum_rounded,
              label: 'Showcase',
              onTap: () => ref.setShell('/showcase'),
              index: 7,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMentorHUD(String tailorId, String? tailorName) {
    return _MentorCard(
      tailorId: tailorId,
      tailorName: tailorName,
      onChatTap: () => ref.pushShell('/chats'),
    );
  }

  Widget _buildTasksManifest(WidgetRef ref, String apprenticeshipId) {
    final tasksAsync = ref.watch(apprenticeshipTasksProvider(apprenticeshipId));
    return tasksAsync.when(
      data: (tasks) {
        if (tasks.isEmpty) {
          return _buildEmptyState(
            icon: Icons.task_alt_rounded,
            title: 'QUEUE CLEAR',
            subtitle: 'No pending tasks',
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tasks.length > 3 ? 3 : tasks.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final task = tasks[index];
            return _TaskTile(task: task);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: AppColors.amber,
          strokeWidth: 2,
        ),
      ),
      error: (e, _) => LuxuryGlassCard(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.sync_problem_rounded,
                color: AppColors.textMuted,
                size: 32,
              ),
              const SizedBox(height: 12),
              const Text(
                'SYNC ERROR',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Could not load tasks',
                style: TextStyle(color: AppColors.textMuted, fontSize: 10),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => ref.invalidate(
                  apprenticeshipTasksProvider(apprenticeshipId),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.amber,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'RETRY',
                    style: TextStyle(
                      color: AppColors.darkNavy,
                      fontWeight: FontWeight.w900,
                      fontSize: 9,
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
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final colors = context.colors;
    return LuxuryGlassCard(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Icon(icon, color: colors.textMuted, size: 36),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: colors.textMuted,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: colors.textMuted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurriculumHUD(WidgetRef ref) {
    final curriculumAsync = ref.watch(curriculumProvider);
    return curriculumAsync.when(
      data: (modules) {
        if (modules.isEmpty) {
          return _buildEmptyState(
            icon: Icons.menu_book_rounded,
            title: 'NO MODULES',
            subtitle: 'Curriculum will appear here',
          );
        }
        return Column(
          children: modules
              .take(3)
              .map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _CurriculumTile(title: m.title, moduleId: m.id),
                ),
              )
              .toList(),
        );
      },
      loading: () => DashboardShimmer(listCount: 2),
      error: (e, _) => const SizedBox(),
    );
  }

  Widget _buildSectionHeader(String title, String route) {
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: colors.textMuted,
          ),
        ),
        GestureDetector(
          onTap: () => ref.setShell(route),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'VIEW ALL',
              style: TextStyle(
                color: AppColors.amber,
                fontWeight: FontWeight.w900,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MentorCard extends StatefulWidget {
  final String tailorId;
  final String? tailorName;
  final VoidCallback? onChatTap;
  const _MentorCard({required this.tailorId, this.tailorName, this.onChatTap});

  @override
  State<_MentorCard> createState() => _MentorCardState();
}

class _MentorCardState extends State<_MentorCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final displayName = widget.tailorName ?? 'MENTOR';
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: LuxuryGlassCard(
        padding: const EdgeInsets.all(20),
        borderColor: _isHovered ? AppColors.amber.withValues(alpha: 0.2) : null,
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _isHovered
                    ? AppColors.amber.withValues(alpha: 0.15)
                    : AppColors.amber.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_pin_rounded,
                color: AppColors.amber,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName.toUpperCase(),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Atelier Direct Access',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.forum_rounded,
                color: AppColors.amber,
                size: 20,
              ),
              onPressed: widget.onChatTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final ApprenticeTask task;
  const _TaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bool isReview = task.status == ApprenticeTaskStatus.underReview;
    final bool isCompleted = task.status == ApprenticeTaskStatus.completed;

    return LuxuryGlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            isCompleted
                ? Icons.check_circle_rounded
                : isReview
                ? Icons.hourglass_empty_rounded
                : Icons.pending_rounded,
            color: isCompleted
                ? AppColors.successGreen
                : isReview
                ? AppColors.amber
                : colors.textMuted,
            size: 18,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title.toUpperCase(),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
                Text(
                  isReview
                      ? 'PENDING VALIDATION'
                      : 'DEADLINE: ${task.dueDate.day}/${task.dueDate.month}',
                  style: TextStyle(
                    color: isReview ? AppColors.amber : colors.textMuted,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: colors.textMuted,
            size: 12,
          ),
        ],
      ),
    );
  }
}

class _CurriculumTile extends StatefulWidget {
  final String title;
  final String moduleId;
  const _CurriculumTile({required this.title, required this.moduleId});

  @override
  State<_CurriculumTile> createState() => _CurriculumTileState();
}

class _CurriculumTileState extends State<_CurriculumTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Consumer(
        builder: (context, ref, _) => GestureDetector(
          onTap: () =>
              ref.pushShell('/module-detail', {'moduleId': widget.moduleId}),
          child: LuxuryGlassCard(
            padding: const EdgeInsets.all(4),
            borderColor: _isHovered
                ? Colors.purpleAccent.withValues(alpha: 0.2)
                : null,
            child: ListTile(
              leading: Icon(
                Icons.bookmark_rounded,
                color: _isHovered
                    ? Colors.purpleAccent
                    : Colors.purpleAccent.withValues(alpha: 0.7),
                size: 20,
              ),
              title: Text(
                widget.title.toUpperCase(),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: _isHovered ? Colors.purpleAccent : colors.textMuted,
                size: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
