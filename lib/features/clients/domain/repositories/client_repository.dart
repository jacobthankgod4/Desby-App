import '../../../../core/error/failures.dart';
import '../entities/client.dart';

abstract class ClientRepository {
  Future<Result<List<Client>>> getClients({String? query});
  Future<Result<Client>> getClientById(String id);
  Future<Result<Client>> createClient(Client client);
  Future<Result<Client>> updateClient(Client client);
  Future<Result<void>> deleteClient(String id);
}
