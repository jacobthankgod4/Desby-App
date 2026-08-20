import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
                subtitle: 'Change password',
                onTap: () => _showChangePasswordDialog(context),
              ),
              _buildSettingsTile(
                icon: Icons.delete_forever_rounded,
                title: 'Delete Account',
                subtitle: 'Permanently remove your data',
                onTap: () => _showDeleteAccountDialog(context, ref),
              ),
            ]),
            
            const SizedBox(height: 32),
            _buildSectionHeader('SYSTEM CONFIGURATION'),
            _buildSettingsCard([
              _buildSettingsTile(
                icon: Icons.straighten_rounded,
                title: 'Measurement Units',
                subtitle: 'Inches / Centimeters',
                onTap: () => _showMeasurementUnitsDialog(context),
              ),
              _buildSettingsTile(
                icon: Icons.notifications_active_outlined,
                title: 'Smart Notifications',
                subtitle: 'Configure real-time alerts',
                onTap: () => _showNotificationsDialog(context),
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
                  onTap: () => _showPaymentsInfo(context),
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
                onTap: () => _showSupportDialog(context),
              ),
              _buildSettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'About Desby OS',
                subtitle: 'System version 1.0.0+1',
                onTap: () => _showAboutDialog(context),
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

  // --- DIALOGS ---

  void _showChangePasswordDialog(BuildContext context) {
    final emailController = TextEditingController();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.darkNavy,
          title: const Text('Change Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'A password reset link will be sent to your email.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                ),
                const SizedBox(height: 20),
                _dialogTextField(controller: emailController, hint: 'Your email', keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (emailController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Enter your email'), backgroundColor: Colors.red));
                  return;
                }
                setDialogState(() => isLoading = true);
                try {
                  await Supabase.instance.client.auth.resetPasswordForEmail(emailController.text.trim());
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password reset email sent! Check your inbox.'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                  }
                } finally {
                  setDialogState(() => isLoading = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber, foregroundColor: AppColors.darkNavy),
              child: isLoading
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Send Reset Link'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    final passwordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.darkNavy,
          title: const Text('Delete Account', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This action is permanent and cannot be undone.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  'All your data including profiles, orders, and client records will be permanently deleted.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                ),
                const SizedBox(height: 20),
                _dialogTextField(controller: passwordController, hint: 'Confirm with your password', obscure: true),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Enter your password to confirm'), backgroundColor: Colors.red));
                  return;
                }
                setDialogState(() => isLoading = true);
                try {
                  final user = ref.read(currentUserProvider);
                  if (user == null) return;

                  // Re-authenticate first
                  final email = Supabase.instance.client.auth.currentUser?.email ?? '';
                  await Supabase.instance.client.auth.signInWithPassword(email: email, password: passwordController.text);

                  // Delete profile from database
                  await Supabase.instance.client.from('users').delete().eq('id', user.id);

                  // Delete auth account
                  await Supabase.instance.client.auth.admin.deleteUser(user.id);

                  // Clear local storage
                  await localStorage.clearAll();

                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    await ref.read(authStateProvider.notifier).logout();
                    if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                      content: Text('Delete failed: ${e.toString().contains('Invalid login') ? 'Incorrect password' : e}'),
                      backgroundColor: Colors.red,
                    ));
                  }
                } finally {
                  setDialogState(() => isLoading = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              child: isLoading
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Delete Permanently'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMeasurementUnitsDialog(BuildContext context) {
    String selectedUnit = localStorage.get('measurement_units', defaultValue: 'cm');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.darkNavy,
          title: const Text('Measurement Units', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Centimeters (cm)', style: TextStyle(color: Colors.white)),
                value: 'cm',
                groupValue: selectedUnit,
                activeColor: AppColors.amber,
                onChanged: (v) => setDialogState(() => selectedUnit = v!),
              ),
              RadioListTile<String>(
                title: const Text('Inches (in)', style: TextStyle(color: Colors.white)),
                value: 'in',
                groupValue: selectedUnit,
                activeColor: AppColors.amber,
                onChanged: (v) => setDialogState(() => selectedUnit = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              onPressed: () async {
                await localStorage.save('measurement_units', selectedUnit);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Units set to ${selectedUnit == 'cm' ? 'Centimeters' : 'Inches'}'), backgroundColor: Colors.green),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber, foregroundColor: AppColors.darkNavy),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationsDialog(BuildContext context) {
    bool orderUpdates = localStorage.get('notif_order_updates', defaultValue: true);
    bool clientMessages = localStorage.get('notif_client_messages', defaultValue: true);
    bool systemAlerts = localStorage.get('notif_system_alerts', defaultValue: true);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.darkNavy,
          title: const Text('Notifications', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Order Updates', style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: const Text('Status changes and delivery alerts', style: TextStyle(color: Colors.white38, fontSize: 11)),
                value: orderUpdates,
                activeColor: AppColors.amber,
                onChanged: (v) => setDialogState(() => orderUpdates = v),
              ),
              SwitchListTile(
                title: const Text('Client Messages', style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: const Text('New messages from clients', style: TextStyle(color: Colors.white38, fontSize: 11)),
                value: clientMessages,
                activeColor: AppColors.amber,
                onChanged: (v) => setDialogState(() => clientMessages = v),
              ),
              SwitchListTile(
                title: const Text('System Alerts', style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: const Text('App updates and maintenance', style: TextStyle(color: Colors.white38, fontSize: 11)),
                value: systemAlerts,
                activeColor: AppColors.amber,
                onChanged: (v) => setDialogState(() => systemAlerts = v),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                await localStorage.save('notif_order_updates', orderUpdates);
                await localStorage.save('notif_client_messages', clientMessages);
                await localStorage.save('notif_system_alerts', systemAlerts);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber, foregroundColor: AppColors.darkNavy),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentsInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: const Text('Secure Payments', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payments are processed securely via Paystack.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
            ),
            const SizedBox(height: 16),
            _infoRow('Status', 'Active'),
            _infoRow('Gateway', 'Paystack'),
            _infoRow('Currency', 'NGN'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: AppColors.amber))),
        ],
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: const Text('Support Center', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Need help? Reach out to us:',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
            ),
            const SizedBox(height: 16),
            _infoRow('Email', 'support@desby.app'),
            _infoRow('Docs', 'docs.desby.app'),
            const SizedBox(height: 12),
            Text(
              'For urgent issues, include your User ID in the subject line.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: AppColors.amber))),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 28),
            const SizedBox(width: 10),
            const Text('Desby OS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Version', '1.0.0+1'),
            _infoRow('Build', 'Flutter Web'),
            _infoRow('Platform', 'Cross-platform'),
            const SizedBox(height: 12),
            Text(
              'The operating system for tailors and fashion entrepreneurs.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: AppColors.amber))),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _dialogTextField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.amber),
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
