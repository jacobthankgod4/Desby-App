import '../../../../core/error/failures.dart';
import '../entities/delivery_booking.dart';
import '../entities/order.dart';

abstract class LogisticsRepository {
  Future<Result<String>> summonRider(OrderEntity order);
  Future<Result<Map<String, dynamic>>> trackDelivery(String shipmentRef);
  Future<Result<double>> estimateCost(String destinationState);

  /// Every carrier willing to ship this parcel, cheapest first.
  ///
  /// Multi-carrier aggregators override this to return competing offers. The
  /// default synthesises a single option from [estimateCost] so a
  /// single-carrier implementation still works with carrier-selection UI.
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
          carrierId: 'default',
          carrierName: 'Delivery partner',
          carrierSlug: '',
          amount: amount,
          currency: 'NGN',
          rateId: '',
          deliveryTime: 'Standard delivery',
        ),
      ]),
    );
  }
}