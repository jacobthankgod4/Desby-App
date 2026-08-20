import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../theme/colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final userType = user?.userType ?? 'tailor';

    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            _buildSectionHeader('ACCOUNT ARCHITECTURE'),
            _buildSettingsCard([
              _buildSettingsTile(
                icon: Icons.person_outline_rounded,
                title: 'Profile Details',
                subtitle: 'Manage your professional identity',
                onTap: () => ref.pushShell('/profile/edit', {'userId': user?.id}),
              ),
              _buildSettingsTile(
                icon: Icons.security_rounded,
                title: 'Security & Auth',
                subtitle: 'Manage passwords and verification',
                onTap: () {},
              ),
            ]),
            
            const SizedBox(height: 32),
            _buildSectionHeader('SYSTEM CONFIGURATION'),
            _buildSettingsCard([
              _buildSettingsTile(
                icon: Icons.straighten_rounded,
                title: 'Measurement Units',
                subtitle: 'Inches / Centimeters',
                onTap: () {},
              ),
              _buildSettingsTile(
                icon: Icons.notifications_active_outlined,
                title: 'Smart Notifications',
                subtitle: 'Configure real-time alerts',
                onTap: () {},
              ),
              _buildSettingsTile(
                icon: Icons.refresh_rounded,
                title: 'Reset Onboarding',
                subtitle: 'Re-start setup wizard',
                onTap: () => _showResetOnboardingDialog(context, ref, userType),
              ),
            ]),

            if (userType == 'tailor') ...[
              const SizedBox(height: 32),
              _buildSectionHeader('BUSINESS INFRASTRUCTURE'),
              _buildSettingsCard([
                _buildSettingsTile(
                  icon: Icons.storefront_rounded,
                  title: 'Designer Shop Setup',
                  subtitle: 'Manage your digital storefront',
                  onTap: () => ref.pushShell('/shop-setup'),
                ),
                _buildSettingsTile(
                  icon: Icons.school_rounded,
                  title: 'Invite Apprentice',
                  subtitle: 'Onboard new academy talent',
                  onTap: () => Navigator.pushNamed(context, '/apprentice-onboarding'),
                ),
                _buildSettingsTile(
                  icon: Icons.payments_outlined,
                  title: 'Secure Payments',
                  subtitle: 'Bank details and Paystack config',
                  onTap: () {},
                ),
              ]),
            ],

            const SizedBox(height: 32),
            _buildSectionHeader('OS RESOURCES'),
            _buildSettingsCard([
              _buildSettingsTile(
                icon: Icons.help_outline_rounded,
                title: 'Support Center',
                subtitle: 'Access technical documentation',
                onTap: () {},
              ),
              _buildSettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'About Desby OS',
                subtitle: 'System version 1.0.0+1',
                onTap: () {},
              ),
            ]),

            const SizedBox(height: 60),
            _buildLogoutButton(ref, context),
            const SizedBox(height: 40),
          ],
        ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 1000;
        if (isDesktop) {
          return Container(color: AppColors.darkNavy, child: content);
        }
        return Scaffold(
          backgroundColor: AppColors.darkNavy,
          appBar: AppBar(
            title: const Text('MASTER SETTINGS',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.amber, size: 18),
              onPressed: () {
            if (ref.canPopShell) {
              ref.popShell();
            } else {
              ref.setShell('/main');
            }
          },
            ),
          ),
          body: content,
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 12),
      child: Text(title, 
        style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon, 
    required String title, 
    required String subtitle, 
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.amber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.amber, size: 22),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white10, size: 14),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton(WidgetRef ref, BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: () async {
          await ref.read(authStateProvider.notifier).logout();
          if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        },
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text('LOGOUT OS SESSION', 
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
          foregroundColor: Colors.redAccent,
          elevation: 0,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.redAccent)),
        ),
      ),
    );
  }

  void _showResetOnboardingDialog(BuildContext context, WidgetRef ref, String userType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: const Text(
          'Reset Onboarding',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will reset your onboarding progress. You will need to complete the setup wizard again.\n\nAre you sure?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Clear onboarding flags based on user type
              switch (userType) {
                case 'tailor':
                  await localStorage.delete(StorageKeys.tailorOnboardingComplete);
                  break;
                case 'apprentice':
                  await localStorage.delete(StorageKeys.apprenticeOnboardingComplete);
                  break;
                case 'client':
                  await localStorage.delete(StorageKeys.clientOnboardingComplete);
                  break;
                case 'fabric_seller':
                  await localStorage.delete(StorageKeys.fabricSellerOnboardingComplete);
                  break;
              }
              
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                
                // Navigate to appropriate onboarding
                final route = userType == 'tailor' 
                    ? '/tailor-onboarding'
                    : userType == 'apprentice'
                        ? '/apprentice-onboarding'
                        : userType == 'client'
                            ? '/client-onboarding'
                            : '/fabric-seller-onboarding';
                
                Navigator.pushReplacementNamed(context, route);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amber,
              foregroundColor: AppColors.darkNavy,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
