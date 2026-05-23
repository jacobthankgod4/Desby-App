import '../../../../core/error/failures.dart';
import '../entities/order.dart';

abstract class LogisticsRepository {
  Future<Result<String>> summonRider(OrderEntity order);
  Future<Result<Map<String, dynamic>>> trackDelivery(String fezOrderNo);
  Future<Result<double>> estimateCost(String destinationState);
}
