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
      
      // 2. Save variants
      if (fabric.variants.isNotEmpty) {
        final variants = fabric.variants.map((v) => {
          'fabric_id': fabric.id,
          'color_name': v.colorName,
          'color_code': v.colorCode,
          'stock_quantity': v.stockQuantity,
          'image_url': v.imageUrl,
        }).toList();
        await _supabase.from('fabric_variants').insert(variants);
      }
      
      // 3. Save wholesale tiers
      if (fabric.wholesaleTiers.isNotEmpty) {
        final tiers = fabric.wholesaleTiers.map((t) => {
          'fabric_id': fabric.id,
          'min_quantity': t.minQuantity,
          'unit_price': t.unitPrice,
        }).toList();
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
      await _supabase.from('fabric_variants').delete().eq('fabric_id', fabric.id);
      if (fabric.variants.isNotEmpty) {
        final variants = fabric.variants.map((v) => {
          'fabric_id': fabric.id,
          'color_name': v.colorName,
          'color_code': v.colorCode,
          'stock_quantity': v.stockQuantity,
          'image_url': v.imageUrl,
        }).toList();
        await _supabase.from('fabric_variants').insert(variants);
      }
      
      // 3. Sync wholesale tiers
      await _supabase.from('fabric_wholesale_tiers').delete().eq('fabric_id', fabric.id);
      if (fabric.wholesaleTiers.isNotEmpty) {
        final tiers = fabric.wholesaleTiers.map((t) => {
          'fabric_id': fabric.id,
          'min_quantity': t.minQuantity,
          'unit_price': t.unitPrice,
        }).toList();
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
      await _supabase.from('fabrics').delete().eq('id', id);
      return const Success(null);
    } catch (e) {
      return Failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Stream<List<Fabric>> streamCatalog({String? category, String? sellerId}) {
    // Note: To get variants/tiers in a stream, we'd need a more complex subscription
    // or fetch them separately. For the catalog list, usually basic data is enough.
    return _supabase.from('fabrics').stream(primaryKey: ['id']).eq('is_visible', true).map((event) {
      return event.map((data) => FabricModel.fromJson(data).toEntity()).toList();
    });
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
  Future<Result<Map<String, dynamic>>> getMerchantStats(String merchantId) async {
    try {
      final response = await _supabase.rpc('get_merchant_stats', params: {'merchant_id': merchantId});
      return Success(Map<String, dynamic>.from(response));
    } catch (e) {
      return Failure(UnknownFailure(message: e.toString()));
    }
  }
}
