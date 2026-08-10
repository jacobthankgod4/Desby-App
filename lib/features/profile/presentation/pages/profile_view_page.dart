import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/profile_provider.dart';
import '../../../../theme/colors.dart';
import '../../domain/entities/user_profile.dart';
import '../../../../core/widgets/luxury_glass_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/providers/navigation_provider.dart';

class ProfileViewPage extends ConsumerWidget {
  final String userId;
  const ProfileViewPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final isOwnProfile = currentUser?.id == userId;
    final profileAsync = ref.watch(userProfileProvider(userId));

    final content = profileAsync.when(
      data: (profile) {
        if (profile == null) return _buildNoProfileState(context, ref, userId);
        return _buildCompleteProfileView(context, profile, ref, isOwnProfile, currentUser?.userType);
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amber, strokeWidth: 2)),
      error: (err, _) => _buildErrorState(context, err.toString(), ref, userId),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 1000;
        if (isDesktop) {
          return Container(color: const Color(0xFF0A1921), child: content);
        }
        return Scaffold(
          backgroundColor: const Color(0xFF0A1921),
          appBar: AppBar(
            title: const Text('ACCOUNT DOSSIER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            actions: [
              if (isOwnProfile)
                IconButton(
                  icon: const Icon(Icons.settings_suggest_rounded, color: Colors.white24, size: 20),
                  onPressed: () => ref.read(navigationProvider.notifier).state = const NavigationState('/profile/settings'),
                ),
            ],
          ),
          body: content,
        );
      },
    );
  }

  Widget _buildCompleteProfileView(BuildContext context, UserProfile profile, WidgetRef ref, bool isOwnProfile, String? currentUserType) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildHeader(profile),
          const SizedBox(height: 32),

          // CONTEXTUAL ACTIONS (If not own profile)
          if (!isOwnProfile) _buildContextualActions(context, profile, currentUserType),
          if (!isOwnProfile) const SizedBox(height: 24),
          
          LuxuryGlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('LOGISTICS & CORRESPONDENCE', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                const SizedBox(height: 24),
                _buildInfoRow(Icons.email_outlined, 'ENCRYPTED EMAIL', profile.email),
                _buildInfoRow(Icons.phone_outlined, 'DIRECT LINE', profile.phone ?? 'NOT PROVIDED'),
                _buildInfoRow(Icons.location_on_outlined, 'PRIMARY ADDRESS', profile.address ?? 'NOT PROVIDED'),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          if (profile.userType == 'tailor') _buildTailorBusinessInfo(profile),
          
          const SizedBox(height: 32),
          
          if (isOwnProfile)
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/profile/edit', arguments: userId),
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: const Text('MODIFY DOSSIER', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.amber,
                  side: const BorderSide(color: Colors.white10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  Widget _buildContextualActions(BuildContext context, UserProfile target, String? viewerType) {
    return Row(
      children: [
        if (target.userType == 'tailor' && viewerType == 'client')
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/tailor-profile', arguments: target.id),
              icon: const Icon(Icons.architecture_rounded, size: 18),
              label: const Text('BOOK NOW', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amber,
                foregroundColor: AppColors.darkNavy,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        if (target.userType == 'tailor' && viewerType == 'client') const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: Start Chat logic
            },
            icon: const Icon(Icons.forum_rounded, size: 18),
            label: const Text('SECURE MESSAGE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white10),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(UserProfile profile) {
    return Column(
      children: [
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.amber.withValues(alpha: 0.3), width: 2),
          ),
          child: profile.profileImage != null
              ? ClipOval(
                  child: Image.network(
                    profile.profileImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Text(profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 40, color: AppColors.amber, fontWeight: FontWeight.w900)),
                    ),
                  ),
                )
              : Center(child: Text(profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 40, color: AppColors.amber, fontWeight: FontWeight.w900))),
        ),
        const SizedBox(height: 16),
        Text(profile.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(color: AppColors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.amber.withValues(alpha: 0.2))),
          child: Text(profile.userType.toUpperCase(), style: const TextStyle(color: AppColors.amber, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        ),
      ],
    );
  }

  Widget _buildTailorBusinessInfo(UserProfile profile) {
    return LuxuryGlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ATELIER CONFIGURATION', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 24),
          _buildInfoRow(Icons.business_center_outlined, 'BUSINESS IDENTITY', profile.businessName ?? 'NOT CONFIGURED'),
          _buildInfoRow(Icons.storefront_outlined, 'STUDIO ADDRESS', profile.businessAddress ?? 'NOT CONFIGURED'),
          
          if (profile.services != null && profile.services!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('SPECIALIZATIONS', style: TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: profile.services!.map((service) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
                child: Text(service.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.w900)),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: AppColors.amber, size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoProfileState(BuildContext context, WidgetRef ref, String userId) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_sync_rounded, size: 64, color: Colors.white10),
          const SizedBox(height: 24),
          const Text('SYNCING DOSSIER...', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 32),
          TextButton(onPressed: () => ref.invalidate(userProfileProvider(userId)), child: const Text('RETRY', style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error, WidgetRef ref, String userId) {
    return Center(child: Text('SYNC ERROR: $error', style: const TextStyle(color: Colors.redAccent, fontSize: 10)));
  }

  Widget _buildLogoutButton(WidgetRef ref, BuildContext context) {
    return TextButton(
      onPressed: () async {
        await Supabase.instance.client.auth.signOut();
        if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      },
      child: const Text('TERMINATE SESSION', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
    );
  }
}
