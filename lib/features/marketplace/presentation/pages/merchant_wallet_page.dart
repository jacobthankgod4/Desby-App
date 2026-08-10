import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/merchant_provider.dart';
import '../../../../core/widgets/luxury_glass_card.dart';

class MerchantWalletPage extends ConsumerWidget {
  const MerchantWalletPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final balanceAsync = ref.watch(walletBalanceProvider(user?.id ?? ''));
    final historyAsync = ref.watch(payoutHistoryProvider(user?.id ?? ''));

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      appBar: AppBar(
        title: const Text('MERCHANT WALLET', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.amber, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceCard(balanceAsync),
            const SizedBox(height: 40),
            const Text('PAYOUT HISTORY', style: TextStyle(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            const SizedBox(height: 16),
            _buildHistoryList(historyAsync),
            const SizedBox(height: 60),
          ],
        ),
      ),
      bottomNavigationBar: _buildPayoutAction(context, ref, balanceAsync),
    );
  }

  Widget _buildBalanceCard(AsyncValue<Map<String, dynamic>> balanceAsync) {
    return balanceAsync.when(
      data: (data) => LuxuryGlassCard(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Text('SETTLED BALANCE', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 12),
            Text('₦${(data['balance'] as num).toStringAsFixed(2)}', 
              style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.hourglass_bottom_rounded, color: AppColors.amber, size: 14),
                const SizedBox(width: 8),
                Text('PENDING: ₦${(data['pending_payout'] as num).toStringAsFixed(2)}', 
                  style: const TextStyle(color: AppColors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amber)),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_wallet_outlined, color: Colors.white24, size: 48),
            const SizedBox(height: 12),
            const Text(
              'WALLET UNAVAILABLE',
              style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(AsyncValue<List<Map<String, dynamic>>> historyAsync) {
    return historyAsync.when(
      data: (history) => history.isEmpty
          ? const Center(child: Text('No payout history found.', style: TextStyle(color: Colors.white10)))
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = history[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('₦${(item['amount'] as num).toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text(item['created_at'].toString().split('T').first, style: const TextStyle(color: Colors.white24, fontSize: 10)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: _getStatusColor(item['status']).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(item['status'].toString().toUpperCase(), 
                          style: TextStyle(color: _getStatusColor(item['status']), fontSize: 8, fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                );
              },
            ),
      loading: () => const LinearProgressIndicator(color: AppColors.amber),
      error: (e, _) => const SizedBox(),
    );
  }

  Color _getStatusColor(dynamic status) {
    switch (status.toString()) {
      case 'processed': return Colors.greenAccent;
      case 'failed': return Colors.redAccent;
      default: return AppColors.amber;
    }
  }

  Widget _buildPayoutAction(BuildContext context, WidgetRef ref, AsyncValue<Map<String, dynamic>> balanceAsync) {
    final balance = balanceAsync.asData?.value['balance'] ?? 0.0;
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ElevatedButton(
        onPressed: balance > 0 ? () => _showPayoutDialog(context, ref, balance) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.amber,
          foregroundColor: AppColors.darkNavy,
          disabledBackgroundColor: Colors.white10,
          minimumSize: const Size(double.infinity, 64),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: const Text('REQUEST PAYOUT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
      ),
    );
  }

  void _showPayoutDialog(BuildContext context, WidgetRef ref, double maxAmount) {
    final amountController = TextEditingController(text: maxAmount.toString());
    final bankController = TextEditingController();
    final accountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('PAYOUT REQUEST', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController, 
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Amount (NGN)', labelStyle: TextStyle(color: Colors.white24)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bankController, 
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Bank Name', labelStyle: TextStyle(color: Colors.white24)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: accountController, 
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Account Number', labelStyle: TextStyle(color: Colors.white24)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              final user = ref.read(currentUserProvider);
              await ref.read(merchantRepositoryProvider).requestPayout(
                user!.id, 
                double.parse(amountController.text),
                {'bank': bankController.text, 'account': accountController.text}
              );
              ref.invalidate(walletBalanceProvider(user.id));
              ref.invalidate(payoutHistoryProvider(user.id));
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber, foregroundColor: AppColors.darkNavy),
            child: const Text('SUBMIT'),
          ),
        ],
      ),
    );
  }
}
