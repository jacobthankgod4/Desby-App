import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/client_repository.dart';
import '../../domain/usecases/client_usecases.dart';
import '../../domain/entities/client.dart';
import '../../data/repositories/supabase_client_repository.dart';

import '../../../../features/orders/presentation/providers/order_provider.dart';
import '../../../../features/orders/domain/entities/order.dart';

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  return SupabaseClientRepository();
});

final getClientsUsecaseProvider = Provider((ref) {
  return GetClientsUsecase(ref.watch(clientRepositoryProvider));
});

final getClientByIdUsecaseProvider = Provider((ref) {
  return GetClientByIdUsecase(ref.watch(clientRepositoryProvider));
});

final createClientUsecaseProvider = Provider((ref) {
  return CreateClientUsecase(ref.watch(clientRepositoryProvider));
});

final updateClientUsecaseProvider = Provider((ref) {
  return UpdateClientUsecase(ref.watch(clientRepositoryProvider));
});

final deleteClientUsecaseProvider = Provider((ref) {
  return DeleteClientUsecase(ref.watch(clientRepositoryProvider));
});

final clientsProvider = FutureProvider.family<List<Client>, String?>((ref, query) async {
  final usecase = ref.watch(getClientsUsecaseProvider);
  final result = await usecase(query: query);
  return result.fold(
    (failure) => throw Exception(failure.toString()),
    (clients) => clients,
  );
});

final clientOrdersProvider = FutureProvider.family<List<OrderEntity>, String>((ref, clientId) async {
  try {
    final orders = await ref.watch(ordersProvider(null).future);
    return orders.where((o) => o.clientId == clientId).toList();
  } catch (e) {
    debugPrint('[CLIENT] History Sync Error: $e');
    return [];
  }
});

final clientDetailProvider = FutureProvider.family<Client, String>((ref, id) async {
  final usecase = ref.watch(getClientByIdUsecaseProvider);
  final result = await usecase(id);
  return result.fold(
    (failure) => throw Exception(failure.toString()),
    (client) => client,
  );
});
