import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/colors.dart';

class NigerianBank {
  final String code;
  final String name;

  const NigerianBank({required this.code, required this.name});
}

/// Comprehensive list of all Nigerian banks supported by Flutterwave/Paystack/NIBSS.
/// Sorted alphabetically by name. Includes commercial banks, digital banks,
/// PSBs, MFBs, merchant banks, and mortgage banks.
const List<NigerianBank> kNigerianBanks = [
  NigerianBank(code: '044', name: 'Access Bank'),
  NigerianBank(code: '063', name: 'Access Bank (Diamond)'),
  NigerianBank(code: '120001', name: '9 Payment Service Bank'),
  NigerianBank(code: '070010', name: 'Abbey Mortgage Bank'),
  NigerianBank(code: '090260', name: 'Above Only MFB'),
  NigerianBank(code: '090545', name: 'Abulesoro MFB'),
  NigerianBank(code: '120004', name: 'Airtel Smartcash PSB'),
  NigerianBank(code: '035A', name: 'ALAT by WEMA'),
  NigerianBank(code: '090180', name: 'Amju Unique MFB'),
  NigerianBank(code: '090307', name: 'Aramoko MFB'),
  NigerianBank(code: '090001', name: 'ASO Savings and Loans'),
  NigerianBank(code: '090172', name: 'Astrapolaris MFB'),
  NigerianBank(code: '090188', name: 'Bainescredit MFB'),
  NigerianBank(code: '090148', name: 'Bowen Microfinance Bank'),
  NigerianBank(code: '100026', name: 'Carbon'),
  NigerianBank(code: '090154', name: 'CEMCS Microfinance Bank'),
  NigerianBank(code: '090397', name: 'Chanelle MFB'),
  NigerianBank(code: '023', name: 'Citibank Nigeria'),
  NigerianBank(code: '090365', name: 'Corestep MFB'),
  NigerianBank(code: '060001', name: 'Coronation Merchant Bank'),
  NigerianBank(code: '090526', name: 'Crescent MFB'),
  NigerianBank(code: '050', name: 'Ecobank Nigeria'),
  NigerianBank(code: '090552', name: 'Ekimogun MFB'),
  NigerianBank(code: '090097', name: 'Ekondo MFB'),
  NigerianBank(code: '090328', name: 'Eyowo'),
  NigerianBank(code: '070', name: 'Fidelity Bank'),
  NigerianBank(code: '090366', name: 'Firmus MFB'),
  NigerianBank(code: '011', name: 'First Bank of Nigeria'),
  NigerianBank(code: '214', name: 'First City Monument Bank (FCMB)'),
  NigerianBank(code: '400001', name: 'FSDH Merchant Bank'),
  NigerianBank(code: '070009', name: 'Gateway Mortgage Bank'),
  NigerianBank(code: '000027', name: 'Globus Bank'),
  NigerianBank(code: '100022', name: 'GoMoney'),
  NigerianBank(code: '058', name: 'Guaranty Trust Bank (GTBank)'),
  NigerianBank(code: '090147', name: 'Hackman MFB'),
  NigerianBank(code: '090121', name: 'Hasal MFB'),
  NigerianBank(code: '030', name: 'Heritage Bank'),
  NigerianBank(code: '120002', name: 'Hope PSB'),
  NigerianBank(code: '090118', name: 'Ibile MFB'),
  NigerianBank(code: '090536', name: 'Ikoyi-Osun MFB'),
  NigerianBank(code: '090157', name: 'Infinity MFB'),
  NigerianBank(code: '301', name: 'Jaiz Bank'),
  NigerianBank(code: '090320', name: 'Kadpoly MFB'),
  NigerianBank(code: '082', name: 'Keystone Bank'),
  NigerianBank(code: '090380', name: 'Kredi Money MFB'),
  NigerianBank(code: '090267', name: 'Kuda Bank'),
  NigerianBank(code: '070012', name: 'Lagos Building Investment Company'),
  NigerianBank(code: '090435', name: 'Links MFB'),
  NigerianBank(code: '000029', name: 'Lotus Bank'),
  NigerianBank(code: '090321', name: 'Mayfair MFB'),
  NigerianBank(code: '090763', name: 'Mint MFB'),
  NigerianBank(code: '120003', name: 'MTN Momo PSB'),
  NigerianBank(code: '090405', name: 'Moniepoint MFB'),
  NigerianBank(code: '327', name: 'Paga'),
  NigerianBank(code: '100033', name: 'PalmPay'),
  NigerianBank(code: '000030', name: 'Parallex Bank'),
  NigerianBank(code: '100003', name: 'Parkway - ReadyCash'),
  NigerianBank(code: '305', name: 'OPay (Paycom)'),
  NigerianBank(code: '090165', name: 'Petra MFB'),
  NigerianBank(code: '076', name: 'Polaris Bank'),
  NigerianBank(code: '000031', name: 'PremiumTrust Bank'),
  NigerianBank(code: '101', name: 'Providus Bank'),
  NigerianBank(code: '090261', name: 'QuickFund MFB'),
  NigerianBank(code: '502', name: 'Rand Merchant Bank'),
  NigerianBank(code: '070011', name: 'Refuge Mortgage Bank'),
  NigerianBank(code: '090175', name: 'Rubies MFB'),
  NigerianBank(code: '090286', name: 'Safe Haven MFB'),
  NigerianBank(code: '090524', name: 'Solid Rock MFB'),
  NigerianBank(code: '090325', name: 'Sparkle'),
  NigerianBank(code: '221', name: 'Stanbic IBTC Bank'),
  NigerianBank(code: '068', name: 'Standard Chartered Bank'),
  NigerianBank(code: '090262', name: 'Stellas MFB'),
  NigerianBank(code: '232', name: 'Sterling Bank'),
  NigerianBank(code: '100', name: 'Suntrust Bank'),
  NigerianBank(code: '000026', name: 'TAJ Bank'),
  NigerianBank(code: '090426', name: 'Tangerine Money'),
  NigerianBank(code: '090409', name: 'TCF MFB'),
  NigerianBank(code: '000025', name: 'Titan Trust Bank'),
  NigerianBank(code: '100039', name: 'Titan Paystack'),
  NigerianBank(code: '090193', name: 'Unical MFB'),
  NigerianBank(code: '032', name: 'Union Bank of Nigeria'),
  NigerianBank(code: '033', name: 'United Bank for Africa (UBA)'),
  NigerianBank(code: '215', name: 'Unity Bank'),
  NigerianBank(code: '090110', name: 'VFD MFB'),
  NigerianBank(code: '035', name: 'Wema Bank'),
  NigerianBank(code: '057', name: 'Zenith Bank'),
];

