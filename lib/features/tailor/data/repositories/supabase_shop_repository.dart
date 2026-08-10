import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/shop_product.dart';
import '../../domain/repositories/shop_repository.dart';

class SupabaseShopRepository implements ShopRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<Result<List<ShopProduct>>> getProducts(String tailorId) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('tailor_id', tailorId);
      
      final products = (response as List)
          .map((data) => ShopProduct.fromMap(data))
          .toList();
      
      return Success(products);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<ShopProduct>> getProduct(String productId) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('id', productId)
          .maybeSingle();
      
      if (response == null) {
        return const Failure(AuthFailure(message: 'Product not found'));
      }
      
      return Success(ShopProduct.fromMap(response));
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<ShopProduct>> createProduct(ShopProduct product) async {
    try {
      await _supabase.from('products').upsert(product.toMap(), onConflict: 'id');
      return Success(product);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<ShopProduct>> updateProduct(ShopProduct product) async {
    try {
      final updatedProduct = product.copyWith(updatedAt: DateTime.now());
      await _supabase.from('products').upsert(updatedProduct.toMap(), onConflict: 'id');
      return Success(updatedProduct);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteProduct(String productId) async {
    try {
      await _supabase.from('products').delete().eq('id', productId);
      return const Success(null);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<ShopProduct>> toggleProductVisibility(String productId, bool isVisible) async {
    try {
      final response = await _supabase.from('products').update({
        'is_visible': isVisible,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', productId).select().single();
      
      return Success(ShopProduct.fromMap(response));
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<ShopProduct>>> getVisibleProducts(String tailorId) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('tailor_id', tailorId)
          .eq('is_visible', true);
      
      final products = (response as List)
          .map((data) => ShopProduct.fromMap(data))
          .toList();
      
      return Success(products);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<ShopProduct>>> searchProducts(String tailorId, String query) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('tailor_id', tailorId)
          .ilike('name', '%$query%');
      
      final products = (response as List)
          .map((data) => ShopProduct.fromMap(data))
          .toList();
      
      return Success(products);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }
}
