import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/merchant_repository.dart';

class SupabaseMerchantRepository implements MerchantRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<Result<Map<String, dynamic>>> getWalletBalance(
    String merchantId,
  ) async {
    try {
      // `wallet_balance()` takes no user argument and derives the caller from
      // auth.uid() inside the function, so it cannot be used to read someone
      // else's balance. merchantId is retained on the interface for callers but
      // is intentionally not trusted here.
      final balance = await _supabase.rpc('wallet_balance');
      if (balance is! num) {
        return const Success({'balance': 0.0, 'pending_payout': 0.0});
      }
      final row = await _supabase
          .from('merchant_wallets')
          .select('pending_payout')
          .maybeSingle();
      return Success({
        'balance': balance.toDouble(),
        'pending_payout':
            (row?['pending_payout'] as num?)?.toDouble() ?? 0.0,
      });
    } catch (e) {
      return Failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> requestPayout(
    String merchantId,
    double amount,
    Map<String, dynamic> bankDetails,
  ) async {
    try {
      // The insert now happens inside `request_wallet_payout()`, which checks
      // ownership and available balance and moves the money from balance to
      // pending in one transaction. The client no longer writes payout rows.
      final result = await _supabase.rpc(
        'request_wallet_payout',
        params: {'p_amount': amount},
      );
      if (result is Map && result.containsKey('status')) {
        debugPrint('[MERCHANT] Wallet payout ${result['status']}');
        return const Success(null);
      }
      return const Failure(
        UnknownFailure(message: 'Payout could not be queued'),
      );
    } catch (e) {
      debugPrint('[MERCHANT] Wallet payout error: $e');
      return Failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getPayoutHistory(
    String merchantId,
  ) async {
    try {
      final response = await _supabase
          .from('payout_requests')
          .select()
          .eq('seller_id', merchantId)
          .order('created_at', ascending: false);

      return Success(
        (response as List).map((e) => Map<String, dynamic>.from(e)).toList(),
      );
    } catch (e) {
      return Failure(UnknownFailure(message: e.toString()));
    }
  }

  /// Queue a payout after delivery confirmation.
  ///
  /// Delegates to the `release_order_payout` database function, which records
  /// the payout row and flips `payment_status` in one transaction and is
  /// idempotent per order. The actual bank transfer is initiated server-side by
  /// an Edge Function that holds the Flutterwave secret.
  ///
  /// The previous implementation credited the wallet *and* issued a transfer
  /// from the browser, which paid the merchant twice and could never succeed
  /// anyway -- `merchant_wallets` had no INSERT policy.
  Future<Result<Map<String, dynamic>>> creditWalletAndPayout({
    required String merchantId,
    required String orderId,
    required double tailorPayout,
    required String accountBank,
    required String accountNumber,
    required String recipientName,
  }) async {
    try {
      final result = await _supabase.rpc(
        'release_order_payout',
        params: {'p_order_id': orderId},
      );

      if (result is Map && result.containsKey('status')) {
        debugPrint('[MERCHANT] Payout ${result['status']} for order $orderId');
        return Success(Map<String, dynamic>.from(result));
      }

      return const Failure(
        UnknownFailure(message: 'Payout could not be queued'),
      );
    } catch (e) {
      debugPrint('[MERCHANT] Payout queue error: $e');
      return Failure(UnknownFailure(message: e.toString()));
    }
  }
}
