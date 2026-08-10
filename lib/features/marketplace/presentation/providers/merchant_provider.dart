import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/supabase_merchant_repository.dart';
import '../../domain/repositories/merchant_repository.dart';

final merchantRepositoryProvider = Provider<MerchantRepository>((ref) {
  return SupabaseMerchantRepository();
});

final walletBalanceProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, merchantId) async {
  final repo = ref.watch(merchantRepositoryProvider);
  final result = await repo.getWalletBalance(merchantId);
  return result.fold(
    (failure) => throw Exception('Unable to load wallet balance.'),
    (balance) => balance,
  );
});

final payoutHistoryProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, merchantId) async {
  final repo = ref.watch(merchantRepositoryProvider);
  final result = await repo.getPayoutHistory(merchantId);
  return result.fold(
    (failure) => throw Exception('Unable to load payout history.'),
    (history) => history,
  );
});
