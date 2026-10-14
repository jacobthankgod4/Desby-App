import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../theme/colors.dart';

class SellerTrustCard extends ConsumerStatefulWidget {
  final String? sellerId;
  const SellerTrustCard({super.key, this.sellerId});

  @override
  ConsumerState<SellerTrustCard> createState() => _SellerTrustCardState();
}

class _SellerTrustCardState extends ConsumerState<SellerTrustCard> {
  late final Future<Map<String, dynamic>> _sellerFuture;

  @override
  void initState() {
    super.initState();
    _sellerFuture = _fetchSellerData();
  }

  Future<Map<String, dynamic>> _fetchSellerData() async {
    final sid = widget.sellerId;
    if (sid == null) return {};
    try {
      return await Supabase.instance.client
              .from('profiles')
              .select('name, business_name, is_verified, rating')
              .eq('id', sid)
              .maybeSingle() ??
          {};
    } catch (e) {
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sid = widget.sellerId;
    if (sid == null) return const SizedBox.shrink();

    return FutureBuilder<Map<String, dynamic>>(
      future: _sellerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 30,
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.amber),
            ),
          );
        }

        final data = snapshot.data ?? {};
        final name = data['name'] ?? data['business_name'] ?? 'Merchant';
        final isVerified = data['is_verified'] ?? false;
        final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
        final initials = name.length >= 2
            ? name.substring(0, 2).toUpperCase()
            : name.toUpperCase();

        return Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: colors.borderDefault),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 30,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: colors.scaffoldBg,
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: AppColors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: AppColors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              rating > 0 ? rating.toStringAsFixed(1) : 'New',
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (isVerified) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'VERIFIED',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Divider(color: colors.divider),
              const SizedBox(height: 20),
              _buildTrustStat(
                'Merchant Tier',
                isVerified ? 'Verified' : 'Standard',
                Colors.blue,
              ),
              const SizedBox(height: 28),
              OutlinedButton(
                onPressed: () =>
                    ref.pushShell('/seller-portfolio', {'sellerId': sid}),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  side: BorderSide(color: colors.textOnAmber),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  backgroundColor: colors.surfaceAlt,
                ),
                child: Text(
                  'VIEW MERCHANT PORTFOLIO',
                  style: TextStyle(
                    color: colors.textOnAmber,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrustStat(String label, String value, Color color) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
