import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/fabric.dart';
import '../../domain/repositories/fabric_repository.dart';
import '../models/fabric_model.dart';

class SupabaseFabricRepository implements FabricRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<Result<void>> uploadFabric(Fabric fabric) async {
    try {
      final model = FabricModel.fromEntity(fabric);

      // 1. Save main fabric
      await _supabase.from('fabrics').upsert(model.toJson(), onConflict: 'id');

      // 2. Delete existing variants/tiers then re-insert (upsert not supported for children)
      await _supabase
          .from('fabric_variants')
          .delete()
          .eq('fabric_id', fabric.id);
      await _supabase
          .from('fabric_wholesale_tiers')
          .delete()
          .eq('fabric_id', fabric.id);

      // 3. Save variants
      if (fabric.variants.isNotEmpty) {
        final variants = fabric.variants
            .map(
              (v) => {
                'fabric_id': fabric.id,
                'color_name': v.colorName,
                'color_code': v.colorCode,
                'stock_quantity': v.stockQuantity,
                'image_url': v.imageUrl,
              },
            )
            .toList();
        await _supabase.from('fabric_variants').insert(variants);
      }

      // 3. Save wholesale tiers
      if (fabric.wholesaleTiers.isNotEmpty) {
        final tiers = fabric.wholesaleTiers
            .map(
              (t) => {
                'fabric_id': fabric.id,
                'min_quantity': t.minQuantity,
                'unit_price': t.unitPrice,
              },
            )
            .toList();
        await _supabase.from('fabric_wholesale_tiers').insert(tiers);
      }

      return const Success(null);
    } catch (e) {
      return Failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> updateFabric(Fabric fabric) async {
    try {
      final model = FabricModel.fromEntity(fabric);

      // 1. Update main fabric
      await _supabase.from('fabrics').upsert(model.toJson(), onConflict: 'id');

      // 2. Sync variants (Delete existing and re-insert or use upsert if IDs present)
      // For simplicity, we delete and re-insert custom variants
      await _supabase
          .from('fabric_variants')
          .delete()
          .eq('fabric_id', fabric.id);
      if (fabric.variants.isNotEmpty) {
        final variants = fabric.variants
            .map(
              (v) => {
                'fabric_id': fabric.id,
                'color_name': v.colorName,
                'color_code': v.colorCode,
                'stock_quantity': v.stockQuantity,
                'image_url': v.imageUrl,
              },
            )
            .toList();
        await _supabase.from('fabric_variants').insert(variants);
      }

      // 3. Sync wholesale tiers
      await _supabase
          .from('fabric_wholesale_tiers')
          .delete()
          .eq('fabric_id', fabric.id);
      if (fabric.wholesaleTiers.isNotEmpty) {
        final tiers = fabric.wholesaleTiers
            .map(
              (t) => {
                'fabric_id': fabric.id,
                'min_quantity': t.minQuantity,
                'unit_price': t.unitPrice,
              },
            )
            .toList();
        await _supabase.from('fabric_wholesale_tiers').insert(tiers);
      }

      return const Success(null);
    } catch (e) {
      return Failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteFabric(String id) async {
    try {
      // Delete associated variants and tiers first
      await _supabase.from('fabric_variants').delete().eq('fabric_id', id);
      await _supabase
          .from('fabric_wholesale_tiers')
          .delete()
          .eq('fabric_id', id);
      await _supabase.from('fabrics').delete().eq('id', id);
      return const Success(null);
    } catch (e) {
      return Failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Stream<List<Fabric>> streamCatalog({
    String? category,
    String? sellerId,
    String? state,
  }) async* {
    try {
      var query = _supabase.from('fabrics').select().eq('is_visible', true);
      if (category != null && category != 'All') {
        query = query.eq('category', category);
      }
      if (sellerId != null) {
        query = query.eq('seller_id', sellerId);
      }

      // The fabrics table has no location/state column; a seller's state
      // lives on their profile (users.state). Resolve matching sellers first,
      // then restrict the catalog to their fabrics.
      if (state != null && state != 'All States') {
        final sellerRows = await _supabase
            .from('users')
            .select('id')
            .eq('state', state);
        final matchingSellerIds = (sellerRows as List)
            .map((row) => row['id'].toString())
            .toList();
        if (matchingSellerIds.isEmpty) {
          yield [];
          return;
        }
        query = query.inFilter('seller_id', matchingSellerIds);
      }

      final response = await query;
      final fabrics = (response as List)
          .map((data) => FabricModel.fromJson(data).toEntity())
          .toList();

      // Featured placement: Pro sellers rank higher
      if (sellerId == null) {
        final sellerIds = fabrics.map((f) => f.sellerId).toSet();
        final sellerProfiles = <String, bool>{};
        for (final sid in sellerIds) {
          try {
            final profile = await _supabase
                .from('users')
                .select('subscription_plan_id')
                .eq('id', sid)
                .maybeSingle();
            sellerProfiles[sid] =
                profile != null &&
                (profile['subscription_plan_id'] ?? '').toString().endsWith(
                  '_pro',
                );
          } catch (_) {
            sellerProfiles[sid] = false;
          }
        }
        fabrics.sort((a, b) {
          final aIsPro = sellerProfiles[a.sellerId] ?? false;
          final bIsPro = sellerProfiles[b.sellerId] ?? false;
          if (aIsPro && !bIsPro) return -1;
          if (!aIsPro && bIsPro) return 1;
          return 0;
        });
      }

      yield fabrics;
    } catch (e) {
      yield [];
    }
  }

  @override
  Future<Result<List<Fabric>>> getSellerInventory(String sellerId) async {
    try {
      final response = await _supabase
          .from('fabrics')
          .select('*, fabric_variants(*), fabric_wholesale_tiers(*)')
          .eq('seller_id', sellerId);

      final fabrics = (response as List)
          .map((data) => FabricModel.fromJson(data).toEntity())
          .toList();

      return Success(fabrics);
    } catch (e) {
      return Failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Fabric>> getFabricById(String id) async {
    try {
      final response = await _supabase
          .from('fabrics')
          .select('*, fabric_variants(*), fabric_wholesale_tiers(*)')
          .eq('id', id)
          .single();
      return Success(FabricModel.fromJson(response).toEntity());
    } catch (e) {
      return Failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getMerchantStats(
    String merchantId,
  ) async {
    try {
      final response = await _supabase.rpc(
        'get_merchant_stats',
        params: {'merchant_id': merchantId},
      );
      return Success(Map<String, dynamic>.from(response));
    } catch (e) {
      return Failure(UnknownFailure(message: e.toString()));
    }
  }
}
