import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/luxury_stat_card.dart';
import 'package:desby_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:desby_app/features/apprenticeship/presentation/providers/apprenticeship_provider.dart';
import "package:desby_app/features/apprenticeship/domain/entities/apprentice_task.dart";
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/luxury_glass_card.dart';
import '../../../../theme/colors.dart';

class ApprenticeDashboard extends ConsumerWidget {
  const ApprenticeDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final userId = currentUser?.id ?? '';
    final apprenticeshipAsync = ref.watch(apprenticeApprenticeshipProvider(userId));

    return apprenticeshipAsync.when(
      data: (apprenticeship) {
        if (apprenticeship == null) {
          return const Scaffold(
            backgroundColor: AppColors.darkNavy,
            body: Center(child: Text('NO ACTIVE ACADEMY SESSION', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2))),
          );
        }
        
        return Scaffold(
          backgroundColor: AppColors.darkNavy,
          body: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(currentUser?.name),
                  const SizedBox(height: 32),
                  
                  // 1. CRAFT MASTERY HUD
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      LuxuryStatCard(
                        title: 'Learning Sync',
                        value: '${(apprenticeship.progress * 100).toInt()}%',
                        icon: Icons.school_rounded,
                        color: Colors.purpleAccent,
                      ),
                      LuxuryStatCard(
                        title: 'Skill Badges',
                        value: '${apprenticeship.skillIds.length}',
                        icon: Icons.verified_rounded,
                        color: Colors.blueAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 2. MENTOR ACCESS
                  _buildMentorHUD(apprenticeship.tailorId),
                  const SizedBox(height: 32),

                  // 3. TASK QUEUE
                  _buildSectionHeader('Critical Tasks', () {}),
                  const SizedBox(height: 16),
                  _buildTasksManifest(ref, apprenticeship.id),
                  
                  const SizedBox(height: 32),
                  
                  // 4. CURRICULUM SYNC
                  _buildSectionHeader('Academy Modules', () {}),
                  const SizedBox(height: 16),
                  _buildCurriculumHUD(ref),
                  const SizedBox(height: 40),
                ],
              ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amber)),
      error: (error, _) => const ErrorStateWidget(message: 'Academy sync failed.'),
    );
  }

  Widget _buildHeader(String? name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ACADEMY DASHBOARD', style: TextStyle(color: AppColors.amber, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 2)),
        const SizedBox(height: 4),
        Text(
          'Mastery, ${name ?? 'Apprentice'}',
          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
      ],
    );
  }

  Widget _buildMentorHUD(String tailorId) {
    return LuxuryGlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(color: AppColors.amber.withValues(alpha: 0.1), shape: BoxShape.circle),
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
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildTasksManifest(WidgetRef ref, String apprenticeshipId) {
    final tasksAsync = ref.watch(apprenticeshipTasksProvider(apprenticeshipId));
    return tasksAsync.when(
      data: (tasks) {
        if (tasks.isEmpty) return const LuxuryGlassCard(padding: EdgeInsets.all(32), child: Center(child: Text('QUEUE CLEAR', style: TextStyle(color: Colors.white10, fontWeight: FontWeight.w900, fontSize: 10))));
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tasks.length > 3 ? 3 : tasks.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final task = tasks[index];
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
                        Text(isReview ? 'PENDING VALIDATION' : 'DEADLINE: ${task.dueDate.day}/${task.dueDate.month}', style: TextStyle(color: isReview ? AppColors.amber : Colors.white24, fontSize: 8, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white10, size: 12),
                ],
              ),
            );
          },
        );
      },
      loading: () => const LinearProgressIndicator(color: AppColors.amber),
      error: (e, _) => const Text('History Sync Error'),
    );
  }

  Widget _buildCurriculumHUD(WidgetRef ref) {
    final curriculumAsync = ref.watch(curriculumProvider);
    return curriculumAsync.when(
      data: (modules) => Column(
        children: modules.take(2).map((m) => LuxuryGlassCard(
          padding: const EdgeInsets.all(4),
          child: ListTile(
            leading: const Icon(Icons.bookmark_rounded, color: Colors.purpleAccent, size: 20),
            title: Text(m.title.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 16),
          ),
        )).toList(),
      ),
      loading: () => const SizedBox(),
      error: (e, _) => const SizedBox(),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white38)),
        GestureDetector(onTap: onSeeAll, child: const Text('VIEW ALL', style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1))),
      ],
    );
  }
}
