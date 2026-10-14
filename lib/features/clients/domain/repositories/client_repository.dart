import '../../../../core/error/failures.dart';
import '../entities/client.dart';

abstract class ClientRepository {
  Future<Result<List<Client>>> getClients({
    required String tailorId,
    String? query,
  });
  Future<Result<Client>> getClientById(String id);
  Future<Result<Client>> createClient(Client client);
  Future<Result<Client>> updateClient(Client client);
  Future<Result<void>> deleteClient(String id);

  // Invite system methods
  Future<Result<Client>> getClientByInviteToken(String token);
  Future<Result<void>> updateClientByInvite(
    String token,
    Map<String, dynamic> data,
  );
  Future<Result<String>> generateInviteToken(String clientId);
}
