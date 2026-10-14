import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../theme/colors.dart';
import '../../../../theme/spacing.dart';
import '../../../../theme/typography.dart';
import '../../data/admin_service.dart';

final adminServiceProvider = Provider<AdminService>((ref) => AdminService());

/// Admin console.
///
/// Every action here is a server call: reads are gated by RLS, decisions go
/// through SECURITY DEFINER functions that re-check the admin role, and document
/// viewing mints a short-lived signed URL that is written to the audit log.
/// Nothing about an admin session is trusted by the client.
class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this);

  bool _loading = true;
  bool _isAdmin = false;
  String? _error;
  Map<String, dynamic> _overview = const {};

  List<ReviewQueueItem> _identityQueue = const [];
  List<ReviewQueueItem> _addressQueue = const [];
  List<AdminUserRow> _users = const [];
  List<Map<String, dynamic>> _orders = const [];
  List<Map<String, dynamic>> _audit = const [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final service = ref.read(adminServiceProvider);
    setState(() => _loading = true);

    final isAdmin = await service.isAdmin();
    if (!mounted) return;

    if (!isAdmin) {
      setState(() {
        _isAdmin = false;
        _loading = false;
        _error = 'This area is restricted to administrators.';
      });
      return;
    }

    try {
      final overview = await service.overview();
      final identity = await service.identityQueue();
      final address = await service.addressQueue();
      final users = await service.users();
      final orders = await service.orders();
      final audit = await service.auditTrail();
      if (!mounted) return;

      setState(() {
        _isAdmin = true;
        _loading = false;
        _error = null;
        _overview = overview;
        _identityQueue = identity.getOrNull() ?? const [];
        _addressQueue = address.getOrNull() ?? const [];
        _users = users.getOrNull() ?? const [];
        _orders = orders.getOrNull() ?? const [];
        _audit = audit.getOrNull() ?? const [];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Review actions
  // ---------------------------------------------------------------------------

  Future<void> _viewDocument(ReviewQueueItem item) async {
    final service = ref.read(adminServiceProvider);
    final url = await service.documentUrl(item.storagePath);
    if (!mounted) return;

    if (url == null) {
      // Address proofs submitted as a note have no file.
      _snack('No document file — this proof was submitted as a note.', Colors.orange);
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) _snack('Could not open the document.', Colors.red);
    }
  }

  Future<void> _decide(ReviewQueueItem item, bool approve, {bool isAddress = false}) async {
    String? reason;
    if (!approve) {
      reason = await _askReason();
      if (reason == null) return;
    }

    final service = ref.read(adminServiceProvider);
    final result = isAddress
        ? await service.decideAddress(item.id, approve ? 'verified' : 'rejected',
            reason: reason)
        : await service.decideIdentity(item.id, approve ? 'verified' : 'rejected',
            reason: reason);

    if (!mounted) return;
    result.fold(
      (failure) => _snack('Decision failed: ${failure.message}', Colors.red),
      (_) => _snack(
        approve ? 'Verified.' : 'Rejected.',
        approve ? Colors.green : Colors.orange,
      ),
    );
    await _loadAll();
  }

  Future<String?> _askReason() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reason for rejection'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Shown to the user so they know what to fix',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    return (reason == null || reason.isEmpty) ? null : reason;
  }

  void _snack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 44, color: colors.textMuted),
                const SizedBox(height: 12),
                Text(
                  _error ?? 'Not authorised.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textMuted),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin console'),
        actions: [
          IconButton(
            onPressed: _inviteUser,
            icon: const Icon(Icons.person_add_alt_rounded),
            tooltip: 'Invite a user',
          ),
          IconButton(
            onPressed: _loadAll,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: [
            const Tab(text: 'Overview'),
            Tab(text: 'Identity (${_identityQueue.length})'),
            Tab(text: 'Address (${_addressQueue.length})'),
            const Tab(text: 'Users'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _overviewTab(colors),
          _queueTab(colors, _identityQueue, isAddress: false),
          _queueTab(colors, _addressQueue, isAddress: true),
          _usersTab(colors),
        ],
      ),
    );
  }

  Widget _overviewTab(DesbyThemeColors colors) => RefreshIndicator(
        onRefresh: _loadAll,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _stat(colors, 'Users', _overview['users_total']),
                _stat(colors, 'Tailors', _overview['tailors']),
                _stat(colors, 'Orders', _overview['orders_total']),
                _stat(colors, 'Open orders', _overview['orders_open']),
                _stat(colors, 'KYC verified', _overview['kyc_verified']),
                _stat(colors, 'KYC pending', _overview['kyc_pending']),
                _stat(colors, 'Address pending', _overview['address_pending']),
                _stat(colors, 'Payouts pending', _overview['payouts_pending']),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Money', style: AppTypography.subtitle1.copyWith(
              color: colors.textPrimary, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            _money(colors, 'Gross collected', _overview['gross_value']),
            _money(colors, 'Awaiting payout', _overview['payouts_value']),
            const SizedBox(height: AppSpacing.lg),
            Text('Recent orders', style: AppTypography.subtitle1.copyWith(
              color: colors.textPrimary, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            if (_orders.isEmpty)
              _empty(colors, 'No orders yet.')
            else
              for (final o in _orders.take(10))
                ListTile(
                  dense: true,
                  title: Text('${o['reference'] ?? o['id'] ?? ''}'),
                  subtitle: Text(
                    '${o['status'] ?? '-'} · ${o['payment_status'] ?? '-'}',
                    style: AppTypography.caption,
                  ),
                  trailing: Text(_naira(o['total_amount'])),
                ),
            const SizedBox(height: AppSpacing.lg),
            Text('Admin activity', style: AppTypography.subtitle1.copyWith(
              color: colors.textPrimary, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            if (_audit.isEmpty)
              _empty(colors, 'No privileged actions recorded yet.')
            else
              for (final a in _audit.take(15))
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.history, size: 18),
                  title: Text(a['action']?.toString() ?? ''),
                  subtitle: Text(a['created_at']?.toString() ?? '',
                      style: AppTypography.caption),
                ),
          ],
        ),
      );

  Widget _queueTab(
    DesbyThemeColors colors,
    List<ReviewQueueItem> items, {
    required bool isAddress,
  }) =>
      RefreshIndicator(
        onRefresh: _loadAll,
        child: items.isEmpty
            ? ListView(children: [_empty(colors, 'Queue is clear.')])
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.sm),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final item = items[i];
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: colors.containerFill,
                      child: Text(
                        _initials(item.userName),
                        style: TextStyle(
                            color: colors.textPrimary, fontSize: 13),
                      ),
                    ),
                    title: Text(item.userName),
                    subtitle: Text(
                      '${item.docType}'
                      '${item.docLast4 != null ? ' ····${item.docLast4}' : ''}\n'
                      '${item.userEmail} · ${_ago(item.submittedAt)}',
                      style: AppTypography.caption,
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'View document',
                          icon: const Icon(Icons.visibility, size: 20),
                          onPressed: () => _viewDocument(item),
                        ),
                        IconButton(
                          tooltip: 'Reject',
                          icon: const Icon(Icons.close, size: 20, color: Colors.red),
                          onPressed: () => _decide(item, false, isAddress: isAddress),
                        ),
                        IconButton(
                          tooltip: 'Verify',
                          icon: const Icon(Icons.check, size: 20, color: Colors.green),
                          onPressed: () => _decide(item, true, isAddress: isAddress),
                        ),
                      ],
                    ),
                  );
                },
              ),
      );

  /// Invites someone to create an account. Sends the "Invite user" email
  /// template, the only place in the app that triggers it.
  Future<void> _inviteUser() async {
    final controller = TextEditingController();

    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Invite a user'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email address',
            hintText: 'name@example.com',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Send invitation'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (email == null || email.trim().isEmpty) return;

    final res = await ref.read(adminServiceProvider).inviteUser(email: email);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          // fold(onFailure, onSuccess)
          res.fold(
            (f) => f.message,
            (_) => 'Invitation sent to ${email.trim()}',
          ),
        ),
      ),
    );
  }

  Widget _usersTab(DesbyThemeColors colors) => RefreshIndicator(
        onRefresh: _loadAll,
        child: _users.isEmpty
            ? ListView(children: [_empty(colors, 'No users.')])
            : ListView.separated(
                itemCount: _users.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final u = _users[i];
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: colors.containerFill,
                      child: Text(_initials(u.name ?? u.email ?? '?'),
                          style: TextStyle(color: colors.textPrimary, fontSize: 13)),
                    ),
                    title: Text(u.businessName ?? u.name ?? '(no name)'),
                    subtitle: Text(
                      '${u.email ?? ''}\n${u.userType ?? ''} · KYC: ${u.identityStatus}'
                      '${u.canReceivePayouts ? ' · can receive payouts' : ''}',
                      style: AppTypography.caption,
                    ),
                    isThreeLine: true,
                    trailing: _badge(u.identityStatus),
                  );
                },
              ),
      );

  // ---------------------------------------------------------------------------
  // Small helpers
  // ---------------------------------------------------------------------------

  Widget _stat(DesbyThemeColors colors, String label, Object? value) => Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.containerFill,
          borderRadius: BorderRadius.circular(AppSpacing.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.caption.copyWith(color: colors.textMuted)),
            const SizedBox(height: 4),
            Text(
              '${value ?? 0}',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );

  Widget _money(DesbyThemeColors colors, String label, Object? value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.body2.copyWith(color: colors.textPrimary)),
            Text(_naira(value),
                style: AppTypography.body2.copyWith(
                    color: colors.textPrimary, fontWeight: FontWeight.w700)),
          ],
        ),
      );

  Widget _badge(String status) {
    final color = switch (status) {
      'verified' => Colors.green,
      'pending' => Colors.blue,
      'rejected' => Colors.red,
      'expired' => Colors.orange,
      _ => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(status,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  Widget _empty(DesbyThemeColors colors, String message) => Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(message, style: TextStyle(color: colors.textMuted)),
        ),
      );

  String _naira(Object? v) {
    final n = (v is num) ? v : double.tryParse('${v ?? 0}') ?? 0;
    return '₦${n.toStringAsFixed(0)}';
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}
