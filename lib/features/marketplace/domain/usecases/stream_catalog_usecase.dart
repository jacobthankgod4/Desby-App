import '../entities/fabric.dart';
import '../repositories/fabric_repository.dart';

class StreamCatalogUsecase {
  final FabricRepository repository;
  StreamCatalogUsecase(this.repository);
  Stream<List<Fabric>> call({String? category, String? sellerId}) =>
      repository.streamCatalog(category: category, sellerId: sellerId);
}
