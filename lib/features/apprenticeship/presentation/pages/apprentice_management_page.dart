import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desby_app/features/apprenticeship/domain/entities/apprentice_task.dart';
import 'package:desby_app/features/apprenticeship/presentation/providers/apprenticeship_provider.dart';
import '../widgets/create_task_dialog.dart';
import 'apprentice_task_grading_page.dart';
import 'package:desby_app/features/auth/presentation/providers/auth_provider.dart';
import '../../../../theme/colors.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../domain/entities/apprenticeship.dart';

class ApprenticeManagementPage extends ConsumerWidget {
  const ApprenticeManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final tailorId = currentUser?.id ?? '';

    final apprenticeshipsAsync = ref.watch(tailorApprenticeshipsProvider(tailorId));

    return Scaffold(
      backgroundColor: const Color(0xFF0A1921),
      body: apprenticeshipsAsync.when(
        data: (apprenticeships) {
          final pending = apprenticeships.where((a) => a.status == ApprenticeshipStatus.awaitingMasterApproval).toList();
          final active = apprenticeships.where((a) => a.status == ApprenticeshipStatus.active).toList();

          return CustomScrollView(
            slivers: [
              if (pending.isNotEmpty) ...[
                _buildSectionTitle('Enrollment Requests'),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _PendingRequestCard(apprenticeship: pending[index]),
                    childCount: pending.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
              _buildSectionTitle('Active Apprentices'),
              if (active.isEmpty && pending.isEmpty)
                SliverFillRemaining(child: _buildEmptyState(context))
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _ApprenticeCard(apprenticeship: active[index]),
                    childCount: active.length,
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amber)),
        error: (error, _) => const ErrorStateWidget(message: 'Failed to sync academy database.'),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
        child: Text(title.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 64, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          const Text('No Active Apprenticeships', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold)),
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
    final profile = apprenticeship.apprenticeProfile;
    final name = profile?.name ?? 'Candidate ${apprenticeship.apprenticeId.substring(0, 5)}';

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
            backgroundImage: profile?.profileImage != null ? NetworkImage(profile!.profileImage!) : null,
            child: profile?.profileImage == null ? const Icon(Icons.person, color: AppColors.darkNavy) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('New Apprentice Invite Request', style: TextStyle(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              final updated = apprenticeship.copyWith(status: ApprenticeshipStatus.active);
              await ref.read(apprenticeshipRepositoryProvider).updateApprenticeship(updated);
              ref.invalidate(tailorApprenticeshipsProvider(apprenticeship.tailorId));
            },
            icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.green),
          ),
          IconButton(
            onPressed: () async {
              final updated = apprenticeship.copyWith(status: ApprenticeshipStatus.terminated);
              await ref.read(apprenticeshipRepositoryProvider).updateApprenticeship(updated);
              ref.invalidate(tailorApprenticeshipsProvider(apprenticeship.tailorId));
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
    final profile = apprenticeship.apprenticeProfile;
    final name = profile?.name ?? 'Apprentice ${apprenticeship.apprenticeId.substring(0, 5)}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28, 
                backgroundColor: Colors.white10, 
                backgroundImage: profile?.profileImage != null ? NetworkImage(profile!.profileImage!) : null,
                child: profile?.profileImage == null ? const Icon(Icons.person_outline, color: Colors.white70) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Master-in-Training', style: TextStyle(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_task_rounded, color: AppColors.amber, size: 20),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => CreateTaskDialog(apprenticeshipId: apprenticeship.id),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white24, size: 20),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildTaskReviewSection(ref),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mastery Progress', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w600)),
              Text('${(apprenticeship.progress * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: apprenticeship.progress,
            backgroundColor: Colors.white10,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.amber),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskReviewSection(WidgetRef ref) {
    final tasksAsync = ref.watch(apprenticeshipTasksProvider(apprenticeship.id));
    return tasksAsync.when(
      data: (tasks) {
        final reviewable = tasks.where((t) => t.status == ApprenticeTaskStatus.underReview).toList();
        if (reviewable.isEmpty) return const SizedBox.shrink();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 16),
            Text('${reviewable.length} SUBMISSIONS AWAITING REVIEW', style: const TextStyle(color: AppColors.amber, fontSize: 9, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            ...reviewable.map((t) => _buildReviewItem(ref, t)),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
    );
  }

  Widget _buildReviewItem(WidgetRef ref, ApprenticeTask task) {
    return InkWell(
      onTap: () {
        Navigator.push(
          ref.context,
          MaterialPageRoute(
            builder: (context) => ApprenticeTaskGradingPage(task: task),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            const Icon(Icons.history_edu_rounded, color: AppColors.amber, size: 16),
            const SizedBox(width: 12),
            Expanded(child: Text(task.title.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900))),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white10, size: 10),
          ],
        ),
      ),
    );
  }
}
