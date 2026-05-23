import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firebase_fabric_repository.dart';
import '../../domain/entities/fabric.dart';
import '../../domain/repositories/fabric_repository.dart';

final fabricRepositoryProvider = Provider<FabricRepository>((ref) {
  return FirebaseFabricRepository();
});

final fabricCatalogProvider = StreamProvider.family<List<Fabric>, String?>((ref, category) {
  final repo = ref.watch(fabricRepositoryProvider);
  return repo.streamCatalog(category: category);
});

final sellerInventoryProvider = FutureProvider.family<List<Fabric>, String>((ref, sellerId) async {
  final repo = ref.watch(fabricRepositoryProvider);
  final result = await repo.getSellerInventory(sellerId);
  return result.fold(
    (failure) => throw failure.message,
    (fabrics) => fabrics,
  );
});
