import '../../../../core/error/failures.dart';
import '../entities/client.dart';
import '../repositories/client_repository.dart';

class GetClientsUsecase {
  final ClientRepository repository;
  GetClientsUsecase(this.repository);
  Future<Result<List<Client>>> call({String? query}) =>
      repository.getClients(query: query);
}

class GetClientByIdUsecase {
  final ClientRepository repository;
  GetClientByIdUsecase(this.repository);
  Future<Result<Client>> call(String id) => repository.getClientById(id);
}

class CreateClientUsecase {
  final ClientRepository repository;
  CreateClientUsecase(this.repository);
  Future<Result<Client>> call(Client client) => repository.createClient(client);
}

class UpdateClientUsecase {
  final ClientRepository repository;
  UpdateClientUsecase(this.repository);
  Future<Result<Client>> call(Client client) => repository.updateClient(client);
}

class DeleteClientUsecase {
  final ClientRepository repository;
  DeleteClientUsecase(this.repository);
  Future<Result<void>> call(String id) => repository.deleteClient(id);
}
