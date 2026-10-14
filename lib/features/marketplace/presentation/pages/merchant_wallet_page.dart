import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/merchant_provider.dart';
import '../../../../core/widgets/luxury_glass_card.dart';
import '../../../../core/widgets/shell_app_bar.dart';
import '../../../../core/widgets/price_text_field.dart';

class MerchantWalletPage extends ConsumerWidget {
  const MerchantWalletPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final user = ref.watch(currentUserProvider);
    final balanceAsync = ref.watch(walletBalanceProvider(user?.id ?? ''));
    final historyAsync = ref.watch(payoutHistoryProvider(user?.id ?? ''));

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: shellAppBar(context, title: 'MERCHANT WALLET'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceCard(context, balanceAsync),
            const SizedBox(height: 40),
            const Text(
              'PAYOUT HISTORY',
              style: TextStyle(
                color: AppColors.amber,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _buildHistoryList(context, historyAsync),
            const SizedBox(height: 60),
          ],
        ),
      ),
      bottomNavigationBar: _buildPayoutAction(context, ref, balanceAsync),
    );
  }

  Widget _buildBalanceCard(
    BuildContext context,
    AsyncValue<Map<String, dynamic>> balanceAsync,
  ) {
    final colors = context.colors;
    return balanceAsync.when(
      data: (data) => LuxuryGlassCard(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Text(
              'SETTLED BALANCE',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '\u20A6${(data['balance'] as num).toStringAsFixed(2)}',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.hourglass_bottom_rounded,
                  color: AppColors.amber,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Text(
                  'PENDING: \u20A6${(data['pending_payout'] as num).toStringAsFixed(2)}',
                  style: TextStyle(
                    color: AppColors.amber,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.amber),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              color: colors.textMuted,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'WALLET UNAVAILABLE',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again.',
              style: TextStyle(color: colors.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(
    BuildContext context,
    AsyncValue<List<Map<String, dynamic>>> historyAsync,
  ) {
    final colors = context.colors;
    return historyAsync.when(
      data: (history) {
        return history.isEmpty
            ? Center(
                child: Text(
                  'No payout history found.',
                  style: TextStyle(color: colors.textMuted),
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = history[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '\u20A6${(item['amount'] as num).toStringAsFixed(0)}',
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              item['created_at'].toString().split('T').first,
                              style: TextStyle(
                                color: colors.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              item['status'],
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item['status'].toString().toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(item['status']),
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
      },
      loading: () => const LinearProgressIndicator(color: AppColors.amber),
      error: (e, _) => const SizedBox(),
    );
  }

  Color _getStatusColor(dynamic status) {
    switch (status.toString()) {
      case 'processed':
        return Colors.greenAccent;
      case 'failed':
        return Colors.redAccent;
      default:
        return AppColors.amber;
    }
  }

  Widget _buildPayoutAction(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<Map<String, dynamic>> balanceAsync,
  ) {
    final colors = context.colors;
    final balance = balanceAsync.asData?.value['balance'] ?? 0.0;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: ElevatedButton(
        onPressed: balance > 0
            ? () => _showPayoutDialog(context, ref, balance)
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.amber,
          foregroundColor: AppColors.darkNavy,
          disabledBackgroundColor: colors.borderSubtle,
          minimumSize: const Size(double.infinity, 64),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: const Text(
          'REQUEST PAYOUT',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
      ),
    );
  }

  void _showPayoutDialog(
    BuildContext context,
    WidgetRef ref,
    double maxAmount,
  ) {
    final colors = context.colors;
    final amountController = TextEditingController(text: maxAmount.toString());
    final bankController = TextEditingController();
    final accountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'PAYOUT REQUEST',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: priceInputFormatters,
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Amount (NGN)',
                hintStyle: TextStyle(color: colors.textHint, fontSize: 13),
                filled: true,
                fillColor: colors.inputFill,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.amber,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bankController,
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Bank Name',
                hintStyle: TextStyle(color: colors.textHint, fontSize: 13),
                filled: true,
                fillColor: colors.inputFill,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.amber,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: accountController,
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Account Number',
                hintStyle: TextStyle(color: colors.textHint, fontSize: 13),
                filled: true,
                fillColor: colors.inputFill,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.amber,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              final user = ref.read(currentUserProvider);
              if (user == null) return;
              await ref.read(merchantRepositoryProvider).requestPayout(
                user.id,
                double.parse(priceToDigits(amountController.text)),
                {
                  'bank': bankController.text,
                  'account': accountController.text,
                },
              );
              ref.invalidate(walletBalanceProvider(user.id));
              ref.invalidate(payoutHistoryProvider(user.id));
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amber,
              foregroundColor: AppColors.darkNavy,
            ),
            child: const Text('SUBMIT'),
          ),
        ],
      ),
    );
  }
}
