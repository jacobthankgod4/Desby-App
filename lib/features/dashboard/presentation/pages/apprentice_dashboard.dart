import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/stat_card.dart';
import '../widgets/desktop_dashboard_shell.dart';
import 'package:desby_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:desby_app/features/apprenticeship/presentation/providers/apprenticeship_provider.dart';
import "package:desby_app/features/apprenticeship/domain/entities/apprentice_task.dart";
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../theme/colors.dart';

class ApprenticeDashboard extends ConsumerWidget {
  const ApprenticeDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final userId = currentUser?.id ?? '';

    final apprenticeshipAsync = ref.watch(apprenticeApprenticeshipProvider(userId));

    // Note: Desktop shell is handled by MainPage on desktop
    return apprenticeshipAsync.when(
      data: (apprenticeship) {
        // No apprenticeship - show placeholder (shell handled by MainPage)
        if (apprenticeship == null) {
          return const Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(child: Text('No Active Apprenticeship')),
          );
        }
        
        // Main content with SingleChildScrollView
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(currentUser?.name),
                  const SizedBox(height: 24),
                  _buildMentorCard(apprenticeship.tailorId),
                  const SizedBox(height: 32),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.3,
                    children: [
                      StatCard(
                        title: 'Learning Progress',
                        value: '${(apprenticeship.progress * 100).toInt()}%',
                        icon: Icons.school_outlined,
                        color: Colors.purple,
                      ),
                      StatCard(
                        title: 'Skill Badges',
                        value: '${apprenticeship.skillIds.length}',
                        icon: Icons.verified_outlined,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text('Assigned Tasks', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 16),
                  _buildTasksList(ref, apprenticeship.id),
                  const SizedBox(height: 32),
                  const Text('My Curriculum', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 16),
                  _buildCurriculumSummary(ref),
                ],
              ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => const ErrorStateWidget(message: 'Failed to load progress.'),
    );
  }

  Widget _buildHeader(String? name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Master the Craft, ${name ?? 'Apprentice'}!',
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
        ),
        Text('Every stitch brings you closer to mastery.', style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildMentorCard(String tailorId) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkNavy,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white10,
            child: Icon(Icons.person_outline, color: AppColors.amber),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Mentor', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text('Master Tailor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: AppColors.amber),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildTasksList(WidgetRef ref, String apprenticeshipId) {
    final tasksAsync = ref.watch(apprenticeshipTasksProvider(apprenticeshipId));
    return tasksAsync.when(
      data: (tasks) {
        if (tasks.isEmpty) return const Text('No tasks assigned yet', style: TextStyle(color: Colors.white24, fontSize: 12));
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tasks.length > 3 ? 3 : tasks.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final task = tasks[index];
            final bool isReview = task.status == ApprenticeTaskStatus.underReview;
            final bool isCompleted = task.status == ApprenticeTaskStatus.completed;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    isCompleted ? Icons.check_circle_rounded : isReview ? Icons.hourglass_top_rounded : Icons.pending_actions_rounded,
                    color: isCompleted ? const Color(0xFF00FF7F) : isReview ? AppColors.amber : Colors.white24,
                    size: 18,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(task.title.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
                        Text(isReview ? 'UNDER REVIEW' : 'DUE: ${task.dueDate.day}/${task.dueDate.month}', style: TextStyle(color: isReview ? AppColors.amber : Colors.white24, fontSize: 8, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => const Text('Error loading tasks'),
    );
  }

  Widget _buildCurriculumSummary(WidgetRef ref) {
    final curriculumAsync = ref.watch(curriculumProvider);
    return curriculumAsync.when(
      data: (modules) => Column(
        children: modules.take(2).map((m) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.menu_book, color: Colors.purple),
            title: Text(m.title),
            trailing: const Icon(Icons.chevron_right),
          ),
        )).toList(),
      ),
      loading: () => const SizedBox(),
      error: (e, _) => const Text('Error loading curriculum'),
    );
  }

Widget _buildNoApprenticeshipState() {
    return const Center(child: Text('No Active Apprenticeship'));
  }

  // Default nav items for null apprenticeship state
  List<NavItem> _buildDefaultNavItems() {
    return [
      NavItem(label: 'Home', icon: Icons.home_rounded, onTap: () {}),
      NavItem(label: 'Tasks', icon: Icons.assignment_rounded, onTap: () {}),
      NavItem(label: 'Curriculum', icon: Icons.menu_book_rounded, onTap: () {}),
      NavItem(label: 'Progress', icon: Icons.trending_up_rounded, onTap: () {}),
      NavItem(label: 'Mentors', icon: Icons.person_rounded, onTap: () {}),
      NavItem(label: 'Settings', icon: Icons.settings_rounded, onTap: () {}),
      NavItem(label: 'Help', icon: Icons.help_outline_rounded, onTap: () {}),
    ];
  }
}
