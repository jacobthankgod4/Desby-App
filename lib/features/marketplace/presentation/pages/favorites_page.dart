import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../theme/colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/fabric_provider.dart';
import '../widgets/fabric_card_grid.dart';
import '../widgets/garment_favourite_card.dart';
import '../../../tailor/presentation/providers/tailor_finder_provider.dart';

/// Unified Favorites Page - Shows Both Fabrics and Tailors
class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

@override
  void initState() {
    super.initState();
    // THREE TYPE FAVOURITES: Fabrics, Tailors, Garments
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

@override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.darkNavy,
        body: Center(child: Text('Please login', style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      appBar: AppBar(
        backgroundColor: AppColors.darkNavy,
        elevation: 0,
        title: const Text('MY FAVOURITES', style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        )),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.amber, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.amber,
          labelColor: AppColors.amber,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
          tabs: const [
            Tab(text: 'FABRICS'),
            Tab(text: 'TAILORS'),
            Tab(text: 'GARMENTS'),
          ],
        ),
      ),
body: TabBarView(
        controller: _tabController,
        children: [
          _FabricsFavoritesTab(userId: user.id),
          _TailorsFavoritesTab(userId: user.id),
          // THREE TYPE FAVOURITES: New third tab for garments
          _GarmentsFavoritesTab(userId: user.id),
        ],
      ),
    );
  }
}

/// Tab 1: Fabric Favorites (from Firestore)
class _FabricsFavoritesTab extends ConsumerWidget {
  final String userId;
  const _FabricsFavoritesTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('favorites').doc(userId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.amber));
        
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildEmptyState(context, 'FABRIC');
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final fabricIds = (data['fabricIds'] as List? ?? []).cast<String>();

        if (fabricIds.isEmpty) return _buildEmptyState(context, 'FABRIC');

        final fabricsAsync = ref.watch(fabricCatalogProvider(const CatalogFilter(category: 'All')));

        return fabricsAsync.when(
          data: (allFabrics) {
            final favorites = allFabrics.where((f) => fabricIds.contains(f.id)).toList();
            if (favorites.isEmpty) {
              return Center(child: Text('No active listings', style: TextStyle(color: Colors.white38)));
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FabricCardGrid(isGridView: true, fabrics: favorites),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amber)),
          error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, String type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border_rounded, size: 80, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 24),
          Text('NO SAVED $type', style: const TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 12),
TextButton(
            onPressed: () {
              if (type == 'FABRIC') {
                Navigator.pushNamed(context, '/marketplace');
              } else {
                // Navigate to /tailor-finder which loads full client dashboard shell
                Navigator.pushNamed(context, '/tailor-finder');
              }
            },
            child: Text('EXPLORE ${type}S', style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

/// Tab 2: Tailor Favorites (from Firestore)
class _TailorsFavoritesTab extends ConsumerWidget {
  final String userId;
  const _TailorsFavoritesTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('tailor_favorites').doc(userId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.amber));
        
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildEmptyTailorsState(context);
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final tailorIds = (data['tailorIds'] as List? ?? []).cast<String>();

        if (tailorIds.isEmpty) return _buildEmptyTailorsState(context);

// Fetch tailors from provider
        final tailorsAsync = ref.watch(tailorsFromFirestoreProvider);

        return tailorsAsync.when(
          data: (allTailors) {
            final favorites = allTailors.where((t) => tailorIds.contains(t['id'])).toList();
            if (favorites.isEmpty) {
              return const Center(child: Text('No active tailors found', style: TextStyle(color: Colors.white38)));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final tailor = favorites[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildTailorCard(context, tailor),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amber)),
          error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
        );
      },
    );
  }

  Widget _buildEmptyTailorsState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border_rounded, size: 80, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 24),
          const Text('NO SAVED TAILORS', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 12),
TextButton(
            onPressed: () {
              // Navigate to /tailor-finder which loads full client dashboard shell
              Navigator.pushNamed(context, '/tailor-finder');
            },
            child: const Text('FIND TAILORS', style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

Widget _buildTailorCard(BuildContext context, Map<String, dynamic> tailor) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/tailor-profile', arguments: tailor),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  (tailor['name'] ?? 'T')[0].toString().toUpperCase(),
                  style: const TextStyle(color: AppColors.amber, fontSize: 24, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (tailor['name'] ?? 'Unknown').toString().toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: AppColors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        tailor['rating']?.toString() ?? '4.5',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.location_on_rounded, color: Colors.white38, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          tailor['location'] ?? 'Nigeria',
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.amber, size: 16),
          ],
        ),
      ),
    );
  }
}

/// Tab 3: Garment Favorites (Ready-to-Wear) - THREE TYPE FAVOURITES
class _GarmentsFavoritesTab extends ConsumerWidget {
  final String userId;
  
  const _GarmentsFavoritesTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('garment_favorites').doc(userId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.amber));
        
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildEmptyGarmentsState(context, ref);
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final garmentIds = (data['garmentIds'] as List? ?? []).cast<String>();

        if (garmentIds.isEmpty) return _buildEmptyGarmentsState(context, ref);

        // Load garments from Firestore
        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('garments')
              .where(FieldPath.documentId, whereIn: garmentIds)
              .get(),
          builder: (context, snap) {
            if (snap.hasError) return Center(child: Text('Error: ${snap.error}', style: const TextStyle(color: Colors.red)));
            if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.amber));
            
            final garments = snap.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
            
            if (garments.isEmpty) return _buildEmptyGarmentsState(context, ref);
            
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: garments.length,
              itemBuilder: (context, index) {
                final garment = garments[index];
                return GarmentFavouriteCard(
                  garment: garment,
                  onTap: () {
                    // Navigate to garment detail page
                    Navigator.pushNamed(context, '/garment-detail', arguments: garment);
                  },
                  onRemove: () => _removeGarmentFavorite(context, ref, garment['id']),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyGarmentsState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.checkroom_rounded, size: 80, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 24),
          const Text('NO SAVED GARMENTS', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/marketplace'),
            child: const Text('BROWSE STYLES', style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Future<void> _removeGarmentFavorite(BuildContext context, WidgetRef ref, String garmentId) async {
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;
      
      await FirebaseFirestore.instance.collection('garment_favorites').doc(user.id).update({
        'garmentIds': FieldValue.arrayRemove([garmentId]),
      });
    } catch (e) {
      // Handle error silently
    }
  }
}
