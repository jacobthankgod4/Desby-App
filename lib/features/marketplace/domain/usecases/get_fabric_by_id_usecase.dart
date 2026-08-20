import '../../../../core/error/failures.dart';
import '../entities/fabric.dart';
import '../repositories/fabric_repository.dart';

class GetFabricByIdUsecase {
  final FabricRepository repository;
  GetFabricByIdUsecase(this.repository);
  Future<Result<Fabric>> call(String id) => repository.getFabricById(id);
}
