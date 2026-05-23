import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/shop_product.dart';
import '../../domain/repositories/shop_repository.dart';

class FirebaseShopRepository implements ShopRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<Result<List<ShopProduct>>> getProducts(String tailorId) async {
    try {
      final snapshot = await _firestore
          .collection('shops')
          .doc(tailorId)
          .collection('products')
          .get();
      
      final products = snapshot.docs
          .map((doc) => ShopProduct.fromMap(doc.data()))
          .toList();
      
      return Success(products);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<ShopProduct>> getProduct(String productId) async {
    try {
      final doc = await _firestore
          .collection('products')
          .doc(productId)
          .get();
      
      if (!doc.exists) {
        return const Failure(AuthFailure(message: 'Product not found'));
      }
      
      return Success(ShopProduct.fromMap(doc.data()!));
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<ShopProduct>> createProduct(ShopProduct product) async {
    try {
      final docRef = _firestore.collection('products').doc(product.id);
      await docRef.set(product.toMap());
      
      // Also add to shop subcollection
      await _firestore
          .collection('shops')
          .doc(product.tailorId)
          .collection('products')
          .doc(product.id)
          .set(product.toMap());
      
      return Success(product);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<ShopProduct>> updateProduct(ShopProduct product) async {
    try {
      final updatedProduct = product.copyWith(updatedAt: DateTime.now());
      
      await _firestore
          .collection('products')
          .doc(product.id)
          .update(updatedProduct.toMap());
      
      await _firestore
          .collection('shops')
          .doc(product.tailorId)
          .collection('products')
          .doc(product.id)
          .update(updatedProduct.toMap());
      
      return Success(updatedProduct);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteProduct(String productId) async {
    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      if (doc.exists) {
        final tailorId = doc.data()?['tailorId'] as String?;
        
        await _firestore.collection('products').doc(productId).delete();
        
        if (tailorId != null) {
          await _firestore
              .collection('shops')
              .doc(tailorId)
              .collection('products')
              .doc(productId)
              .delete();
        }
      }
      return const Success(null);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<ShopProduct>> toggleProductVisibility(String productId, bool isVisible) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'isVisible': isVisible,
        'updatedAt': DateTime.now(),
      });
      
      final doc = await _firestore.collection('products').doc(productId).get();
      final product = ShopProduct.fromMap(doc.data()!);
      
      return Success(product);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<ShopProduct>>> getVisibleProducts(String tailorId) async {
    try {
      final snapshot = await _firestore
          .collection('shops')
          .doc(tailorId)
          .collection('products')
          .where('isVisible', isEqualTo: true)
          .get();
      
      final products = snapshot.docs
          .map((doc) => ShopProduct.fromMap(doc.data()))
          .toList();
      
      return Success(products);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<ShopProduct>>> searchProducts(String tailorId, String query) async {
    try {
      final snapshot = await _firestore
          .collection('shops')
          .doc(tailorId)
          .collection('products')
          .get();
      
      final products = snapshot.docs
          .map((doc) => ShopProduct.fromMap(doc.data()))
          .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
      
      return Success(products);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }
}
