import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/supabase_fabric_repository.dart';
import '../../domain/entities/fabric.dart';
import '../../domain/repositories/fabric_repository.dart';
import '../../domain/usecases/stream_catalog_usecase.dart';
import '../../domain/usecases/get_seller_inventory_usecase.dart';
import '../../domain/usecases/get_fabric_by_id_usecase.dart';
import '../../domain/usecases/get_merchant_stats_usecase.dart';

final fabricRepositoryProvider = Provider<FabricRepository>((ref) {
  return SupabaseFabricRepository();
});

final streamCatalogUsecaseProvider = Provider<StreamCatalogUsecase>((ref) {
  return StreamCatalogUsecase(ref.watch(fabricRepositoryProvider));
});

final getSellerInventoryUsecaseProvider = Provider<GetSellerInventoryUsecase>((ref) {
  return GetSellerInventoryUsecase(ref.watch(fabricRepositoryProvider));
});

final getFabricByIdUsecaseProvider = Provider<GetFabricByIdUsecase>((ref) {
  return GetFabricByIdUsecase(ref.watch(fabricRepositoryProvider));
});

final getMerchantStatsUsecaseProvider = Provider<GetMerchantStatsUsecase>((ref) {
  return GetMerchantStatsUsecase(ref.watch(fabricRepositoryProvider));
});

final fabricCatalogProvider = StreamProvider.family<List<Fabric>, String?>((ref, category) {
  final usecase = ref.watch(streamCatalogUsecaseProvider);
  return usecase(category: category);
});

final sellerInventoryProvider = FutureProvider.family<List<Fabric>, String>((ref, sellerId) async {
  final usecase = ref.watch(getSellerInventoryUsecaseProvider);
  final result = await usecase(sellerId);
  return result.fold(
    (failure) => throw Exception('Unable to load inventory. Please check your connection.'),
    (fabrics) => fabrics,
  );
});

final fabricByIdProvider = FutureProvider.family<Fabric, String>((ref, fabricId) async {
  final usecase = ref.watch(getFabricByIdUsecaseProvider);
  final result = await usecase(fabricId);
  return result.fold(
    (failure) => throw Exception('Fabric not found or unavailable.'),
    (fabric) => fabric,
  );
});

final merchantStatsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, merchantId) async {
  final usecase = ref.watch(getMerchantStatsUsecaseProvider);
  final result = await usecase(merchantId);
  return result.fold(
    (failure) => throw Exception('Unable to load merchant stats.'),
    (stats) => stats,
  );
});
