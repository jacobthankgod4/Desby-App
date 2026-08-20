import '../../../../core/error/failures.dart';
import '../entities/fabric.dart';
import '../repositories/fabric_repository.dart';

class GetSellerInventoryUsecase {
  final FabricRepository repository;
  GetSellerInventoryUsecase(this.repository);
  Future<Result<List<Fabric>>> call(String sellerId) =>
      repository.getSellerInventory(sellerId);
}
