import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/client.dart';
import '../../domain/repositories/client_repository.dart';

class FirebaseClientRepository implements ClientRepository {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  @override
  Future<Result<List<Client>>> getClients({String? query}) async {
    try {
      final snapshot = await _firestore.collection('clients').get();
      final clients = snapshot.docs.map((doc) => _mapToEntity(doc.id, doc.data())).toList();
      if (query != null && query.isNotEmpty) {
        return Success(clients.where((c) => c.name.toLowerCase().contains(query.toLowerCase())).toList());
      }
      return Success(clients);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Client>> getClientById(String id) async {
    try {
      final doc = await _firestore.collection('clients').doc(id).get();
      if (!doc.exists) return const Failure(AuthFailure(message: 'Client not found'));
      return Success(_mapToEntity(doc.id, doc.data()!));
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Client>> createClient(Client client) async {
    try {
      await _firestore.collection('clients').doc(client.id).set(_mapFromEntity(client));
      return Success(client);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Client>> updateClient(Client client) async {
    try {
      await _firestore.collection('clients').doc(client.id).update(_mapFromEntity(client));
      return Success(client);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteClient(String id) async {
    try {
      await _firestore.collection('clients').doc(id).delete();
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
      profileImage: data['profileImage'] as String?,
      measurements: (data['measurements'] as Map?)?.map((k, v) => MapEntry(k as String, v.toString())),
      // Firestore may return either Timestamp or String/ISO-8601 depending on data type.
      createdAt: (() {
        final raw = data['createdAt'];
        if (raw is Timestamp) return raw.toDate();
        if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
        return DateTime.now();
      })(),
    );
  }

  Map<String, dynamic> _mapFromEntity(Client client) {
    return {
      'name': client.name,
      'email': client.email,
      'phone': client.phone,
      'address': client.address,
      'gender': client.gender,
      'profileImage': client.profileImage,
      'measurements': client.measurements,
      'createdAt': client.createdAt,
    };
  }
}
