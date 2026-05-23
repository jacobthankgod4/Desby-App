import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/profile_provider.dart';
import '../../../../theme/colors.dart';
import '../../domain/entities/user_profile.dart';

class ProfileViewPage extends ConsumerWidget {
  final String userId;
  const ProfileViewPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(userId));

    return Scaffold(
      backgroundColor: const Color(0xFF0A1921),
      appBar: AppBar(
        title: const Text('PROFILE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
        backgroundColor: Colors.transparent, 
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: AppColors.amber, size: 20),
            onPressed: () {
              Navigator.pushNamed(context, '/profile/edit', arguments: userId);
            },
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return _buildNoProfileState(context, ref, userId);
          }
          
          // Check if profile is incomplete
          final isProfileIncomplete = _isProfileIncomplete(profile);
          if (isProfileIncomplete) {
            return _buildIncompleteProfileView(context, profile, ref);
          }
          
          return _buildCompleteProfileView(context, profile, ref);
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amber)),
        error: (err, stackTrace) => _buildErrorState(context, err.toString(), ref, userId),
      ),
    );
  }

  /// Check if profile has essential fields filled
  bool _isProfileIncomplete(UserProfile profile) {
    // Profile is incomplete if name is empty or key fields are missing
    final hasBasicInfo = profile.name.isNotEmpty && profile.name != 'New User';
    final hasContact = profile.phone != null && profile.phone!.isNotEmpty;
    final hasAddress = profile.address != null && profile.address!.isNotEmpty;
    final hasState = profile.state != null && profile.state!.isNotEmpty;
    
    // For tailors, check business info
    final isTailor = profile.userType == 'tailor';
    final hasBusinessInfo = !isTailor || 
        (profile.businessName != null && profile.businessName!.isNotEmpty);
    
    return !(hasBasicInfo && hasContact && hasAddress && hasState && hasBusinessInfo);
  }

  /// Build view for incomplete profile - show option to complete onboarding
  Widget _buildIncompleteProfileView(BuildContext context, UserProfile profile, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Warning Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_add_rounded, size: 60, color: Colors.orange),
          ),
          const SizedBox(height: 32),
          const Text(
            'COMPLETE YOUR PROFILE',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2),
          ),
          const SizedBox(height: 16),
          const Text(
            'Please complete your profile to get the most out of Desby.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 32),
          
          // Show what's missing
          _buildMissingFieldsList(profile),
          
          const SizedBox(height: 32),
          
          // Complete Profile Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/profile/edit', arguments: profile.id);
              },
              icon: const Icon(Icons.edit_rounded),
              label: const Text('COMPLETE PROFILE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amber,
                foregroundColor: const Color(0xFF0A1921),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Show basic info that is available
          _buildBasicProfileCard(profile),
        ],
      ),
    );
  }

  Widget _buildMissingFieldsList(UserProfile profile) {
    final missingFields = <String>[];
    
    if (profile.name.isEmpty || profile.name == 'New User') {
      missingFields.add('Full Name');
    }
    if (profile.phone == null || profile.phone!.isEmpty) {
      missingFields.add('Phone Number');
    }
    if (profile.address == null || profile.address!.isEmpty) {
      missingFields.add('Home Address');
    }
    if (profile.state == null || profile.state!.isEmpty) {
      missingFields.add('State');
    }
    if (profile.userType == 'tailor' && (profile.businessName == null || profile.businessName!.isEmpty)) {
      missingFields.add('Business Name');
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Missing Information:',
            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...missingFields.map((field) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 8, color: Colors.orange),
                const SizedBox(width: 8),
                Text(field, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildBasicProfileCard(UserProfile profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.amber.withValues(alpha: 0.1),
            backgroundImage: profile.profileImage != null 
                ? NetworkImage(profile.profileImage!) 
                : null,
            child: profile.profileImage == null
                ? Text(
                    profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 36, color: AppColors.amber, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            profile.name.isNotEmpty ? profile.name : 'Unnamed User',
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            profile.email,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// Build view for complete profile with real Firebase data
  Widget _buildCompleteProfileView(BuildContext context, UserProfile profile, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildHeader(profile),
          const SizedBox(height: 32),
          
          // Edit button for own profile
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/profile/edit', arguments: userId);
              },
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text('EDIT PROFILE'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.amber,
                side: const BorderSide(color: AppColors.amber),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Contact Information
          _buildContactInfo(profile),
          const SizedBox(height: 24),
          
          // Address Information
          if (profile.address != null || profile.state != null)
            _buildAddressInfo(profile),
          
          // Tailor-specific business info
          if (profile.userType == 'tailor')
            _buildTailorBusinessInfo(profile),
          
          // Fabric seller business info
          if (profile.userType == 'fabric_seller')
            _buildFabricSellerInfo(profile),
          
          const SizedBox(height: 32),
          
          // Logout button
          _buildLogoutButton(ref, context),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(UserProfile profile) {
    return Column(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: AppColors.amber.withValues(alpha: 0.1),
          backgroundImage: profile.profileImage != null 
              ? NetworkImage(profile.profileImage!) 
              : null,
          child: profile.profileImage == null
              ? Text(
                  profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 40, color: AppColors.amber, fontWeight: FontWeight.bold),
                )
              : null,
        ),
        const SizedBox(height: 16),
        Text(
          profile.name.isNotEmpty ? profile.name : 'Unnamed User',
          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            profile.userType.toUpperCase(),
            style: const TextStyle(
              color: AppColors.amber, 
              fontSize: 10, 
              fontWeight: FontWeight.w900, 
              letterSpacing: 1.5
            ),
          ),
        ),
        if (profile.isVerified) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_rounded, color: Colors.blue.shade300, size: 16),
              const SizedBox(width: 4),
              Text(
                'Verified Partner',
                style: TextStyle(color: Colors.blue.shade300, fontSize: 12),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildContactInfo(UserProfile profile) {
    return _buildInfoCard('Contact Information', [
      _buildInfoRow(Icons.email_outlined, 'Email', profile.email.isNotEmpty ? profile.email : 'Not provided'),
      _buildInfoRow(Icons.phone_outlined, 'Phone', profile.phone ?? 'Not provided'),
      if (profile.bio != null && profile.bio!.isNotEmpty)
        _buildInfoRow(Icons.info_outline, 'Bio', profile.bio!),
    ]);
  }

  Widget _buildAddressInfo(UserProfile profile) {
    return _buildInfoCard('Address', [
      if (profile.address != null && profile.address!.isNotEmpty)
        _buildInfoRow(Icons.home_outlined, 'Home', profile.address!),
      if (profile.state != null && profile.state!.isNotEmpty)
        _buildInfoRow(Icons.location_on_outlined, 'State', profile.state!),
      if (profile.lga != null && profile.lga!.isNotEmpty)
        _buildInfoRow(Icons.location_city_outlined, 'LGA', profile.lga!),
    ]);
  }

  Widget _buildTailorBusinessInfo(UserProfile profile) {
    return Column(
      children: [
        const SizedBox(height: 24),
_buildInfoCard('Business Details', [
          if (profile.businessName != null && profile.businessName!.isNotEmpty)
            _buildInfoRow(Icons.business_center_outlined, 'Business', profile.businessName!),
          if (profile.businessAddress != null && profile.businessAddress!.isNotEmpty)
            _buildInfoRow(Icons.storefront_outlined, 'Address', profile.businessAddress!),
          if (profile.businessPhone != null && profile.businessPhone!.isNotEmpty)
            _buildInfoRow(Icons.phone_in_talk_outlined, 'Business Phone', profile.businessPhone!),
          if (profile.workingHours != null && profile.workingHours!.isNotEmpty)
            _buildInfoRow(Icons.access_time, 'Operating Hours', profile.workingHours!),
        ]),
        if (profile.services != null && profile.services!.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildInfoCard('Services Offered', [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.services!.map((service) => Chip(
                label: Text(service, style: const TextStyle(fontSize: 12)),
                backgroundColor: AppColors.amber.withValues(alpha: 0.2),
                side: BorderSide.none,
              )).toList(),
            ),
          ]),
        ],
        if (profile.availableFabrics != null && profile.availableFabrics!.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildInfoCard('Available Fabrics', [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.availableFabrics!.map((fabric) => Chip(
                label: Text(fabric, style: const TextStyle(fontSize: 12)),
                backgroundColor: Colors.blue.withValues(alpha: 0.2),
                side: BorderSide.none,
              )).toList(),
            ),
          ]),
        ],
      ],
    );
  }

  Widget _buildFabricSellerInfo(UserProfile profile) {
    return Column(
      children: [
        const SizedBox(height: 24),
        _buildInfoCard('Shop Details', [
          if (profile.businessName != null && profile.businessName!.isNotEmpty)
            _buildInfoRow(Icons.store_outlined, 'Shop Name', profile.businessName!),
          if (profile.businessAddress != null && profile.businessAddress!.isNotEmpty)
            _buildInfoRow(Icons.location_on_outlined, 'Location', profile.businessAddress!),
          if (profile.businessPhone != null && profile.businessPhone!.isNotEmpty)
            _buildInfoRow(Icons.phone_outlined, 'Contact', profile.businessPhone!),
        ]),
      ],
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    // Filter out empty rows
final nonEmptyChildren = children.where((child) {
      if (child is Padding) {
        final childWidget = child.child;
        if (childWidget is Row) {
          final widgets = childWidget.children.toList();
          if (widgets.length >= 2) {
            final textWidget = widgets.last;
            if (textWidget is Expanded) {
              final column = textWidget.child;
              if (column is Column) {
                final text = (column.children.last as Text).data ?? '';
                return text != 'Not provided' && text.isNotEmpty;
              }
            }
          }
        }
      }
      return true;
    }).toList();

    if (nonEmptyChildren.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Colors.white38, 
              fontSize: 11, 
              fontWeight: FontWeight.w900, 
              letterSpacing: 2
            ),
          ),
          const SizedBox(height: 20),
          ...nonEmptyChildren,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.amber, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoProfileState(BuildContext context, WidgetRef ref, String userId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 60),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_sync_rounded, size: 60, color: AppColors.amber),
          ),
          const SizedBox(height: 32),
          const Text(
            'SYNC IN PROGRESS',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your profile is being synchronized from our servers.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 32),
          // Retry button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Invalidate and retry
                ref.invalidate(userProfileProvider(userId));
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('RETRY'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amber,
                foregroundColor: const Color(0xFF0A1921),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Create profile button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/profile/edit', arguments: userId);
              },
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('CREATE PROFILE'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.amber,
                side: const BorderSide(color: AppColors.amber),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error, WidgetRef ref, String userId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 60),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline_rounded, size: 60, color: Colors.red),
          ),
          const SizedBox(height: 32),
          const Text(
            'SYNC ERROR',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(userProfileProvider(userId));
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('RETRY'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amber,
                foregroundColor: const Color(0xFF0A1921),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/profile/edit', arguments: userId);
              },
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('CREATE PROFILE'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.amber,
                side: const BorderSide(color: AppColors.amber),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(WidgetRef ref, BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF0A1921),
              title: const Text('LOGOUT', style: TextStyle(color: Colors.white)),
              content: const Text(
                'Are you sure you want to logout?',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('LOGOUT', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
          
          if (confirmed == true) {
            await FirebaseAuth.instance.signOut();
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            }
          }
        },
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text('LOGOUT'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red.shade300,
          side: BorderSide(color: Colors.red.shade300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
