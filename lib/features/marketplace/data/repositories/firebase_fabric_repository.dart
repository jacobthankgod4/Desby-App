import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/fabric.dart';
import '../../domain/repositories/fabric_repository.dart';
import '../models/fabric_model.dart';

class FirebaseFabricRepository implements FabricRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<Result<void>> uploadFabric(Fabric fabric) async {
    try {
      final model = FabricModel.fromEntity(fabric);
      await _firestore.collection('fabrics').doc(model.id).set(model.toJson());
      return const Success(null);
    } catch (e) {
      return Failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> updateFabric(Fabric fabric) async {
    try {
      final model = FabricModel.fromEntity(fabric);
      await _firestore.collection('fabrics').doc(model.id).update(model.toJson());
      return const Success(null);
    } catch (e) {
      return Failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteFabric(String id) async {
    try {
      await _firestore.collection('fabrics').doc(id).delete();
      return const Success(null);
    } catch (e) {
      return Failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Stream<List<Fabric>> streamCatalog({String? category, String? sellerId}) {
    Query query = _firestore.collection('fabrics').where('isVisible', isEqualTo: true);
    
    if (category != null && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }
    
    if (sellerId != null) {
      query = query.where('sellerId', isEqualTo: sellerId);
    }

    return query.orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => FabricModel.fromJson(doc.data() as Map<String, dynamic>).toEntity())
          .toList();
    });
  }

  @override
  Future<Result<List<Fabric>>> getSellerInventory(String sellerId) async {
    try {
      final snapshot = await _firestore
          .collection('fabrics')
          .where('sellerId', isEqualTo: sellerId)
          .get();
      
      final fabrics = snapshot.docs
          .map((doc) => FabricModel.fromJson(doc.data() as Map<String, dynamic>).toEntity())
          .toList();
          
      return Success(fabrics);
    } catch (e) {
      return Failure(UnknownFailure(message: e.toString()));
    }
  }
}
