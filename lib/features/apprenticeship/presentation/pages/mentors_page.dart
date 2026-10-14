import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desby_app/theme/colors.dart';
import 'package:desby_app/core/providers/navigation_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/entities/apprenticeship.dart';
import '../providers/apprenticeship_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../payments/presentation/widgets/subscription_gate.dart';
import '../../../payments/domain/models/plan_registry.dart';
import '../../../../core/widgets/shell_app_bar.dart';

class MentorsPage extends ConsumerWidget {
  const MentorsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final user = ref.watch(currentUserProvider);
    final apprenticeId = user?.id ?? '';
    final apprenticeshipAsync = ref.watch(
      apprenticeApprenticeshipProvider(apprenticeId),
    );

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: shellAppBar(context, title: 'My Tailor'),
      body: apprenticeshipAsync.when(
        data: (apprenticeship) {
          if (apprenticeship == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.school_outlined,
                    color: colors.iconMuted,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'NO TAILOR YET',
                    style: TextStyle(
                      color: colors.textHint,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Join an academy to connect with a tailor',
                    style: TextStyle(color: colors.textHint, fontSize: 12),
                  ),
                ],
              ),
            );
          }

          final tailorProfile = apprenticeship.tailorProfile;
          final tailorName = tailorProfile?.name ?? 'Your Tailor';
          final tailorPhone = tailorProfile?.phone ?? '';
          final tailorBio = tailorProfile?.bio ?? '';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Master card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.amber.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.amber.withValues(alpha: 0.15),
                      child: Text(
                        tailorName.isNotEmpty
                            ? tailorName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: AppColors.amber,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tailorName,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    if (tailorPhone.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.phone_rounded,
                            color: colors.iconMuted,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tailorPhone,
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Contact actions
              if (tailorPhone.isNotEmpty) ...[
                _buildActionTile(
                  colors: colors,
                  icon: Icons.phone_rounded,
                  label: 'Call Tailor',
                  subtitle: tailorPhone,
                  onTap: () async {
                    final uri = Uri.parse('tel:$tailorPhone');
                    if (await canLaunchUrl(uri)) await launchUrl(uri);
                  },
                ),
                const SizedBox(height: 8),
              ],
              _buildActionTile(
                colors: colors,
                icon: Icons.chat_rounded,
                label: 'Message',
                subtitle: 'Send a message to your tailor',
                onTap: () {
                  ref.pushShell('/chat-detail', {
                    'peerId': apprenticeship.tailorId,
                  });
                },
              ),
              const SizedBox(height: 24),
              // Bio section
              if (tailorBio.isNotEmpty) ...[
                const Text(
                  'ABOUT YOUR TAILOR',
                  style: TextStyle(
                    color: AppColors.amber,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
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
                    tailorBio,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
              // Apprenticeship info
              const SizedBox(height: 24),
              const Text(
                'YOUR ACADEMY STATUS',
                style: TextStyle(
                  color: AppColors.amber,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              _buildInfoTile(
                colors: colors,
                label: 'Status',
                value: apprenticeship.status.name.toUpperCase(),
              ),
              _buildInfoTile(
                colors: colors,
                label: 'Progress',
                value: '${(apprenticeship.progress * 100).toInt()}%',
              ),
              _buildInfoTile(
                colors: colors,
                label: 'Skills',
                value: '${apprenticeship.skillIds.length} selected',
              ),
              _buildInfoTile(
                colors: colors,
                label: 'Joined',
                value: _formatDate(apprenticeship.startDate),
              ),
              const SizedBox(height: 24),
              // Switch Mentor button
              _buildSwitchMentorButton(
                context,
                ref,
                colors,
                apprenticeId,
                apprenticeship.tailorId,
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.amber),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Failed to load mentor info',
                style: TextStyle(color: colors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required DesbyThemeColors colors,
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.amber, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: colors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.iconMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required DesbyThemeColors colors,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: colors.textMuted, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchMentorButton(
    BuildContext context,
    WidgetRef ref,
    DesbyThemeColors colors,
    String apprenticeId,
    String currentTailorId,
  ) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () =>
            _showSwitchMentorSheet(context, ref, apprenticeId, currentTailorId),
        icon: const Icon(Icons.swap_horiz_rounded, size: 18),
        label: const Text(
          'SWITCH MENTOR',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            fontSize: 12,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.amber,
          side: BorderSide(color: AppColors.amber.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showSwitchMentorSheet(
    BuildContext context,
    WidgetRef ref,
    String apprenticeId,
    String currentTailorId,
  ) async {
    final colors = context.colors;

    // Check switch cap: Free = 1/30 days, Pro = unlimited
    final profile = await ref
        .read(userProfileProvider(apprenticeId).future)
        .catchError((_) => null);
    final planId =
        profile?.subscriptionPlanId ??
        '${profile?.userType ?? 'apprentice'}_free';
    final plan = PlanRegistry.getPlanById(planId);
    final isPro = plan?.tierLevel == PlanRegistry.proTier;

    // Count terminated apprenticeships in last 30 days
    int recentSwitches = 0;
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final response = await Supabase.instance.client
          .from('apprenticeships')
          .select('id')
          .eq('apprentice_id', apprenticeId)
          .eq('status', 'terminated')
          .gte('updated_at', thirtyDaysAgo.toIso8601String());
      recentSwitches = (response as List).length;
    } catch (_) {}

    final maxSwitches = isPro ? 999 : 1;
    final canSwitch = recentSwitches < maxSwitches;

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (ctx, scrollController) => Container(
          decoration: BoxDecoration(
            color: colors.bottomSheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SWITCH MENTOR',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (!canSwitch)
                      Text(
                        isPro
                            ? 'Unlimited switches (Pro)'
                            : 'Free: 1 switch per 30 days ($recentSwitches/1 used)',
                        style: TextStyle(color: colors.textMuted, fontSize: 11),
                      )
                    else
                      Text(
                        isPro
                            ? 'Unlimited switches (Pro)'
                            : 'Free: ${maxSwitches - recentSwitches} switch remaining',
                        style: TextStyle(color: colors.textMuted, fontSize: 11),
                      ),
                  ],
                ),
              ),
              if (!canSwitch) ...[
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          color: colors.iconMuted,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Switch limit reached',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Upgrade to Pro for unlimited switches',
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            SubscriptionGate.checkAccess(
                              context,
                              requiredTier: PlanRegistry.proTier,
                              featureLabel: 'Unlimited Mentor Switches',
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.amber,
                            foregroundColor: AppColors.darkNavy,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'UPGRADE TO PRO',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else
                Expanded(
                  child: _AvailableTailorList(
                    currentTailorId: currentTailorId,
                    apprenticeId: apprenticeId,
                    onSelected: (tailorId) {
                      Navigator.pop(ctx);
                      _confirmSwitch(context, ref, apprenticeId, tailorId);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmSwitch(
    BuildContext context,
    WidgetRef ref,
    String apprenticeId,
    String newTailorId,
  ) {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.dialogBg,
        title: Text(
          'Switch Mentor?',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          'This will end your current mentorship and send a new enrollment request to the selected tailor. Your progress will be saved.',
          style: TextStyle(color: colors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL', style: TextStyle(color: colors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _executeSwitch(ref, apprenticeId, newTailorId);
              if (context.mounted) {
                ref.invalidate(apprenticeApprenticeshipProvider(apprenticeId));
              }
            },
            child: const Text(
              'SWITCH',
              style: TextStyle(
                color: AppColors.amber,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _executeSwitch(
    WidgetRef ref,
    String apprenticeId,
    String newTailorId,
  ) async {
    try {
      // Terminate current apprenticeship
      final current = await ref
          .read(apprenticeshipRepositoryProvider)
          .getApprenticeship(apprenticeId);
      current.fold((_) {}, (app) async {
        if (app != null) {
          final updated = app.copyWith(
            status: ApprenticeshipStatus.terminated,
            endDate: DateTime.now(),
          );
          await ref
              .read(apprenticeshipRepositoryProvider)
              .updateApprenticeship(updated);
        }
      });

      // Create new pending apprenticeship
      const uuid = Uuid();
      final newApprenticeship = Apprenticeship(
        id: 'app_${uuid.v4().substring(0, 8)}',
        tailorId: newTailorId,
        apprenticeId: apprenticeId,
        status: ApprenticeshipStatus.awaitingMasterApproval,
        progress: 0,
        startDate: DateTime.now(),
      );
      await ref
          .read(apprenticeshipRepositoryProvider)
          .createApprenticeship(newApprenticeship);
    } catch (e) {
      debugPrint('[MENTORS] Switch error: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _AvailableTailorList extends ConsumerWidget {
  final String currentTailorId;
  final String apprenticeId;
  final ValueChanged<String> onSelected;

  const _AvailableTailorList({
    required this.currentTailorId,
    required this.apprenticeId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return FutureBuilder(
      future: Supabase.instance.client
          .from('users')
          .select('id, name, business_name, profile_image, bio')
          .eq('user_type', 'tailor')
          .neq('id', currentTailorId)
          .order('business_name'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.amber),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Could not load tailors',
              style: TextStyle(color: colors.textMuted),
            ),
          );
        }
        final tailors = (snapshot.data as List?) ?? [];
        if (tailors.isEmpty) {
          return Center(
            child: Text(
              'No other tailors available',
              style: TextStyle(color: colors.textMuted),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: tailors.length,
          itemBuilder: (ctx, i) {
            final t = tailors[i];
            final name = (t['business_name'] as String?)?.isNotEmpty == true
                ? t['business_name']
                : t['name'] ?? 'Tailor';
            final avatar = t['profile_image'] as String?;
            return ListTile(
              leading: CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.amber.withValues(alpha: 0.15),
                backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                child: avatar == null
                    ? Text(
                        name[0].toUpperCase(),
                        style: TextStyle(
                          color: AppColors.amber,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    : null,
              ),
              title: Text(
                name,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                (t['bio'] as String?)?.isNotEmpty == true ? t['bio'] : 'Tailor',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.textMuted, fontSize: 11),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: colors.iconMuted,
              ),
              onTap: () => onSelected(t['id']),
            );
          },
        );
      },
    );
  }
}
