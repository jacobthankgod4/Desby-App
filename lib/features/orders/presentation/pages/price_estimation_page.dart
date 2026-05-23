import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/data/repositories/firebase_auth_repository.dart';
import '../providers/logistics_provider.dart';

/// Provider for getting tailor pricing data from Firebase
final tailorPricingProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, tailorId) async {
  final localDatasource = ref.read(authLocalDatasourceProvider);
  final repo = FirebaseAuthRepository(localDatasource: localDatasource);
  return repo.getTailorById(tailorId);
});

class PriceEstimationPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> tailor;

  const PriceEstimationPage({super.key, required this.tailor});

  @override
  ConsumerState<PriceEstimationPage> createState() => _PriceEstimationPageState();
}

class _PriceEstimationPageState extends ConsumerState<PriceEstimationPage> {
  double _calculatedTotal = 0.0;
  
  // Default service pricing fallback
  static const Map<String, dynamic> servicePricing = {
    'stitchingPrice': 45000.0,
    'materialCost': 12500.0,
    'startingPrice': 20000.0,
    'currency': 'NGN',
  };

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final String tailorId = widget.tailor['id'] as String? ?? '';
    
    // Fetch real pricing from Firebase if tailor ID is available
    final pricingAsync = tailorId.isNotEmpty ? ref.watch(tailorPricingProvider(tailorId)) : null;
    
    final String tailorName = (widget.tailor['name'] ?? 'MASTER TAILOR').toString().toUpperCase();
    final String tailorAddress = (widget.tailor['location'] ?? 'LAGOS, NIGERIA').toString().toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.darkNavy, // NAVY GREEN THEME
      appBar: AppBar(
        title: const Text('PAYMENT RECEIPT', 
          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2.8)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.amber, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: pricingAsync != null
          ? pricingAsync.when(
              data: (tailorData) => _buildPricingContent(context, ref, user, tailorName, tailorAddress, tailorData),
              loading: () => _buildLoadingContent(),
              error: (_, __) => _buildPricingContent(context, ref, user, tailorName, tailorAddress, null),
            )
          : _buildPricingContent(context, ref, user, tailorName, tailorAddress, null),
      bottomNavigationBar: _buildBottomAction(context, _calculatedTotal),
    );
  }

  Widget _buildLoadingContent() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.amber),
    );
  }

  Widget _buildPricingContent(
    BuildContext context, 
    WidgetRef ref, 
    dynamic user, 
    String tailorName, 
    String tailorAddress,
    Map<String, dynamic>? tailorData,
  ) {
// TAILOR SETS PRICING: Fetch from tailor's profile in Firebase
    // Priority: 1) Profile pricing fields 2) Fallback to servicePricing 3) System defaults
    final baseStitching = (tailorData?['baseStitchingPrice'] as num?)?.toDouble() ?? 
                        servicePricing['stitchingPrice'] ?? 45000.0;
    final materialCost = (tailorData?['materialCost'] as num?)?.toDouble() ?? 
                        servicePricing['materialCost'] ?? 12500.0;
    final startingPrice = (tailorData?['startingPrice'] as num?)?.toDouble() ?? 
                        servicePricing['startingPrice'] ?? 20000.0;
    
// FETCH REAL LOGISTICS COST FROM FEZ (PRO PASS)
    // NO DEFAULT - ONLY FETCHED FEE
    final logisticsAsync = ref.watch(deliveryCostProvider(tailorData?['businessState'] ?? 'Lagos'));
    final double expressFee = logisticsAsync.when(
      data: (cost) => cost,
      loading: () => 0.0,
      error: (_, __) => 0.0,
    );

    final total = baseStitching + materialCost + expressFee;
    
    // Update local state for bottom action
    if (_calculatedTotal != total) {
      Future.microtask(() => setState(() => _calculatedTotal = total));
    }
    
    // Format currency
    final currency = servicePricing['currency'] ?? 'NGN';
    final currencySymbol = currency == 'NGN' ? '₦' : '$currency ';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03), // LAYERED DARK
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.amber.withValues(alpha: 0.1), width: 1.5),
        ),
        child: Column(
          children: [
            // 1. BUSINESS DETAILS HEADER
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Icon(Icons.verified_user_rounded, color: AppColors.amber, size: 40),
                  const SizedBox(height: 16),
                  Text(tailorName, 
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text(tailorAddress, 
                    style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  if (tailorData != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tailorData['hasPricing'] == true 
                          ? '${currencySymbol}${tailorData['startingPrice']?.toStringAsFixed(0)} STARTS FROM'
                          : 'PRICING NOT SET',
                        style: const TextStyle(color: AppColors.amber, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const Divider(height: 1, color: Colors.white12),
            
            // 2. RECEIPT ARCHITECTURE
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  _buildReceiptSection('CLIENT IDENTIFICATION', [
                    {'label': 'NAME', 'value': user?.name ?? 'ANONYMOUS CLIENT'},
                    {'label': 'CHANNEL', 'value': tailorData != null ? 'FIREBASE SYNCED' : 'SECURE SESSION'},
                    {'label': 'ID', 'value': 'DSB_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}'},
                  ]),
                  const SizedBox(height: 32),
_buildReceiptSection('PROJECT TIMELINE', [
                    {'label': 'INITIATED', 'value': 'ACTIVE NOW'},
                    {'label': 'HANDOVER', 'value': 'EST. 14 DAYS'},
                  ]),
                  const SizedBox(height: 32),
                  _buildPricingSection(currencySymbol, [
                    {'label': 'BASE STITCHING', 'value': baseStitching},
                    {'label': 'MATERIAL LOGISTICS', 'value': materialCost},
                    {'label': 'EXPRESS DISPATCH', 'value': expressFee},
                    {'label': 'ESTIMATED TOTAL', 'value': total, 'isTotal': true},
                  ]),
                ],
              ),
            ),

            // 3. SECURITY WATERMARK
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Text('ENCRYPTED BY DESBY OS', 
                style: TextStyle(color: Colors.white.withValues(alpha: 0.05), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptSection(String title, List<Map<String, String>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: AppColors.amber, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
        const SizedBox(height: 16),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item['label']!, style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700)),
              Text(item['value']!.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildPricingSection(String currencySymbol, List<Map<String, dynamic>> items) {
    return Column(
      children: [
        const Divider(color: Colors.white12),
        const SizedBox(height: 24),
        ...items.map((item) {
          final value = item['value'] as double;
          final isTotal = item['isTotal'] == true;
          final formattedValue = '$currencySymbol${value.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},'
          )}';
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item['label'] as String,
                  style: TextStyle(
                    color: isTotal ? Colors.white : Colors.white38,
                    fontSize: isTotal ? 14 : 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  formattedValue,
                  style: TextStyle(
                    color: isTotal ? AppColors.amber : Colors.white,
                    fontSize: isTotal ? 20 : 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBottomAction(BuildContext context, double total) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: AppColors.darkNavy,
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton(
            onPressed: () {
              // COMMERCIAL BRIDGE: Navigate to Checkout
              Navigator.pushNamed(
                context, 
                '/checkout', 
                arguments: {
                  'amount': total,
                  'orderId': 'ORD_${DateTime.now().millisecondsSinceEpoch}',
                }
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amber,
              foregroundColor: AppColors.darkNavy,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('SECURE CHECKOUT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5)),
                SizedBox(width: 12),
                Icon(Icons.lock_rounded, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
