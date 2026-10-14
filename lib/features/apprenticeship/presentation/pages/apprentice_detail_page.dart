import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desby_app/theme/colors.dart';
import 'package:desby_app/core/providers/navigation_provider.dart';
import '../../domain/entities/apprenticeship.dart';
import '../../domain/entities/apprentice_task.dart';
import '../providers/apprenticeship_provider.dart';
import '../widgets/create_task_dialog.dart';
import '../../../../core/widgets/shell_app_bar.dart';

class ApprenticeDetailPage extends ConsumerWidget {
  final String apprenticeId;
  final String apprenticeshipId;
  const ApprenticeDetailPage({
    super.key,
    required this.apprenticeId,
    required this.apprenticeshipId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final apprenticeshipsAsync = ref.watch(
      tailorApprenticeshipsProvider(apprenticeId),
    );

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: shellAppBar(context, title: 'APPRENTICE PROFILE'),
      body: apprenticeshipsAsync.when(
        data: (apprenticeships) {
          final app = apprenticeships.firstWhere(
            (a) => a.id == apprenticeshipId,
            orElse: () => apprenticeships.isNotEmpty
                ? apprenticeships.first
                : Apprenticeship(
                    id: '',
                    tailorId: '',
                    apprenticeId: '',
                    status: ApprenticeshipStatus.active,
                    progress: 0,
                    startDate: DateTime.now(),
                  ),
          );
          if (app.id.isEmpty) {
            return Center(
              child: Text(
                'Apprenticeship not found',
                style: TextStyle(color: colors.textMuted),
              ),
            );
          }
          return _buildProfile(context, ref, app, colors);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.amber),
        ),
        error: (err, _) => Center(
          child: Text('Error: $err', style: TextStyle(color: colors.textMuted)),
        ),
      ),
    );
  }

  Widget _buildProfile(
    BuildContext context,
    WidgetRef ref,
    Apprenticeship app,
    DesbyThemeColors colors,
  ) {
    final profile = app.apprenticeProfile;
    final name = profile?.name ?? 'Apprentice';
    final phone = profile?.phone ?? '';
    final bio = profile?.bio ?? 'No bio provided';
    final tasksAsync = ref.watch(apprenticeshipTasksProvider(app.id));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.amber.withValues(alpha: 0.15),
                  backgroundImage: profile?.profileImage != null
                      ? NetworkImage(profile!.profileImage!)
                      : null,
                  child: profile?.profileImage == null
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: AppColors.amber,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    phone,
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(app.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _statusColor(app.status).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _statusLabel(app.status),
                    style: TextStyle(
                      color: _statusColor(app.status),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Progress section
          _buildSection('PROGRESS'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.cardBorder),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mastery Level',
                      style: TextStyle(color: colors.textMuted, fontSize: 13),
                    ),
                    Text(
                      '${(app.progress * 100).toInt()}%',
                      style: TextStyle(
                        color: AppColors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: app.progress,
                  backgroundColor: colors.divider,
                  valueColor: const AlwaysStoppedAnimation(AppColors.amber),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMiniStat(colors, 'Level', app.level ?? 'Beginner'),
                    _buildMiniStat(colors, 'Skills', '${app.skillIds.length}'),
                    _buildMiniStat(
                      colors,
                      'Joined',
                      _formatDate(app.startDate),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Skills section
          if (app.skillIds.isNotEmpty) ...[
            _buildSection('SKILLS & GOALS'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: app.skillIds
                  .map(
                    (skill) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.amber.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        skill,
                        style: TextStyle(
                          color: AppColors.amber,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Bio section
          if (bio.isNotEmpty && bio != 'No bio provided') ...[
            _buildSection('ABOUT'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.cardBorder),
              ),
              child: Text(
                bio,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Tasks section
          _buildSection('ALL TASKS'),
          const SizedBox(height: 12),
          tasksAsync.when(
            data: (tasks) {
              if (tasks.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.cardBorder),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          color: colors.iconMuted,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No tasks assigned yet',
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                children: tasks
                    .map((task) => _buildTaskTile(ref, task, colors))
                    .toList(),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                color: AppColors.amber,
                strokeWidth: 2,
              ),
            ),
            error: (err, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sync_problem_rounded,
                    color: colors.textMuted,
                    size: 36,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'SYNC ERROR',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Could not load tasks',
                    style: TextStyle(color: colors.textMuted, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) =>
                          CreateTaskDialog(apprenticeshipId: app.id),
                    );
                  },
                  icon: const Icon(Icons.add_task_rounded, size: 18),
                  label: const Text('ASSIGN TASK'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.amber,
                    side: const BorderSide(color: AppColors.amber),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.pushShell('/chat-detail', {
                      'peerId': app.apprenticeId,
                      'conversationId': 'apprentice_${app.id}',
                    });
                  },
                  icon: const Icon(Icons.chat_rounded, size: 18),
                  label: const Text('MESSAGE'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.textSecondary,
                    side: BorderSide(color: colors.divider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppColors.amber,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildMiniStat(DesbyThemeColors colors, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: colors.textMuted, fontSize: 10)),
      ],
    );
  }

  Widget _buildTaskTile(
    WidgetRef ref,
    ApprenticeTask task,
    DesbyThemeColors colors,
  ) {
    Color statusColor;
    IconData statusIcon;
    switch (task.status) {
      case ApprenticeTaskStatus.completed:
        statusColor = AppColors.successGreen;
        statusIcon = Icons.check_circle_rounded;
        break;
      case ApprenticeTaskStatus.inProgress:
        statusColor = Colors.blue;
        statusIcon = Icons.play_circle_rounded;
        break;
      case ApprenticeTaskStatus.underReview:
        statusColor = Colors.orange;
        statusIcon = Icons.rate_review_rounded;
        break;
      case ApprenticeTaskStatus.failed:
        statusColor = Colors.red;
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = colors.textMuted;
        statusIcon = Icons.radio_button_unchecked;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Due: ${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year}',
                  style: TextStyle(color: colors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          if (task.score != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${task.score!.toInt()}%',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _statusColor(ApprenticeshipStatus status) {
    switch (status) {
      case ApprenticeshipStatus.active:
        return AppColors.successGreen;
      case ApprenticeshipStatus.awaitingMasterApproval:
        return Colors.orange;
      case ApprenticeshipStatus.completed:
        return Colors.blue;
      case ApprenticeshipStatus.terminated:
        return Colors.red;
      case ApprenticeshipStatus.pendingInvite:
        return Colors.purple;
    }
  }

  String _statusLabel(ApprenticeshipStatus status) {
    switch (status) {
      case ApprenticeshipStatus.active:
        return 'ACTIVE';
      case ApprenticeshipStatus.awaitingMasterApproval:
        return 'PENDING APPROVAL';
      case ApprenticeshipStatus.completed:
        return 'COMPLETED';
      case ApprenticeshipStatus.terminated:
        return 'TERMINATED';
      case ApprenticeshipStatus.pendingInvite:
        return 'PENDING INVITE';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
