import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/merchant_repository.dart';

class SupabaseMerchantRepository implements MerchantRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<Result<Map<String, dynamic>>> getWalletBalance(String merchantId) async {
    try {
      final response = await _supabase
          .from('merchant_wallets')
          .select()
          .eq('user_id', merchantId)
          .maybeSingle();
      
      if (response == null) {
        return const Success({'balance': 0.0, 'pending_payout': 0.0});
      }
      return Success(Map<String, dynamic>.from(response));
    } catch (e) {
      return Failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> requestPayout(String merchantId, double amount, Map<String, dynamic> bankDetails) async {
    try {
      await _supabase.from('payout_requests').insert({
        'seller_id': merchantId,
        'amount': amount,
        'bank_details': bankDetails,
      });
      return const Success(null);
    } catch (e) {
      return Failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getPayoutHistory(String merchantId) async {
    try {
      final response = await _supabase
          .from('payout_requests')
          .select()
          .eq('seller_id', merchantId)
          .order('created_at', ascending: false);
      
      return Success((response as List).map((e) => Map<String, dynamic>.from(e)).toList());
    } catch (e) {
      return Failure(UnknownFailure(message: e.toString()));
    }
  }
}
