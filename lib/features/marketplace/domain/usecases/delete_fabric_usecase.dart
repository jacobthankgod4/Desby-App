import '../../../../core/error/failures.dart';
import '../repositories/fabric_repository.dart';

class DeleteFabricUsecase {
  final FabricRepository repository;
  DeleteFabricUsecase(this.repository);
  Future<Result<void>> call(String id) => repository.deleteFabric(id);
}
