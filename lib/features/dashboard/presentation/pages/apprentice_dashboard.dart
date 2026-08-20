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

class ApprenticeDashboard extends ConsumerStatefulWidget {
  const ApprenticeDashboard({super.key});

  @override
  ConsumerState<ApprenticeDashboard> createState() => _ApprenticeDashboardState();
}

class _ApprenticeDashboardState extends ConsumerState<ApprenticeDashboard> {
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final userId = currentUser?.id ?? '';
    final apprenticeshipAsync = ref.watch(apprenticeApprenticeshipProvider(userId));

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
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
                  AnimatedEntry(index: 0, child: _buildHeader(currentUser?.name)),
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
                  const SizedBox(height: 24),

                  // Mentor Access
                  AnimatedEntry(index: 3, child: _buildMentorHUD(apprenticeship.tailorId)),
                  const SizedBox(height: 32),

                  // Task Queue
                  AnimatedEntry(
                    index: 4,
                    child: _buildSectionHeader('My Tasks', '/tasks'),
                  ),
                  const SizedBox(height: 16),
                  AnimatedEntry(index: 5, child: _buildTasksManifest(ref, apprenticeship.id)),

                  const SizedBox(height: 32),

                  // Curriculum Sync
                  AnimatedEntry(
                    index: 6,
                    child: _buildSectionHeader('Learning Modules', '/curriculum'),
                  ),
                  const SizedBox(height: 16),
                  AnimatedEntry(index: 7, child: _buildCurriculumHUD(ref)),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
          loading: () => DashboardShimmer(statCount: 2, listCount: 3),
          error: (error, _) => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school_rounded, color: Colors.white10, size: 48),
                SizedBox(height: 12),
                Text('ACADEMY SYNC FAILED', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoSessionState() {
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
            child: const Icon(Icons.school_rounded, color: AppColors.amber, size: 48),
          ),
          const SizedBox(height: 24),
          const Text('NO ACTIVE COURSE', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2)),
          const SizedBox(height: 8),
          Text('Contact your mentor to get started', style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildHeader(String? name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ACADEMY', style: TextStyle(color: AppColors.amber, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 2)),
        const SizedBox(height: 4),
        Text(
          'Hello, ${name ?? 'Apprentice'}',
          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
      ],
    );
  }

  Widget _buildMentorHUD(String tailorId) {
    return _MentorCard(tailorId: tailorId);
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
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amber, strokeWidth: 2)),
      error: (e, _) => _buildEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'SYNC ERROR',
        subtitle: 'Pull down to retry',
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return LuxuryGlassCard(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Icon(icon, color: Colors.white10, size: 36),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: Colors.white10, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.15), fontSize: 10)),
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
          children: modules.take(3).map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _CurriculumTile(title: m.title),
          )).toList(),
        );
      },
      loading: () => DashboardShimmer(listCount: 2),
      error: (e, _) => const SizedBox(),
    );
  }

  Widget _buildSectionHeader(String title, String route) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white38)),
        GestureDetector(
          onTap: () => ref.setShell(route),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('VIEW ALL', style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
          ),
        ),
      ],
    );
  }
}

class _MentorCard extends StatefulWidget {
  final String tailorId;
  const _MentorCard({required this.tailorId});

  @override
  State<_MentorCard> createState() => _MentorCardState();
}

class _MentorCardState extends State<_MentorCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
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
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: _isHovered
                    ? AppColors.amber.withValues(alpha: 0.15)
                    : AppColors.amber.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_pin_rounded, color: AppColors.amber),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MASTER MENTOR', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
                  Text('Atelier Direct Access', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.forum_rounded, color: AppColors.amber, size: 20),
              onPressed: () {
                Navigator.of(context).pushNamed('/chats');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final dynamic task;
  const _TaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    final bool isReview = task.status == ApprenticeTaskStatus.underReview;
    final bool isCompleted = task.status == ApprenticeTaskStatus.completed;

    return LuxuryGlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle_rounded : isReview ? Icons.hourglass_empty_rounded : Icons.pending_rounded,
            color: isCompleted ? const Color(0xFF00FF7F) : isReview ? AppColors.amber : Colors.white24,
            size: 18,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
                Text(
                  isReview ? 'PENDING VALIDATION' : 'DEADLINE: ${task.dueDate.day}/${task.dueDate.month}',
                  style: TextStyle(color: isReview ? AppColors.amber : Colors.white24, fontSize: 8, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white10, size: 12),
        ],
      ),
    );
  }
}

class _CurriculumTile extends StatefulWidget {
  final String title;
  const _CurriculumTile({required this.title});

  @override
  State<_CurriculumTile> createState() => _CurriculumTileState();
}

class _CurriculumTileState extends State<_CurriculumTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: LuxuryGlassCard(
        padding: const EdgeInsets.all(4),
        borderColor: _isHovered ? Colors.purpleAccent.withValues(alpha: 0.2) : null,
        child: ListTile(
          leading: Icon(
            Icons.bookmark_rounded,
            color: _isHovered ? Colors.purpleAccent : Colors.purpleAccent.withValues(alpha: 0.7),
            size: 20,
          ),
          title: Text(widget.title.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
          trailing: Icon(
            _isHovered ? Icons.chevron_right_rounded : Icons.chevron_right_rounded,
            color: _isHovered ? Colors.purpleAccent : Colors.white24,
            size: 16,
          ),
        ),
      ),
    );
  }
}
