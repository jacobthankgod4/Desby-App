import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desby_app/theme/colors.dart';
import '../providers/client_provider.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/luxury_glass_card.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../domain/entities/client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ClientListPage extends ConsumerStatefulWidget {
  const ClientListPage({super.key});

  @override
  ConsumerState<ClientListPage> createState() => _ClientListPageState();
}

class _ClientListPageState extends ConsumerState<ClientListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final user = ref.watch(currentUserProvider);
    final tailorId = user?.id ?? '';
    final clientsAsync = ref.watch(
      clientsProvider((tailorId: tailorId, query: _query)),
    );

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: clientsAsync.when(
              data: (clients) => clients.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                      itemCount: clients.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final client = clients[index];
                        return _ClientLuxuryCard(client: client);
                      },
                    ),
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: AppColors.amber,
                  strokeWidth: 2,
                ),
              ),
              error: (err, _) =>
                  const ErrorStateWidget(message: 'Profile sync failed.'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: colors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search clients...',
          hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.amber,
            size: 20,
          ),
          filled: true,
          fillColor: colors.surfaceHover,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) => setState(() => _query = value),
      ),
    );
  }

  Widget _buildEmptyState() {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_alt_outlined, size: 64, color: colors.borderSubtle),
          const SizedBox(height: 24),
          Text(
            'NO CLIENTS YET',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientLuxuryCard extends StatelessWidget {
  final Client client;
  const _ClientLuxuryCard({required this.client});

  Color _inviteBadgeColor(InviteStatus status) {
    switch (status) {
      case InviteStatus.pending:
        return Colors.amber;
      case InviteStatus.accepted:
        return AppColors.successGreen;
      case InviteStatus.expired:
        return AppColors.error;
      case InviteStatus.none:
        return Colors.transparent;
    }
  }

  String _inviteBadgeLabel(InviteStatus status) {
    switch (status) {
      case InviteStatus.pending:
        return 'PENDING';
      case InviteStatus.accepted:
        return 'ACCEPTED';
      case InviteStatus.expired:
        return 'EXPIRED';
      case InviteStatus.none:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final String initial = client.name.isNotEmpty
        ? client.name[0].toUpperCase()
        : 'C';
    final bool hasInvite = client.hasInvite;
    final InviteStatus status = client.inviteStatus;

    return LuxuryGlassCard(
      padding: const EdgeInsets.all(16),
      child: Consumer(
        builder: (context, ref, child) => InkWell(
          onTap: () {
            ref.pushShell('/client-detail', {'clientId': client.id});
          },
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.amber.withValues(alpha: 0.2),
                  ),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: AppColors.amber,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            client.name.toUpperCase(),
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasInvite)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _inviteBadgeColor(
                                status,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _inviteBadgeColor(
                                  status,
                                ).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              _inviteBadgeLabel(status),
                              style: TextStyle(
                                color: _inviteBadgeColor(status),
                                fontSize: 7,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_rounded,
                          color: colors.textMuted,
                          size: 10,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          client.phone,
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: colors.borderSubtle,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
