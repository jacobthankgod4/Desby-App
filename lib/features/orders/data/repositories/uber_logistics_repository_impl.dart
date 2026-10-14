import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/uber_logistics.dart';
import '../../domain/repositories/uber_logistics_repository.dart';

class UberLogisticsRepositoryImpl implements UberLogisticsRepository {
  @override
  Future<Either<Failure, UberDeliveryQuote>> getQuote({
    required UberStructuredAddress pickup,
    required UberStructuredAddress dropoff,
  }) async {
    // Uber logistics not implemented — use Fez Logistics instead
    return Left(Failure(ServerFailure(
      message: 'Uber logistics not available. Use Fez Logistics.',
    )));
  }

  @override
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
  }) async {
    // Stub implementation
    return Right('del_${DateTime.now().millisecondsSinceEpoch}');
  }

  @override
  Future<Either<Failure, UberDeliveryStatus>> getStatus(
    String deliveryId,
  ) async {
    // Stub implementation
    return Right(
      UberDeliveryStatus(
        id: deliveryId,
        current: 'pickup',
        courierImminent: false,
        // PLACEHOLDER: Uber does not return a customer tracking URL yet
        trackingUrl: 'https://ubr.to/tracking',
      ),
    );
  }

  @override
  Future<Either<Failure, void>> cancelDelivery(
    String deliveryId,
    String reason,
  ) async {
    // Stub implementation
    return const Right(null);
  }
}
