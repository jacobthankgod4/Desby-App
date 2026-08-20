import '../../../../core/error/failures.dart';
import '../entities/fabric.dart';
import '../repositories/fabric_repository.dart';

class UploadFabricUsecase {
  final FabricRepository repository;
  UploadFabricUsecase(this.repository);
  Future<Result<void>> call(Fabric fabric) => repository.uploadFabric(fabric);
}
