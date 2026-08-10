import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/academy_card.dart';
import '../widgets/curriculum_progress_hud.dart';
import '../../domain/entities/apprentice_task.dart';
import '../providers/apprenticeship_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'apprentice_lesson_detail_page.dart';
import 'apprentice_task_submission_page.dart';
import '../../../../theme/colors.dart';
import '../../../../core/widgets/error_state_widget.dart';

class ApprenticeLearningPage extends ConsumerWidget {
  const ApprenticeLearningPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final apprenticeId = currentUser?.id ?? '';
    final apprenticeshipAsync = ref.watch(apprenticeApprenticeshipProvider(apprenticeId));
    final curriculumAsync = ref.watch(curriculumProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. MODERN HERO HUD
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 32),
              child: apprenticeshipAsync.when(
                data: (app) => CurriculumProgressHud(
                  progress: app?.progress ?? 0.0,
                  level: 'Rank: Intermediate',
                  nextTarget: 'Structural Draping',
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => const SizedBox(),
              ),
            ),
          ),

          // 2. CURRICULUM SECTION
          _buildSliverHeader('ACADEMY SYLLABUS'),
          curriculumAsync.when(
            data: (modules) => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _ModernModuleCard(module: modules[index]),
                  childCount: modules.length,
                ),
              ),
            ),
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            error: (err, _) => const SliverToBoxAdapter(child: ErrorStateWidget(message: 'Could not load curriculum.')),
          ),

          // 3. TASKS SECTION
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
          _buildSliverHeader('OPERATIONAL TASKS'),
          _buildTasksSliver(ref, apprenticeId),
          
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSliverHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Colors.white24,
          ),
        ),
      ),
    );
  }

  Widget _buildTasksSliver(WidgetRef ref, String apprenticeId) {
    final apprenticeshipAsync = ref.watch(apprenticeApprenticeshipProvider(apprenticeId));

    return apprenticeshipAsync.when(
      data: (apprenticeship) {
        if (apprenticeship == null) return const SliverToBoxAdapter(child: SizedBox());
        final tasksAsync = ref.watch(apprenticeshipTasksProvider(apprenticeship.id));
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

class _ModernModuleCard extends StatelessWidget {
  final dynamic module;
  const _ModernModuleCard({required this.module});

  @override
  Widget build(BuildContext context) {
    return AcademyCard(
      onTap: () {
        if (module.lessonIds.isNotEmpty) {
           Navigator.push(context, MaterialPageRoute(builder: (context) => ApprenticeLessonDetailPage(lessonId: module.lessonIds.first)));
        }
      },
      child: Row(
        children: [
          Container(
            height: 60, width: 60,
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.menu_book_rounded, color: AppColors.amber),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(module.title.toUpperCase(), 
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(module.description, 
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white38, fontSize: 11, height: 1.4)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white10, size: 14),
        ],
      ),
    );
  }
}

class _ModernTaskTile extends StatelessWidget {
  final ApprenticeTask task;
  const _ModernTaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    final bool isReview = task.status == ApprenticeTaskStatus.underReview;
    final bool isCompleted = task.status == ApprenticeTaskStatus.completed;

    return AcademyCard(
      accentColor: isReview ? AppColors.amber : null,
      isGlowing: isReview,
      onTap: () {
        if (!isCompleted && !isReview) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ApprenticeTaskSubmissionPage(task: task)));
        }
      },
      child: Row(
        children: [
          _buildStatusIndicator(task.status),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title.toUpperCase(), 
                  style: TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 12, 
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted ? Colors.white24 : Colors.white,
                  )),
                const SizedBox(height: 4),
                Text(
                  isReview ? 'AWAITING MASTER VERIFICATION' : 'DEADLINE: ${task.dueDate.day}/${task.dueDate.month}',
                  style: TextStyle(
                    color: isReview ? AppColors.amber : Colors.white24, 
                    fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          if (!isCompleted && !isReview)
            const Icon(Icons.add_circle_outline_rounded, color: AppColors.amber, size: 20),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(ApprenticeTaskStatus status) {
    IconData icon;
    Color color;
    switch (status) {
      case ApprenticeTaskStatus.completed:
        icon = Icons.check_circle_rounded;
        color = const Color(0xFF00FF7F);
        break;
      case ApprenticeTaskStatus.underReview:
        icon = Icons.hourglass_top_rounded;
        color = AppColors.amber;
        break;
      default:
        icon = Icons.pending_actions_rounded;
        color = Colors.white12;
    }

    return Container(
      height: 48, width: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
