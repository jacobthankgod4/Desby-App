import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desby_app/features/apprenticeship/domain/entities/apprentice_task.dart';
import 'package:desby_app/features/apprenticeship/presentation/providers/apprenticeship_provider.dart';
import 'package:desby_app/features/auth/presentation/providers/auth_provider.dart';
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

    final curriculumAsync = ref.watch(curriculumProvider);

    return CustomScrollView(
      slivers: [
        _buildHeroSection(context, currentUser?.name ?? 'Apprentice'),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        _buildSectionHeader('Current Curriculum'),
        curriculumAsync.when(
          data: (modules) => SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _ModuleCard(module: modules[index]),
              childCount: modules.length,
            ),
          ),
          loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
          error: (err, _) => const SliverToBoxAdapter(child: ErrorStateWidget(message: 'Could not load curriculum.')),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
        _buildSectionHeader('My Tasks'),
        _buildTasksSection(ref, apprenticeId),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _buildHeroSection(BuildContext context, String name) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.darkNavy,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mastering the Craft, $name',
              style: const TextStyle(color: AppColors.amber, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Continue your journey to becoming a master tailor.',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const LinearProgressIndicator(
              value: 0.45,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.amber),
              minHeight: 12,
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Level 2: Intermediate Sewing', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text('45%', style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildTasksSection(WidgetRef ref, String apprenticeId) {
    final apprenticeshipAsync = ref.watch(apprenticeApprenticeshipProvider(apprenticeId));

    return apprenticeshipAsync.when(
      data: (apprenticeship) {
        if (apprenticeship == null) return const SliverToBoxAdapter(child: Center(child: Text('No active apprenticeship')));
        final tasksAsync = ref.watch(apprenticeshipTasksProvider(apprenticeship.id));
        return tasksAsync.when(
          data: (tasks) => SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _TaskTile(task: tasks[index]),
              childCount: tasks.length,
            ),
          ),
          loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
          error: (err, _) => const SliverToBoxAdapter(child: ErrorStateWidget(message: 'Could not load your tasks.')),
        );
      },
      loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
      error: (err, _) => const SliverToBoxAdapter(child: ErrorStateWidget(message: 'Could not load apprenticeship info.')),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final dynamic module;
  const _ModuleCard({required this.module});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.menu_book, color: AppColors.amber),
        ),
        title: Text(module.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(module.description),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ApprenticeLessonDetailPage(lessonId: module.lessonIds.first),
            ),
          );
        },
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isReview ? AppColors.amber.withValues(alpha: 0.3) : Colors.white10),
      ),
      child: ListTile(
        onTap: () {
          if (!isCompleted && !isReview) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ApprenticeTaskSubmissionPage(task: task),
              ),
            );
          }
        },
        leading: Icon(
          isCompleted ? Icons.check_circle_rounded : isReview ? Icons.hourglass_top_rounded : Icons.pending_actions_rounded,
          color: isCompleted ? const Color(0xFF00FF7F) : isReview ? AppColors.amber : Colors.white24,
        ),
        title: Text(
          task.title.toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
        subtitle: Text(
          isReview ? 'AWAITING MENTOR REVIEW' : 'DUE: ${task.dueDate.day}/${task.dueDate.month}',
          style: TextStyle(color: isReview ? AppColors.amber : Colors.white24, fontSize: 9, fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white10, size: 12),
      ),
    );
  }
}
