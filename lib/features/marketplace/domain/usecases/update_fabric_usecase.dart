import '../../../../core/error/failures.dart';
import '../entities/fabric.dart';
import '../repositories/fabric_repository.dart';

class UpdateFabricUsecase {
  final FabricRepository repository;
  UpdateFabricUsecase(this.repository);
  Future<Result<void>> call(Fabric fabric) => repository.updateFabric(fabric);
}
