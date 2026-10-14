import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_provider.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/providers/layout_provider.dart';
import '../../../../theme/colors.dart';
import '../../domain/entities/user_profile.dart';
import '../../../../core/widgets/luxury_glass_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../../core/widgets/shell_app_bar.dart';
import '../../../../core/widgets/app_network_image.dart';

class ProfileViewPage extends ConsumerWidget {
  final String userId;
  const ProfileViewPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final currentUser = ref.watch(currentUserProvider);
    final isOwnProfile = currentUser?.id == userId;
    final profileAsync = ref.watch(userProfileProvider(userId));

    final content = profileAsync.when(
      data: (profile) {
        if (profile == null) return _buildNoProfileState(context, ref, userId);
        return _buildCompleteProfileView(
          context,
          profile,
          ref,
          isOwnProfile,
          currentUser?.userType,
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: AppColors.amber,
          strokeWidth: 2,
        ),
      ),
      error: (err, _) => _buildErrorState(context, err.toString(), ref, userId),
    );

    final isDesktop = ref.watch(isDesktopProvider);
    if (isDesktop) {
      return Container(color: colors.scaffoldBg, child: content);
    }
    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: shellAppBar(
        context,
        title: 'My Profile',
        actions: [
          if (isOwnProfile)
            IconButton(
              icon: Icon(
                Icons.settings_suggest_rounded,
                color: colors.textMuted,
                size: 20,
              ),
              onPressed: () => ref.pushShell('/profile/settings'),
            ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildCompleteProfileView(
    BuildContext context,
    UserProfile profile,
    WidgetRef ref,
    bool isOwnProfile,
    String? currentUserType,
  ) {
    final colors = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildHeader(context, profile),
          const SizedBox(height: 32),

          // CONTEXTUAL ACTIONS (If not own profile)
          if (!isOwnProfile)
            _buildContextualActions(context, profile, currentUserType, ref),
          if (!isOwnProfile) const SizedBox(height: 24),

          LuxuryGlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contact Information',
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 24),
                _buildInfoRow(
                  context,
                  Icons.email_outlined,
                  'Email',
                  profile.email,
                ),
                _buildInfoRow(
                  context,
                  Icons.phone_outlined,
                  'Phone',
                  profile.phone ?? 'Not provided',
                ),
                _buildInfoRow(
                  context,
                  Icons.location_on_outlined,
                  'Address',
                  profile.address ?? 'Not provided',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          if (profile.userType == 'tailor')
            _buildTailorBusinessInfo(context, profile),

          const SizedBox(height: 32),

          if (isOwnProfile)
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                onPressed: () =>
                    ref.pushShell('/profile/edit', {'userId': userId}),
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: const Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1.5,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.amber,
                  side: BorderSide(color: colors.borderDefault),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 40),
          if (isOwnProfile) _buildLogoutButton(ref, context),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildContextualActions(
    BuildContext context,
    UserProfile target,
    String? viewerType,
    WidgetRef ref,
  ) {
    final colors = context.colors;
    return Row(
      children: [
        if (target.userType == 'tailor' && viewerType == 'client')
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () =>
                  ref.pushShell('/tailor-profile', {'tailorId': target.id}),
              icon: const Icon(Icons.architecture_rounded, size: 18),
              label: const Text(
                'BOOK NOW',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amber,
                foregroundColor: AppColors.darkNavy,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        if (target.userType == 'tailor' && viewerType == 'client')
          const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              final me = ref.read(currentUserProvider);
              if (me == null) return;
              final repo = ref.read(chatRepositoryProvider);
              final result = await repo.createConversation([me.id, userId]);
              result.fold(
                (failure) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Could not start conversation. Please try again.',
                        ),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                },
                (conversation) {
                  ref.pushShell('/chat-detail', {
                    'conversationId': conversation.id,
                    'peerId': userId,
                  });
                },
              );
            },
            icon: const Icon(Icons.forum_rounded, size: 18),
            label: const Text(
              'Send Message',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.textPrimary,
              side: BorderSide(color: colors.borderDefault),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, UserProfile profile) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.amber.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: profile.profileImage != null
              ? ClipOval(
                  child: AppNetworkImage(
                    url: profile.profileImage!,
                    fit: BoxFit.cover,
                  ),
                )
              : Center(
                  child: Text(
                    profile.name.isNotEmpty
                        ? profile.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 40,
                      color: AppColors.amber,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 16),
        Text(
          profile.name.toUpperCase(),
          style: TextStyle(
            color: context.colors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.amber.withValues(alpha: 0.2)),
          ),
          child: Text(
            profile.userType.toUpperCase(),
            style: TextStyle(
              color: AppColors.amber,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTailorBusinessInfo(BuildContext context, UserProfile profile) {
    final colors = context.colors;
    return LuxuryGlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Business Details',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoRow(
            context,
            Icons.business_center_outlined,
            'Business Name',
            profile.businessName ?? 'Not set',
          ),
          _buildInfoRow(
            context,
            Icons.storefront_outlined,
            'Workshop Address',
            profile.businessAddress ?? 'Not set',
          ),

          if (profile.services != null && profile.services!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Specializations',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.services!
                  .map(
                    (service) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        service.toUpperCase(),
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.amber, size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoProfileState(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_sync_rounded, size: 64, color: colors.textMuted),
          const SizedBox(height: 24),
          Text(
            'Loading profile...',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: () => ref.invalidate(userProfileProvider(userId)),
            child: const Text(
              'RETRY',
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

  Widget _buildErrorState(
    BuildContext context,
    String error,
    WidgetRef ref,
    String userId,
  ) {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sync_problem_rounded, color: colors.iconMuted, size: 48),
          const SizedBox(height: 16),
          Text(
            'SYNC ERROR',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Could not load profile',
            style: TextStyle(color: colors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => ref.invalidate(userProfileProvider(userId)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
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
    );
  }

  Widget _buildLogoutButton(WidgetRef ref, BuildContext context) {
    return TextButton(
      onPressed: () async {
        await ref.read(authStateProvider.notifier).logout();
        if (context.mounted)
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
      },
      child: const Text(
        'Log Out',
        style: TextStyle(
          color: Colors.redAccent,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }
}
