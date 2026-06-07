import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../theme/colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/fabric_provider.dart';
import '../widgets/fabric_card_grid.dart';

class MarketplaceFavoritesPage extends ConsumerWidget {
  const MarketplaceFavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: Center(child: Text('Please login to view favorites')));

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      appBar: AppBar(
        title: const Text('FAVOURITES', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.amber, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('favorites').doc(user.id).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.amber));
          
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _buildEmptyState(context);
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final fabricIds = (data['fabricIds'] as List? ?? []).cast<String>();

          if (fabricIds.isEmpty) return _buildEmptyState(context);

          return _FavoritesGrid(fabricIds: fabricIds);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border_rounded, size: 80, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 24),
          const Text('NO SAVED FABRICS', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('EXPLORE MARKETPLACE', style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _FavoritesGrid extends ConsumerWidget {
  final List<String> fabricIds;
  const _FavoritesGrid({required this.fabricIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We need to fetch all fabrics in the list. For this audit, we'll use the existing catalog
    // but filter by the IDs. A production app would use a specific 'getMany' query.
    final fabricsAsync = ref.watch(fabricCatalogProvider('All'));

    return fabricsAsync.when(
      data: (allFabrics) {
        final favorites = allFabrics.where((f) => fabricIds.contains(f.id)).toList();
        
        if (favorites.isEmpty) {
          return const Center(child: Text('No active listings found for your favorites.', style: TextStyle(color: Colors.white38)));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: FabricCardGrid(isGridView: true, fabrics: favorites),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amber)),
      error: (e, _) => Center(child: Text('Sync Error: $e', style: const TextStyle(color: Colors.white38))),
    );
  }
}
