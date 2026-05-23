import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/client_provider.dart';
import '../../../../core/widgets/error_state_widget.dart';

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
      backgroundColor: Colors.transparent, // Maintain background of parent if embedded
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search clients...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                fillColor: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.5),
                filled: true,
              ),
              onChanged: (value) {
                setState(() => _query = value);
              },
            ),
          ),
          Expanded(
            child: clientsAsync.when(
              data: (clients) => clients.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('No clients found', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: clients.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final client = clients[index];
                        final initial = client.name.isNotEmpty ? client.name[0].toUpperCase() : 'C';
                        
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(initial),
                            ),
                            title: Text(client.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(client.phone),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/client-detail',
                                arguments: client.id,
                              );
                            },
                          ),
                        );
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) {
                // Surface the real error so we can debug Firestore/auth/web interop issues.
                debugPrint('[ClientListPage] Failed to load clients: $err');
                return ErrorStateWidget(
                  message: 'Could not load your client list.\n$err',
                  icon: Icons.error_outline,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
