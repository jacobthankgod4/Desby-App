import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desby_app/features/apprenticeship/domain/entities/apprentice_task.dart';
import 'package:desby_app/features/apprenticeship/presentation/providers/apprenticeship_provider.dart';
import 'package:desby_app/features/apprenticeship/presentation/widgets/create_task_dialog.dart';
import 'package:desby_app/features/auth/presentation/providers/auth_provider.dart';
import '../../../../theme/colors.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../domain/entities/apprenticeship.dart';
import '../../domain/entities/apprentice_module.dart';
import 'unified_add_apprentice_page.dart';
import 'module_create_page.dart';
import '../../../../core/widgets/shell_app_bar.dart';

/// Combined Academy page with tabs: Apprentices, Curriculum, Add Apprentice.
class AcademyPage extends ConsumerStatefulWidget {
  const AcademyPage({super.key});

  @override
  ConsumerState<AcademyPage> createState() => _AcademyPageState();
}

class _AcademyPageState extends ConsumerState<AcademyPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: shellAppBar(
        context,
        title: 'ACADEMY',
        foregroundColor: colors.textPrimary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.amber,
          unselectedLabelColor: colors.textMuted,
          indicatorColor: AppColors.amber,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'APPRENTICES'),
            Tab(text: 'CURRICULUM'),
            Tab(text: 'ADD'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ApprenticesTab(),
          _CurriculumTab(),
          _AddApprenticeTab(),
        ],
      ),
    );
  }
}

// ── Apprentices Tab ──

class _ApprenticesTab extends ConsumerWidget {
  const _ApprenticesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final currentUser = ref.watch(currentUserProvider);
    final tailorId = currentUser?.id ?? '';
    final apprenticeshipsAsync = ref.watch(
      tailorApprenticeshipsProvider(tailorId),
    );

    return apprenticeshipsAsync.when(
      data: (apprenticeships) {
        final pending = apprenticeships
            .where(
              (a) => a.status == ApprenticeshipStatus.awaitingMasterApproval,
            )
            .toList();
        final active = apprenticeships
            .where((a) => a.status == ApprenticeshipStatus.active)
            .toList();

        if (pending.isEmpty && active.isEmpty) {
          return _buildEmptyState(context);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (pending.isNotEmpty) ...[
                _sectionTitle('Enrollment Requests', colors),
                const SizedBox(height: 8),
                ...pending.map((a) => _PendingRequestCard(apprenticeship: a)),
                const SizedBox(height: 24),
              ],
              _sectionTitle('Active Apprentices', colors),
              const SizedBox(height: 8),
              if (active.isEmpty)
                _buildEmptyState(context)
              else
                ...active.map((a) => _ApprenticeCard(apprenticeship: a)),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.amber),
      ),
      error: (e, _) =>
          const ErrorStateWidget(message: 'Could not load apprentices.'),
    );
  }

  Widget _sectionTitle(String text, DesbyThemeColors colors) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: colors.textMuted,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_rounded, color: colors.textMuted, size: 48),
            const SizedBox(height: 16),
            Text(
              'No apprentices yet',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Go to ADD tab to invite your first apprentice',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textMuted.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            apprenticeship.apprenticeName ?? 'Unknown',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
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
                  child: const Text('Accept'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
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
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                  child: const Text('Decline'),
                ),
              ),
            ],
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
    final progress = apprenticeship.progress;

    return GestureDetector(
      onTap: () {
        ref.pushShell(
          '/apprentice-detail?apprenticeshipId=${apprenticeship.id}',
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.amber.withValues(alpha: 0.15),
                  child: Text(
                    (apprenticeship.apprenticeName ?? 'A')[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.amber,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        apprenticeship.apprenticeName ?? 'Unknown',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        apprenticeship.skillIds.join(', ').isNotEmpty
                            ? apprenticeship.skillIds.join(', ')
                            : 'No skills yet',
                        style: TextStyle(color: colors.textMuted, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: colors.textMuted),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: colors.borderSubtle,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.amber,
                ),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${progress.toStringAsFixed(0)}% progress',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Curriculum Tab ──

class _CurriculumTab extends ConsumerWidget {
  const _CurriculumTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final curriculumAsync = ref.watch(curriculumProvider);

    return curriculumAsync.when(
      data: (modules) {
        if (modules.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    color: colors.textMuted,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No curriculum yet',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first module to start teaching',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textMuted.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => ref.pushShell('/module-create'),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('CREATE MODULE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amber,
                      foregroundColor: AppColors.darkNavy,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MODULES (${modules.length})',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => ref.pushShell('/module-create'),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('ADD MODULE'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.amber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...modules.map((module) => _ModuleCard(module: module)),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.amber),
      ),
      error: (e, _) =>
          const ErrorStateWidget(message: 'Could not load curriculum.'),
    );
  }
}

class _ModuleCard extends ConsumerWidget {
  final ApprenticeModule module;
  const _ModuleCard({required this.module});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final lessonCount = module.lessonIds.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'MODULE ${module.orderIndex + 1}',
                  style: TextStyle(
                    color: AppColors.amber,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () =>
                    ref.pushShell('/module-create?moduleId=${module.id}'),
                icon: Icon(
                  Icons.edit_rounded,
                  color: colors.textMuted,
                  size: 18,
                ),
                tooltip: 'Edit',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            module.title,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (module.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              module.description,
              style: TextStyle(color: colors.textMuted, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Text(
            '$lessonCount lesson${lessonCount == 1 ? '' : 's'}',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Add Apprentice Tab ──

class _AddApprenticeTab extends StatelessWidget {
  const _AddApprenticeTab();

  @override
  Widget build(BuildContext context) {
    return const UnifiedAddApprenticePage();
  }
}
