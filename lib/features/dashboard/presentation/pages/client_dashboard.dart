import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../designs/presentation/providers/design_provider.dart';
import '../../../designs/domain/entities/design.dart';
import '../../../../core/widgets/luxury_glass_card.dart';
import '../../../../core/widgets/animated_entry.dart';
import '../../../../core/widgets/dashboard_shimmer.dart';
import '../../../../core/widgets/design_card_public.dart';
import '../../../../theme/colors.dart';
import '../../../../core/providers/navigation_provider.dart';

class ClientDashboard extends ConsumerStatefulWidget {
  const ClientDashboard({super.key});

  @override
  ConsumerState<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends ConsumerState<ClientDashboard> {
  List<Map<String, dynamic>> _activeOrders = [];
  List<Design> _recentlyViewed = [];
  List<Map<String, dynamic>> _pendingInvites = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    try {
      final ordersFuture = Supabase.instance.client
          .from('orders')
          .select()
          .eq('client_id', user.id)
          .not('status', 'in', '("delivered","cancelled")')
          .order('created_at', ascending: false)
          .limit(5);

      // Find pending invites for this user by phone number
      List<Map<String, dynamic>> invites = [];
      if (user.phone != null && user.phone!.isNotEmpty) {
        final rawInvites = await Supabase.instance.client
            .from('clients')
            .select('id, name, tailor_id, invite_token, invite_sent_at')
            .eq('phone', user.phone!)
            .eq('invite_status', 'pending')
            .order('invite_sent_at', ascending: false);

        // Fetch tailor names for each invite
        for (final invite in rawInvites) {
          final tailorId = invite['tailor_id'] as String?;
          String tailorName = 'A tailor';
          if (tailorId != null && tailorId.isNotEmpty) {
            final tailor = await Supabase.instance.client
                .from('users')
                .select('name')
                .eq('id', tailorId)
                .maybeSingle();
            if (tailor != null) {
              tailorName = (tailor['name'] as String?) ?? 'A tailor';
            }
          }
          invites.add({...invite, 'tailor_name': tailorName});
        }
      }

      final recentlyViewedIds = await _getRecentlyViewedIds();
      final designs = <Design>[];
      for (final id in recentlyViewedIds) {
        final result = await ref
            .read(designRepositoryProvider)
            .getDesignById(id);
        result.fold((failure) {
          debugPrint('[DASHBOARD] Design fetch failed: ${failure.message}');
        }, (d) => designs.add(d));
      }

      final results = await Future.wait([ordersFuture, Future.value(invites)]);
      final orders = results[0];
      final invitesList = results[1] as List;

      if (mounted) {
        setState(() {
          _activeOrders = List<Map<String, dynamic>>.from(orders as List);
          _pendingInvites = List<Map<String, dynamic>>.from(invitesList);
          _recentlyViewed = designs;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<List<String>> _getRecentlyViewedIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('recently_viewed') ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _loading = true;
          });
          await _loadData();
        },
        color: AppColors.amber,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedEntry(index: 0, child: _buildHeader(currentUser?.name)),
              const SizedBox(height: 24),

              // Stats
              AnimatedEntry(index: 1, child: _buildStatsRow()),
              const SizedBox(height: 32),

              // Pending Invites (if any)
              if (_pendingInvites.isNotEmpty) ...[
                AnimatedEntry(index: 2, child: _buildPendingInvitesSection()),
                const SizedBox(height: 32),
              ],

              // Active Orders
              AnimatedEntry(
                index: 2,
                child: _buildSectionHeader('Active Orders', '/orders'),
              ),
              const SizedBox(height: 14),
              AnimatedEntry(index: 3, child: _buildOrdersSection()),
              const SizedBox(height: 32),

              // Recently Viewed
              AnimatedEntry(
                index: 4,
                child: _buildSectionHeader('Recently Viewed', '/designs'),
              ),
              const SizedBox(height: 14),
              AnimatedEntry(index: 5, child: _buildRecentlyViewed()),
              const SizedBox(height: 32),

              // Explore Designs
              AnimatedEntry(
                index: 6,
                child: _buildSectionHeader('Explore Designs', '/designs'),
              ),
              const SizedBox(height: 14),
              AnimatedEntry(index: 7, child: _buildExploreDesigns()),
              const SizedBox(height: 32),

              // Body Measurements Card
              AnimatedEntry(index: 8, child: _buildMeasurementsCard()),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String? name) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DASHBOARD',
          style: TextStyle(
            color: AppColors.amber,
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Welcome, ${name ?? 'Client'}',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () => ref.pushShell('/tailor-discovery'),
          icon: const Icon(Icons.search_rounded, size: 18),
          label: const Text(
            'FIND A TAILOR',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.amber,
            foregroundColor: AppColors.darkNavy,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            value: '${_activeOrders.length}',
            label: 'ACTIVE ORDERS',
            icon: Icons.receipt_long_rounded,
            color: AppColors.amber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            value: '${_recentlyViewed.length}',
            label: 'RECENTLY VIEWED',
            icon: Icons.history_rounded,
            color: Colors.blueAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersSection() {
    if (_loading) {
      return DashboardShimmer(listCount: 2);
    }
    if (_activeOrders.isEmpty) {
      return _buildEmptyState(
        icon: Icons.receipt_long_rounded,
        title: 'NO ACTIVE ORDERS',
        subtitle: 'Find a tailor to place your first order',
      );
    }
    return Column(
      children: _activeOrders.map((order) {
        final status = order['status']?.toString() ?? 'pending';
        final garment =
            order['garment_type']?.toString() ??
            order['garmentType']?.toString() ??
            'Bespoke Item';
        final tailorName =
            order['tailor_name']?.toString() ??
            order['tailorName']?.toString() ??
            'Tailor';
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _OrderCard(
            garment: garment,
            status: status,
            tailorName: tailorName,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentlyViewed() {
    if (_loading) return DashboardShimmer(listCount: 1);
    if (_recentlyViewed.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history_rounded,
        title: 'NO RECENTLY VIEWED',
        subtitle: 'Browse designs to see them here',
      );
    }
    return SizedBox(
      height: 320,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _recentlyViewed.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final d = _recentlyViewed[index];
          return SizedBox(
            width: 220,
            child: DesignCardPublic(
              design: d,
              onTap: () => ref.pushShell('/design-details', {'design': d}),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExploreDesigns() {
    return ref
        .watch(designListProvider(null))
        .when(
          data: (designs) {
            if (designs.isEmpty) {
              return _buildEmptyState(
                icon: Icons.diamond_outlined,
                title: 'NO DESIGNS TO EXPLORE YET',
                subtitle: 'Try the Find a Tailor journey instead',
                actionLabel: 'FIND A TAILOR',
                onAction: () => ref.pushShell('/tailor-discovery'),
              );
            }
            final display = designs.length > 6
                ? designs.sublist(0, 6)
                : designs;
            return SizedBox(
              height: 320,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: display.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final d = display[index];
                  return SizedBox(
                    width: 220,
                    child: DesignCardPublic(
                      design: d,
                      onTap: () =>
                          ref.pushShell('/design-details', {'design': d}),
                    ),
                  );
                },
              ),
            );
          },
          loading: () => DashboardShimmer(listCount: 1),
          error: (_, _) => const SizedBox.shrink(),
        );
  }

  Widget _buildMeasurementsCard() {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => ref.pushShell('/measurements-profile'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppColors.deepBlue, AppColors.darkNavy]
                : [
                    AppColors.amber.withValues(alpha: 0.08),
                    AppColors.amber.withValues(alpha: 0.03),
                  ],
          ),
          border: Border.all(color: colors.borderDefault),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.straighten_rounded,
                color: AppColors.amber,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MY MEASUREMENTS',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'View and update your body measurements',
                    style: TextStyle(color: colors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: colors.textMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String route) {
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: colors.textMuted,
          ),
        ),
        GestureDetector(
          onTap: () => ref.setShell(route),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'VIEW ALL',
              style: TextStyle(
                color: AppColors.amber,
                fontWeight: FontWeight.w900,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final colors = context.colors;
    return LuxuryGlassCard(
      padding: const EdgeInsets.all(36),
      child: Center(
        child: Column(
          children: [
            Icon(icon, color: colors.textMuted, size: 36),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: colors.textMuted,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: colors.textMuted, fontSize: 10),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: onAction,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.amber,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    actionLabel,
                    style: const TextStyle(
                      color: AppColors.darkNavy,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPendingInvitesSection() {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.person_add_outlined,
                color: AppColors.amber,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'PENDING INVITES',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ..._pendingInvites.map((invite) => _buildInviteCard(invite)),
      ],
    );
  }

  Widget _buildInviteCard(Map<String, dynamic> invite) {
    final colors = context.colors;
    final tailorName = invite['tailor_name'] as String? ?? 'A tailor';
    final sentAt = invite['invite_sent_at'] != null
        ? DateTime.tryParse(invite['invite_sent_at'])
        : null;

    return LuxuryGlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person_add_rounded,
              color: AppColors.amber,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$tailorName has invited you!',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sentAt != null
                      ? 'Sent ${_formatDate(sentAt)}'
                      : 'Complete your profile to accept',
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              final token = invite['invite_token'] as String?;
              if (token != null) {
                Navigator.pushNamed(context, '/invite', arguments: token);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.amber.withValues(alpha: 0.3),
                ),
              ),
              child: const Text(
                'VIEW',
                style: TextStyle(
                  color: AppColors.amber,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.surfaceHover),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final String garment;
  final String status;
  final String tailorName;
  const _OrderCard({
    required this.garment,
    required this.status,
    required this.tailorName,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isPending = status == 'pending';
    final color = isPending ? Colors.orange : AppColors.amber;
    return LuxuryGlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.checkroom_rounded,
              color: AppColors.amber,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  garment.toUpperCase(),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'by $tailorName',
                  style: TextStyle(color: colors.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 7,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
