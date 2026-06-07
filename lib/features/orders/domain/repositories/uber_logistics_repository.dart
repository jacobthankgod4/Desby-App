import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/uber_logistics.dart';

abstract class UberLogisticsRepository {
  Future<Either<Failure, UberDeliveryQuote>> getQuote({
    required UberStructuredAddress pickup,
    required UberStructuredAddress dropoff,
  });

  Future<Either<Failure, String>> createDelivery({
    required String quoteId,
    required String pickupName,
    required UberStructuredAddress pickupAddress,
    required String pickupPhoneNumber,
    required String dropoffName,
    required UberStructuredAddress dropoffAddress,
    required String dropoffPhoneNumber,
    required List<UberManifestItem> items,
    required String idempotencyKey,
  });

  Future<Either<Failure, UberDeliveryStatus>> getStatus(String deliveryId);

  Future<Either<Failure, void>> cancelDelivery(String deliveryId, String reason);
}

class UberDeliveryStatus {
  final String id;
  final String current;
  final bool courierImminent;
  final String? trackingUrl;

  UberDeliveryStatus({
    required this.id,
    required this.current,
    required this.courierImminent,
    this.trackingUrl,
  });
}
