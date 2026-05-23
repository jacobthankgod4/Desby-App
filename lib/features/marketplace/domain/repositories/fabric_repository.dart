import '../../../../core/error/failures.dart';
import '../entities/fabric.dart';

abstract class FabricRepository {
  Future<Result<void>> uploadFabric(Fabric fabric);
  Future<Result<void>> updateFabric(Fabric fabric);
  Future<Result<void>> deleteFabric(String id);
  Stream<List<Fabric>> streamCatalog({String? category, String? sellerId});
  Future<Result<List<Fabric>>> getSellerInventory(String sellerId);
}
