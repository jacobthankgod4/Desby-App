import '../../../../core/error/failures.dart';
import '../repositories/fabric_repository.dart';

class GetMerchantStatsUsecase {
  final FabricRepository repository;
  GetMerchantStatsUsecase(this.repository);
  Future<Result<Map<String, dynamic>>> call(String merchantId) =>
      repository.getMerchantStats(merchantId);
}