/// Shows a searchable bank picker dialog. Returns the selected [NigerianBank] or null.
Future<NigerianBank?> showBankSearchDialog(BuildContext context) async {
  final colors = context.colors;
  String searchQuery = '';

  return showGeneralDialog<NigerianBank>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Select Bank',
    transitionDuration: const Duration(milliseconds: 250),
    transitionBuilder: (ctx, a1, a2, child) {
      return FadeTransition(
        opacity: a1,
        child: ScaleTransition(
          scale: CurvedAnimation(parent: a1, curve: Curves.easeOutBack),
          child: child,
        ),
      );
    },
    pageBuilder: (ctx, a1, a2) {
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          final query = searchQuery.toLowerCase();
          final filtered = query.isEmpty
              ? kNigerianBanks
              : kNigerianBanks
                  .where((b) =>
                      b.name.toLowerCase().contains(query) ||
                      b.code.toLowerCase().contains(query))
                  .toList();

          return Dialog(
            backgroundColor: colors.dialogBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              width: 420,
              height: 520,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance_rounded,
                          color: AppColors.amber, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Select Your Bank',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded,
                            color: colors.textMuted, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    autofocus: true,
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                    onChanged: (val) {
                      searchQuery = val;
                      setDialogState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: 'Search bank name or code...',
                      hintStyle: TextStyle(color: colors.textHint, fontSize: 13),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: colors.textMuted, size: 20),
                      filled: true,
                      fillColor: colors.inputFill,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.amber),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${filtered.length} banks',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              'No bank found',
                              style: TextStyle(
                                color: colors.textMuted,
                                fontSize: 14,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: colors.borderSubtle.withValues(alpha: 0.5),
                            ),
                            itemBuilder: (ctx, i) {
                              final bank = filtered[i];
                              return ListTile(
                                dense: true,
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                title: Text(
                                  bank.name,
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  'Code: ${bank.code}',
                                  style: TextStyle(
                                    color: colors.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                                onTap: () => Navigator.pop(ctx, bank),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
