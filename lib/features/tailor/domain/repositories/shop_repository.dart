import '../../../../core/error/failures.dart';
import '../entities/shop_product.dart';

/// Repository interface for shop operations
abstract class ShopRepository {
  /// Get all products for a tailor
  Future<Result<List<ShopProduct>>> getProducts(String tailorId);
  
  /// Get a single product by ID
  Future<Result<ShopProduct>> getProduct(String productId);
  
  /// Create a new product
  Future<Result<ShopProduct>> createProduct(ShopProduct product);
  
  /// Update an existing product
  Future<Result<ShopProduct>> updateProduct(ShopProduct product);
  
  /// Delete a product
  Future<Result<void>> deleteProduct(String productId);
  
  /// Toggle product visibility
  Future<Result<ShopProduct>> toggleProductVisibility(String productId, bool isVisible);
  
  /// Get visible products only
  Future<Result<List<ShopProduct>>> getVisibleProducts(String tailorId);
  
  /// Search products by name
  Future<Result<List<ShopProduct>>> searchProducts(String tailorId, String query);
}
