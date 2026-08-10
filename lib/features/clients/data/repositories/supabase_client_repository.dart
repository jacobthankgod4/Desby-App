import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/client.dart';
import '../../domain/repositories/client_repository.dart';

class SupabaseClientRepository implements ClientRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<Result<List<Client>>> getClients({String? query}) async {
    try {
      var sbQuery = _supabase.from('clients').select();
      if (query != null && query.isNotEmpty) {
        sbQuery = sbQuery.ilike('name', '%$query%');
      }
      final response = await sbQuery;
      final clients = (response as List).map((data) => _mapToEntity(data['id'], data)).toList();
      return Success(clients);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Client>> getClientById(String id) async {
    try {
      final response = await _supabase.from('clients').select().eq('id', id).maybeSingle();
      if (response == null) return const Failure(AuthFailure(message: 'Client not found'));
      return Success(_mapToEntity(id, response));
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Client>> createClient(Client client) async {
    try {
      await _supabase.from('clients').upsert(_mapFromEntity(client), onConflict: 'id');
      return Success(client);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Client>> updateClient(Client client) async {
    try {
      await _supabase.from('clients').upsert(_mapFromEntity(client), onConflict: 'id');
      return Success(client);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteClient(String id) async {
    try {
      await _supabase.from('clients').delete().eq('id', id);
      return const Success(null);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  Client _mapToEntity(String id, Map<String, dynamic> data) {
    return Client(
      id: id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      address: data['address'] as String? ?? 'No Address',
      gender: data['gender'] as String? ?? 'UNISEX',
      profileImage: (data['profile_image'] ?? data['profileImage']) as String?,
      measurements: (data['measurements'] as Map?)?.map((k, v) => MapEntry(k as String, v.toString())),
      createdAt: data['created_at'] != null ? DateTime.parse(data['created_at'] as String) : (data['createdAt'] != null ? DateTime.parse(data['createdAt'] as String) : DateTime.now()),
    );
  }

  Map<String, dynamic> _mapFromEntity(Client client) {
    return {
      'id': client.id,
      'name': client.name,
      'email': client.email,
      'phone': client.phone,
      'address': client.address,
      'gender': client.gender,
      'profile_image': client.profileImage,
      'measurements': client.measurements,
      'created_at': client.createdAt.toIso8601String(),
    };
  }
}
