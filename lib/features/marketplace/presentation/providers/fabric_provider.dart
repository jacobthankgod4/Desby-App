import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/supabase_fabric_repository.dart';
import '../../domain/entities/fabric.dart';
import '../../domain/repositories/fabric_repository.dart';

final fabricRepositoryProvider = Provider<FabricRepository>((ref) {
  return SupabaseFabricRepository();
});

final fabricCatalogProvider = StreamProvider.family<List<Fabric>, String?>((ref, category) {
  final repo = ref.watch(fabricRepositoryProvider);
  return repo.streamCatalog(category: category);
});

final sellerInventoryProvider = FutureProvider.family<List<Fabric>, String>((ref, sellerId) async {
  final repo = ref.watch(fabricRepositoryProvider);
  final result = await repo.getSellerInventory(sellerId);
  return result.fold(
    (failure) => throw Exception('Unable to load inventory. Please check your connection.'),
    (fabrics) => fabrics,
  );
});

final fabricByIdProvider = FutureProvider.family<Fabric, String>((ref, fabricId) async {
  final repo = ref.watch(fabricRepositoryProvider);
  final result = await repo.getFabricById(fabricId);
  return result.fold(
    (failure) => throw Exception('Fabric not found or unavailable.'),
    (fabric) => fabric,
  );
});

final merchantStatsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, merchantId) async {
  final repo = ref.watch(fabricRepositoryProvider);
  final result = await repo.getMerchantStats(merchantId);
  return result.fold(
    (failure) => throw Exception('Unable to load merchant stats.'),
    (stats) => stats,
  );
});
