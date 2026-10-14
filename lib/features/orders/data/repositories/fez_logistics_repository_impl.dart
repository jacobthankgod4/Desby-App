import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';
import '../../domain/entities/delivery_booking.dart';
import '../../domain/repositories/logistics_repository.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_ids.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/fez_logistics_service.dart';
import '../../../../config/environment.dart';
import '../../../../core/constants/nigeria_lga_data.dart';

/// True when Fez has issued this account its login credentials.
///
/// Desby currently has only the secret key, which Fez does not accept as a
/// credential — so this is false until Fez provisions a user id + password.
/// Callers use it to degrade honestly rather than showing a courier quote that
/// cannot be obtained.
bool get hasFezCredentials =>
    Environment.current.fezLogisticsProvisioned;

class FezLogisticsRepositoryImpl implements LogisticsRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final FezLogisticsService _fezService;

  FezLogisticsRepositoryImpl({FezLogisticsService? fezService})
    : _fezService = fezService ?? FezLogisticsService(Dio());

  @override
  Future<Result<String>> summonRider(OrderEntity order) async {
    try {
      if (!hasFezCredentials) {
        return const Failure(
          UnknownFailure(
            message:
                'Delivery is not available right now — the courier account is '
                'not configured. Your order is saved; the team will arrange '
                'delivery and confirm the fee with you.',
          ),
        );
      }
      await _fezService.ensureAuthenticated();

      final deliveryAddress = order.deliveryAddress ?? '';
      // Fez uses this as its own external reference; prefer the human-readable
      // handle so a Fez ticket and a Desby order can be reconciled by eye.
      final uniqueId = order.displayReference.isNotEmpty
          ? order.displayReference
          : OrderIds.newReference();
      final recipientPhone =
          (order.metadata?['phone'] ??
                  order.metadata?['recipientPhone'] ??
                  '08000000000')
              .toString();

      final rawWeight = order.metadata?['weight'];
      final weight = rawWeight is num
          ? rawWeight.toInt()
          : int.tryParse(rawWeight?.toString() ?? '') ?? 1;
      final payload = <String, dynamic>{
        'recipientAddress': deliveryAddress,
        'recipientState': _deriveState(deliveryAddress),
        'recipientName': order.clientName,
        'recipientPhone': recipientPhone,
        'uniqueID': uniqueId,
        'BatchID': uniqueId,
        'valueOfItem': order.totalAmount.toString(),
        'weight': weight,
        'itemDescription': order.items.isNotEmpty
            ? order.items.first.garmentType
            : 'Custom order',
      };

      final waybill = await _fezService.createOrder(payload);
      if (waybill != null) {
        await _supabase
            .from('orders')
            .update({'fez_order_no': waybill})
            .eq('id', order.id);
        return Success(waybill);
      }
      // Distinguish "we have no courier account configured" from "Fez rejected
      // the call". Telling a tailor to retry when the account is simply missing
      // credentials sends them in circles.
      if (!hasFezCredentials) {
        return const Failure(
          UnknownFailure(
            message:
                'Delivery is not available right now — the courier account is '
                'not configured. Your order is saved; the team will arrange '
                'delivery and confirm the fee with you.',
          ),
        );
      }
      return const Failure(
        UnknownFailure(message: 'Fez dispatch failed. Please try again.'),
      );
    } catch (e) {
      return Failure(UnknownFailure(message: 'Fez dispatch failed: $e'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> trackDelivery(String fezOrderNo) async {
    try {
      final data = await _fezService.trackOrder(fezOrderNo);
      if (data != null) {
        return Success(data);
      }
      return const Failure(
        UnknownFailure(
          message:
              'Unable to track delivery right now. '
              'Please check your internet connection and try again.',
        ),
      );
    } catch (e) {
      return Failure(UnknownFailure(message: 'Fez tracking error: $e'));
    }
  }

  /// Fez prices a single carrier, so the multi-carrier surface collapses to one
  /// option built from the plain estimate.
  @override
  Future<Result<List<DeliveryQuote>>> quotes({
    required String destinationState,
    required double weightKg,
    required double value,
    required String description,
    bool cashOnDelivery = false,
  }) async {
    final result = await estimateCost(destinationState);
    return result.fold(
      (failure) => Failure(failure),
      (amount) => Success(<DeliveryQuote>[
        DeliveryQuote(
          carrierId: 'fez',
          carrierName: 'Fez Delivery',
          carrierSlug: 'fez-delivery',
          amount: amount,
          currency: 'NGN',
          rateId: '',
          deliveryTime: 'Standard delivery',
        ),
      ]),
    );
  }

  @override
  Future<Result<double>> estimateCost(String destinationState) async {
    // Distinguish "not configured" from "temporarily unreachable" — telling a
    // user to check their internet when the courier account is unconfigured
    // sends them down the wrong path entirely.
    final hasCredentials = Environment.current.fezLogisticsProvisioned;

    try {
      final costData = await _fezService.getDeliveryCost(
        state: destinationState,
      );
      if (costData == null) {
        return Failure(
          UnknownFailure(
            message: hasCredentials
                ? 'Unable to get a delivery estimate right now. '
                      'Please try again in a moment.'
                : 'Delivery estimates are unavailable at the moment. '
                      'Your tailor will confirm the delivery cost.',
          ),
        );
      }
      final cost =
          costData['cost'] ??
          costData['amount'] ??
          costData['totalCost'] ??
          costData['delivery_cost'] ??
          costData['price'];
      if (cost != null) {
        return Success((cost as num).toDouble());
      }
      return const Failure(
        UnknownFailure(
          message:
              'Fez Logistics response missing cost data. '
              'Please try again or contact support.',
        ),
      );
    } catch (e) {
      return Failure(UnknownFailure(message: 'Fez Logistics error: $e'));
    }
  }

  Future<Map<String, dynamic>> getDeliveryQuote(
    Map<String, dynamic> params,
  ) async {
    final destinationState = params['state'] as String? ?? '';
    final costResult = await estimateCost(destinationState);
    return costResult.fold(
      (failure) => throw Exception(failure.message),
      (cost) => {'amount': cost, 'currency': 'NGN', 'provider': 'FEZ'},
    );
  }

  Future<void> updateDeliveryStatus(String fezOrderNo, String status) async {
    await _supabase
        .from('orders')
        .update({'status': status})
        .eq('fez_order_no', fezOrderNo);
  }

  String _deriveState(String address) {
    final normalized = address.toLowerCase();
    for (final state in NigeriaLgaData.states) {
      if (normalized.contains(state.toLowerCase())) return state;
    }
    return 'Lagos';
  }
}
