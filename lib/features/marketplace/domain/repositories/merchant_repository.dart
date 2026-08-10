import '../../../../core/error/failures.dart';

abstract class MerchantRepository {
  Future<Result<Map<String, dynamic>>> getWalletBalance(String merchantId);
  Future<Result<void>> requestPayout(String merchantId, double amount, Map<String, dynamic> bankDetails);
  Future<Result<List<Map<String, dynamic>>>> getPayoutHistory(String merchantId);
}
