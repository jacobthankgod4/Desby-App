import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/client_provider.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/luxury_glass_card.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../theme/colors.dart';

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
    final clientsAsync = ref.watch(clientsProvider(_query));

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
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
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final client = clients[index];
                        return _ClientLuxuryCard(client: client);
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amber, strokeWidth: 2)),
              error: (err, _) => const ErrorStateWidget(message: 'Profile sync failed.'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'SEARCH CLIENT DATABASE',
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.amber, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_alt_outlined, size: 64, color: Colors.white.withValues(alpha: 0.05)),
          const SizedBox(height: 24),
          const Text('DATABASE CLEAR', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
        ],
      ),
    );
  }
}

class _ClientLuxuryCard extends StatelessWidget {
  final dynamic client;
  const _ClientLuxuryCard({required this.client});

  @override
  Widget build(BuildContext context) {
    final String initial = client.name.isNotEmpty ? client.name[0].toUpperCase() : 'C';

    return LuxuryGlassCard(
      padding: const EdgeInsets.all(16),
      child: Consumer(
        builder: (context, ref, child) => InkWell(
          onTap: () {
            ref.read(navigationProvider.notifier).state = NavigationState(
              '/client-detail',
              {'clientId': client.id},
            );
          },
          child: Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.amber.withValues(alpha: 0.2)),
                ),
                child: Center(child: Text(initial, style: const TextStyle(color: AppColors.amber, fontSize: 20, fontWeight: FontWeight.w900))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(client.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone_rounded, color: Colors.white24, size: 10),
                        const SizedBox(width: 6),
                        Text(client.phone, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white10, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
