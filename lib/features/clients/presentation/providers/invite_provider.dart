import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/client.dart';
import '../../domain/usecases/client_usecases.dart';
import '../../../orders/data/repositories/supabase_order_repository.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/domain/entities/order_ids.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'client_provider.dart';

class InviteState {
  final Client? client;
  final bool isLoading;
  final String? error;
  final int currentStep;
  final bool isCompleted;
  final Map<String, dynamic>? selectedProduct;
  final Map<String, dynamic>? orderDetails;

  const InviteState({
    this.client,
    this.isLoading = false,
    this.error,
    this.currentStep = 0,
    this.isCompleted = false,
    this.selectedProduct,
    this.orderDetails,
  });

  InviteState copyWith({
    Client? client,
    bool? isLoading,
    String? error,
    int? currentStep,
    bool? isCompleted,
    Map<String, dynamic>? selectedProduct,
    Map<String, dynamic>? orderDetails,
  }) {
    return InviteState(
      client: client ?? this.client,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentStep: currentStep ?? this.currentStep,
      isCompleted: isCompleted ?? this.isCompleted,
      selectedProduct: selectedProduct ?? this.selectedProduct,
      orderDetails: orderDetails ?? this.orderDetails,
    );
  }
}

class InviteNotifier extends StateNotifier<InviteState> {
  final GetClientByInviteTokenUsecase _getClientByInviteTokenUsecase;
  final UpdateClientByInviteUsecase _updateClientByInviteUsecase;
  final SupabaseOrderRepository _orderRepository;

  /// The signed-in account completing the invite. Recorded as
  /// orders.requesting_user_id so the request is attributable, because
  /// client_id here is the tailor's own customer record rather than the buyer.
  final String? _currentUserId;

  InviteNotifier(
    this._getClientByInviteTokenUsecase,
    this._updateClientByInviteUsecase,
    this._orderRepository, {
    String? currentUserId,
  })  : _currentUserId = currentUserId,
        super(const InviteState());

  Future<void> loadClientByToken(String token) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getClientByInviteTokenUsecase(token);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (client) {
        // Restore any previously saved order details from client record
        state = state.copyWith(
          isLoading: false,
          client: client,
          orderDetails: client.orderDetails,
        );
      },
    );
  }

  void selectProduct(Map<String, dynamic> product) {
    state = state.copyWith(selectedProduct: product);
  }

  void clearProductSelection() {
    state = state.copyWith(selectedProduct: null);
  }

  Future<void> updateProfile(String token, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _updateClientByInviteUsecase(token, data);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (_) {
        final updatedClient = state.client?.copyWith(
          name: data['name'] as String? ?? state.client?.name,
          phone: data['phone'] as String? ?? state.client?.phone,
          email: data['email'] as String? ?? state.client?.email,
          gender: data['gender'] as String? ?? state.client?.gender,
          address: data['address'] as String? ?? state.client?.address,
          completedFields: {...?state.client?.completedFields, 'profile': true},
        );
        state = state.copyWith(
          isLoading: false,
          client: updatedClient,
          currentStep: 2,
        );
      },
    );
  }

  Future<void> updateOrderDetails(
    String token,
    Map<String, dynamic> data,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _updateClientByInviteUsecase(token, {
      'order_details': data,
      'completed_fields': {...?state.client?.completedFields, 'order': true},
    });
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (_) {
        final updatedClient = state.client?.copyWith(
          orderDetails: data,
          completedFields: {...?state.client?.completedFields, 'order': true},
        );
        state = state.copyWith(
          isLoading: false,
          client: updatedClient,
          orderDetails: data,
          currentStep: 3,
        );
      },
    );
  }

  Future<void> updateMeasurements(
    String token,
    Map<String, dynamic> data,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _updateClientByInviteUsecase(token, {
      'measurements': data,
      'completed_fields': {
        ...?state.client?.completedFields,
        'measurements': true,
      },
    });
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (_) {
        final updatedClient = state.client?.copyWith(
          measurements: data.map((k, v) => MapEntry(k, v.toString())),
          completedFields: {
            ...?state.client?.completedFields,
            'measurements': true,
          },
        );
        state = state.copyWith(
          isLoading: false,
          client: updatedClient,
          currentStep: 4,
        );
      },
    );
  }

  Future<void> completeInvite(String token) async {
    state = state.copyWith(isLoading: true, error: null);

    // Create order from client data + order details + measurements
    final client = state.client;
    final orderDetails = state.orderDetails;
    if (client == null) {
      state = state.copyWith(isLoading: false, error: 'Client data not loaded');
      return;
    }

    // Create the order.
    // The id must be a uuid: 'ORD_<uuid>' was rejected by the orders PK (22P02).
    // This path already has a clients row, so clientId is legitimate here —
    // but requesting_user_id still has to be set or the row is unattributable.
    final now = DateTime.now();
    final orderId = const Uuid().v4();
    final order = OrderEntity(
      id: orderId,
      reference: OrderIds.newReference(at: now),
      clientId: client.id,
      requestingUserId: _currentUserId,
      tailorId: client.tailorId,
      clientName: client.name,
      items: [
        OrderItem(
          id: 'item_${const Uuid().v4()}',
          garmentType: orderDetails?['garment_type'] as String? ?? 'Custom',
          designId: orderDetails?['product_id'] as String?,
          measurements: client.measurements?.map(
            (k, v) => MapEntry(k, num.tryParse(v) ?? v),
          ),
          price: (orderDetails?['base_price'] as num?)?.toDouble() ?? 0.0,
        ),
      ],
      status: OrderStatus.pending,
      totalAmount: (orderDetails?['base_price'] as num?)?.toDouble() ?? 0.0,
      dueDate: orderDetails?['due_date'] != null
          ? DateTime.tryParse(orderDetails!['due_date'] as String) ??
                now.add(const Duration(days: 14))
          : now.add(const Duration(days: 14)),
      createdAt: now,
      fabricType: orderDetails?['fabric_type'] as String?,
      fabricColor: orderDetails?['fabric_color'] as String?,
      materialAssetUrl: orderDetails?['material_photo_url'] as String?,
      deliveryAddress: client.address.isNotEmpty ? client.address : null,
      requiresDispatch: client.address.isNotEmpty,
    );

    final orderResult = await _orderRepository.createOrder(order);
    if (orderResult.isFailure) {
      final failure = orderResult.getFailureOrNull();
      state = state.copyWith(
        isLoading: false,
        error:
            'Failed to create order: ${failure?.failure.message ?? "Unknown error"}',
      );
      return;
    }

    // Mark invite as accepted
    final result = await _updateClientByInviteUsecase(token, {
      'invite_status': 'accepted',
    });
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (_) => state = state.copyWith(isLoading: false, isCompleted: true),
    );
  }

  void nextStep() {
    state = state.copyWith(currentStep: state.currentStep + 1);
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }
}

final inviteNotifierProvider =
    StateNotifierProvider<InviteNotifier, InviteState>((ref) {
      return InviteNotifier(
        ref.watch(getClientByInviteTokenUsecaseProvider),
        ref.watch(updateClientByInviteUsecaseProvider),
        SupabaseOrderRepository(),
        currentUserId: ref.watch(currentUserProvider)?.id,
      );
    });

final generateInviteTokenProvider = FutureProvider.family<String, String>((
  ref,
  clientId,
) async {
  final usecase = ref.watch(generateInviteTokenUsecaseProvider);
  final result = await usecase(clientId);
  return result.fold(
    (failure) => throw Exception(failure.toString()),
    (token) => token,
  );
});
