import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/client.dart';
import '../../domain/repositories/client_repository.dart';

class SupabaseClientRepository implements ClientRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<Result<List<Client>>> getClients({
    required String tailorId,
    String? query,
  }) async {
    try {
      var sbQuery = _supabase
          .from('clients')
          .select()
          .eq('tailor_id', tailorId);
      if (query != null && query.isNotEmpty) {
        sbQuery = sbQuery.ilike('name', '%$query%');
      }
      final response = await sbQuery.order('created_at', ascending: false);
      final clients = (response as List)
          .map((data) => _mapToEntity(data['id'], data))
          .toList();
      return Success(clients);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Client>> getClientById(String id) async {
    try {
      final response = await _supabase
          .from('clients')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null)
        return const Failure(AuthFailure(message: 'Client not found'));
      return Success(_mapToEntity(id, response));
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Client>> createClient(Client client) async {
    try {
      await _supabase
          .from('clients')
          .upsert(_mapFromEntity(client), onConflict: 'id');
      return Success(client);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Client>> updateClient(Client client) async {
    try {
      await _supabase
          .from('clients')
          .upsert(_mapFromEntity(client), onConflict: 'id');
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

  @override
  Future<Result<Client>> getClientByInviteToken(String token) async {
    try {
      final response = await _supabase
          .from('clients')
          .select()
          .eq('invite_token', token)
          .eq('invite_status', 'pending')
          .maybeSingle();
      if (response == null) {
        return const Failure(
          AuthFailure(message: 'Invalid or expired invite link'),
        );
      }
      return Success(_mapToEntity(response['id'], response));
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> updateClientByInvite(
    String token,
    Map<String, dynamic> data,
  ) async {
    try {
      await _supabase
          .from('clients')
          .update(data)
          .eq('invite_token', token)
          .eq('invite_status', 'pending');
      return const Success(null);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<String>> generateInviteToken(String clientId) async {
    try {
      const uuid = Uuid();
      final token = uuid.v4();
      await _supabase
          .from('clients')
          .update({'invite_token': token, 'invite_status': 'pending'})
          .eq('id', clientId);
      return Success(token);
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
      measurements: (data['measurements'] as Map?)?.map(
        (k, v) => MapEntry(k as String, v.toString()),
      ),
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'] as String)
          : (data['createdAt'] != null
                ? DateTime.parse(data['createdAt'] as String)
                : DateTime.now()),
      tailorId: data['tailor_id'] as String?,
      inviteToken: data['invite_token'] as String?,
      inviteStatus: _parseInviteStatus(data['invite_status'] as String?),
      completedFields: data['completed_fields'] as Map<String, dynamic>?,
      stylePreferences: data['style_preferences'] as Map<String, dynamic>?,
      orderDetails: data['order_details'] as Map<String, dynamic>?,
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> _mapFromEntity(Client client) {
    String? inviteStatusToString(InviteStatus status) {
      switch (status) {
        case InviteStatus.pending:
          return 'pending';
        case InviteStatus.accepted:
          return 'accepted';
        case InviteStatus.expired:
          return 'expired';
        case InviteStatus.none:
          return null;
      }
    }

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
      'tailor_id': client.tailorId,
      'invite_token': client.inviteToken,
      'invite_status': inviteStatusToString(client.inviteStatus),
      'completed_fields': client.completedFields,
      'style_preferences': client.stylePreferences,
      'order_details': client.orderDetails,
      'invite_sent_at': client.inviteSentAt?.toIso8601String(),
    };
  }

  static InviteStatus _parseInviteStatus(String? status) {
    switch (status) {
      case 'pending':
        return InviteStatus.pending;
      case 'accepted':
        return InviteStatus.accepted;
      case 'expired':
        return InviteStatus.expired;
      default:
        return InviteStatus.none;
    }
  }
}
