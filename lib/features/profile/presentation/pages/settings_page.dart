import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/providers/layout_provider.dart';
import '../../../../theme/colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/widgets/shell_app_bar.dart';
import '../../../../core/services/reauth_service.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final user = ref.watch(currentUserProvider);
    final userType = user?.userType ?? 'tailor';

    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'Account'),
          _buildSettingsCard(context, [
            _buildSettingsTile(
              context,
              icon: Icons.person_outline_rounded,
              title: 'Profile Details',
              subtitle: 'Manage your professional identity',
              onTap: () => ref.pushShell('/profile/edit', {'userId': user?.id}),
            ),
            _buildSettingsTile(
              context,
              icon: Icons.security_rounded,
              title: 'Security & Auth',
              subtitle: 'Change password',
              onTap: () => _showChangePasswordDialog(context),
            ),
            _buildSettingsTile(
              context,
              icon: Icons.delete_forever_rounded,
              title: 'Delete Account',
              subtitle: 'Permanently remove your data',
              onTap: () => _showDeleteAccountDialog(context, ref),
            ),
          ]),

          const SizedBox(height: 32),
          _buildSectionHeader(context, 'Preferences'),
          _buildSettingsCard(context, [
            _buildSettingsTile(
              context,
              icon: Icons.straighten_rounded,
              title: 'Measurement Units',
              subtitle: 'Inches / Centimeters',
              onTap: () => _showMeasurementUnitsDialog(context),
            ),
            _buildSettingsTile(
              context,
              icon: Icons.notifications_active_outlined,
              title: 'Smart Notifications',
              subtitle: 'Configure real-time alerts',
              onTap: () => _showNotificationsDialog(context),
            ),
            _buildSettingsTile(
              context,
              icon: Icons.refresh_rounded,
              title: 'Reset Onboarding',
              subtitle: 'Re-start setup wizard',
              onTap: () => _showResetOnboardingDialog(context, ref, userType),
            ),
          ]),

          if (userType == 'tailor' || userType == 'fabric_seller') ...[
            const SizedBox(height: 32),
            _buildSectionHeader(context, 'Your Business'),
            _buildSettingsCard(context, [
              if (userType == 'tailor') ...[
                _buildSettingsTile(
                  context,
                  icon: Icons.storefront_rounded,
                  title: 'Designer Shop Setup',
                  subtitle: 'Manage your digital storefront',
                  onTap: () => ref.pushShell('/shop-setup'),
                ),
                _buildSettingsTile(
                  context,
                  icon: Icons.school_rounded,
                  title: 'Invite Apprentice',
                  subtitle: 'Onboard new academy talent',
                  onTap: () => ref.pushShell('/unified-add-apprentice'),
                ),
              ],
              _buildSettingsTile(
                context,
                icon: Icons.payments_outlined,
                title: 'Secure Payments',
                subtitle: 'Bank details for receiving payouts',
                onTap: () => _showPaymentsInfo(context, ref),
              ),
            ]),
          ],

          const SizedBox(height: 32),
          _buildSectionHeader(context, 'Help & Info'),
          _buildSettingsCard(context, [
            _buildSettingsTile(
              context,
              icon: Icons.help_outline_rounded,
              title: 'Support Center',
              subtitle: 'Access technical documentation',
              onTap: () => _showSupportDialog(context),
            ),
            _buildSettingsTile(
              context,
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

    final isDesktop = ref.watch(isDesktopProvider);
    if (isDesktop) {
      return Container(color: colors.scaffoldBg, child: content);
    }
    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: shellAppBar(context, title: 'MASTER SETTINGS'),
      body: content,
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: colors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, List<Widget> children) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
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
      title: Text(
        title,
        style: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: colors.textMuted, fontSize: 11),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        color: colors.textMuted,
        size: 14,
      ),
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
          if (context.mounted)
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            );
        },
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text(
          'Log Out',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
          foregroundColor: Colors.redAccent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.redAccent),
          ),
        ),
      ),
    );
  }

  // --- DIALOGS ---

  void _showChangePasswordDialog(BuildContext context) {
    final colors = context.colors;

    showDialog(
      context: context,
      builder: (ctx) =>
          _ChangePasswordDialog(colors: colors, outerContext: context),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    showDialog(
      context: context,
      builder: (ctx) =>
          _DeleteAccountDialog(colors: colors, outerContext: context, ref: ref),
    );
  }

  void _showMeasurementUnitsDialog(BuildContext context) {
    final colors = context.colors;
    String selectedUnit = localStorage.get(
      'measurement_units',
      defaultValue: 'cm',
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: colors.scaffoldBg,
          title: Text(
            'Measurement Units',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioGroup<String>(
                groupValue: selectedUnit,
                onChanged: (v) =>
                    setDialogState(() => selectedUnit = v ?? selectedUnit),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<String>(
                      title: Text(
                        'Centimeters (cm)',
                        style: TextStyle(color: colors.textPrimary),
                      ),
                      value: 'cm',
                      activeColor: AppColors.amber,
                    ),
                    RadioListTile<String>(
                      title: Text(
                        'Inches (in)',
                        style: TextStyle(color: colors.textPrimary),
                      ),
                      value: 'in',
                      activeColor: AppColors.amber,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await localStorage.save('measurement_units', selectedUnit);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Units set to ${selectedUnit == 'cm' ? 'Centimeters' : 'Inches'}',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amber,
                foregroundColor: AppColors.darkNavy,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationsDialog(BuildContext context) {
    final colors = context.colors;
    bool orderUpdates = localStorage.get(
      'notif_order_updates',
      defaultValue: true,
    );
    bool clientMessages = localStorage.get(
      'notif_client_messages',
      defaultValue: true,
    );
    bool systemAlerts = localStorage.get(
      'notif_system_alerts',
      defaultValue: true,
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: colors.scaffoldBg,
          title: Text(
            'Notifications',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: Text(
                  'Order Updates',
                  style: TextStyle(color: colors.textPrimary, fontSize: 14),
                ),
                subtitle: Text(
                  'Status changes and delivery alerts',
                  style: TextStyle(color: colors.textMuted, fontSize: 11),
                ),
                value: orderUpdates,
                activeThumbColor: AppColors.amber,
                onChanged: (v) => setDialogState(() => orderUpdates = v),
              ),
              SwitchListTile(
                title: Text(
                  'Client Messages',
                  style: TextStyle(color: colors.textPrimary, fontSize: 14),
                ),
                subtitle: Text(
                  'New messages from clients',
                  style: TextStyle(color: colors.textMuted, fontSize: 11),
                ),
                value: clientMessages,
                activeThumbColor: AppColors.amber,
                onChanged: (v) => setDialogState(() => clientMessages = v),
              ),
              SwitchListTile(
                title: Text(
                  'System Alerts',
                  style: TextStyle(color: colors.textPrimary, fontSize: 14),
                ),
                subtitle: Text(
                  'App updates and maintenance',
                  style: TextStyle(color: colors.textMuted, fontSize: 11),
                ),
                value: systemAlerts,
                activeThumbColor: AppColors.amber,
                onChanged: (v) => setDialogState(() => systemAlerts = v),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                await localStorage.save('notif_order_updates', orderUpdates);
                await localStorage.save(
                  'notif_client_messages',
                  clientMessages,
                );
                await localStorage.save('notif_system_alerts', systemAlerts);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amber,
                foregroundColor: AppColors.darkNavy,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentsInfo(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Bank Details',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your bank details are used for receiving payouts when clients confirm delivery.',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'To update your bank details, go to Profile > Edit Profile > Bank Details section.',
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: TextStyle(color: colors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.pushShell('/profile/edit');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amber,
              foregroundColor: AppColors.darkNavy,
            ),
            child: const Text('Edit Profile'),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.scaffoldBg,
        title: Text(
          'Support Center',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Need help? Reach out to us:',
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            _infoRow(context, 'Email', 'support@desby.app'),
            _infoRow(context, 'Docs', 'docs.desby.app'),
            const SizedBox(height: 12),
            Text(
              'For urgent issues, include your User ID in the subject line.',
              style: TextStyle(color: colors.textMuted, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Close',
              style: TextStyle(color: AppColors.amber),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.scaffoldBg,
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 28),
            const SizedBox(width: 10),
            Text(
              'Desby OS',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow(context, 'Version', '1.0.0+1'),
            _infoRow(context, 'Build', 'Flutter Web'),
            _infoRow(context, 'Platform', 'Cross-platform'),
            const SizedBox(height: 12),
            Text(
              'The operating system for tailors and fashion entrepreneurs.',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Close',
              style: TextStyle(color: AppColors.amber),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showResetOnboardingDialog(
    BuildContext context,
    WidgetRef ref,
    String userType,
  ) {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.scaffoldBg,
        title: Text(
          'Reset Onboarding',
          style: TextStyle(color: colors.textPrimary),
        ),
        content: Text(
          'This will reset your onboarding progress. You will need to complete the setup wizard again.\n\nAre you sure?',
          style: TextStyle(color: colors.textSecondary),
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
                  await localStorage.delete(
                    StorageKeys.tailorOnboardingComplete,
                  );
                  break;
                case 'apprentice':
                  await localStorage.delete(
                    StorageKeys.apprenticeOnboardingComplete,
                  );
                  break;
                case 'client':
                  await localStorage.delete(
                    StorageKeys.clientOnboardingComplete,
                  );
                  break;
                case 'fabric_seller':
                  await localStorage.delete(
                    StorageKeys.fabricSellerOnboardingComplete,
                  );
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

                ref.setShell(route);
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

class _ChangePasswordDialog extends StatefulWidget {
  final dynamic colors;
  final BuildContext outerContext;

  const _ChangePasswordDialog({
    required this.colors,
    required this.outerContext,
  });

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  late final TextEditingController _emailController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return AlertDialog(
      backgroundColor: colors.scaffoldBg,
      title: Text(
        'Change Password',
        style: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'A password reset link will be sent to your email.',
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Your email',
                hintStyle: TextStyle(color: colors.textMuted),
                filled: true,
                fillColor: colors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.borderDefault),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.borderDefault),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.amber),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  if (_emailController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Enter your email'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  setState(() => _isLoading = true);
                  try {
                    await Supabase.instance.client.auth.resetPasswordForEmail(
                      _emailController.text.trim(),
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(widget.outerContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Password reset email sent! Check your inbox.',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Could not send reset email. Please try again.',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.amber,
            foregroundColor: AppColors.darkNavy,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send Reset Link'),
        ),
      ],
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  final dynamic colors;
  final BuildContext outerContext;
  final WidgetRef ref;

  const _DeleteAccountDialog({
    required this.colors,
    required this.outerContext,
    required this.ref,
  });

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  late final TextEditingController _passwordController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return AlertDialog(
      backgroundColor: colors.scaffoldBg,
      title: Text(
        'Delete Account',
        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w800),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action is permanent and cannot be undone.',
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              'All your data including profiles, orders, and client records will be permanently deleted.',
              style: TextStyle(color: colors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Confirm with your password',
                hintStyle: TextStyle(color: colors.textMuted),
                filled: true,
                fillColor: colors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.borderDefault),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.borderDefault),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.amber),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  if (_passwordController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Enter your password to confirm'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  setState(() => _isLoading = true);
                  try {
                    final user = widget.ref.read(currentUserProvider);
                    if (user == null) return;

                    final email =
                        Supabase.instance.client.auth.currentUser?.email ?? '';

                    // The previous call to signInWithPassword ignored its
                    // result. With MFA enabled that call returns no user and
                    // throws nothing, so the account was deleted without the
                    // identity ever being confirmed. ConfirmWithPassword
                    // requires a user in the response.
                    final confirmed = await ReauthService.instance
                        .confirmWithPassword(
                      email: email,
                      password: _passwordController.text,
                    );
                    if (!confirmed) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Could not confirm your identity. Please check your password and try again.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      return;
                    }

                    await Supabase.instance.client
                        .from('users')
                        .delete()
                        .eq('id', user.id);

                    await Supabase.instance.client.auth.admin.deleteUser(
                      user.id,
                    );
                    await localStorage.clearAll();

                    if (context.mounted) {
                      Navigator.pop(context);
                      await widget.ref
                          .read(authStateProvider.notifier)
                          .logout();
                      if (widget.outerContext.mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                          widget.outerContext,
                          '/login',
                          (route) => false,
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Could not delete account. Please check your password and try again.',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: context.colors.textPrimary,
          ),
          child: _isLoading
              ? SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.textPrimary,
                  ),
                )
              : const Text('Delete Permanently'),
        ),
      ],
    );
  }
}
