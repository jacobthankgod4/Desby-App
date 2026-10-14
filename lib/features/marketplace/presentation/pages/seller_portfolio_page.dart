import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../theme/colors.dart';
import '../providers/fabric_provider.dart';
import '../widgets/fabric_card_grid.dart';
import '../../../../core/widgets/shell_scope.dart';

class SellerPortfolioPage extends ConsumerStatefulWidget {
  final String sellerId;

  const SellerPortfolioPage({super.key, required this.sellerId});

  @override
  ConsumerState<SellerPortfolioPage> createState() =>
      _SellerPortfolioPageState();
}

class _SellerPortfolioPageState extends ConsumerState<SellerPortfolioPage> {
  late final Future<Map<String, dynamic>> _sellerFuture;

  @override
  void initState() {
    super.initState();
    _sellerFuture = _fetchSellerData();
  }

  Future<Map<String, dynamic>> _fetchSellerData() async {
    try {
      return await Supabase.instance.client
              .from('profiles')
              .select('name, business_name, is_verified, rating')
              .eq('id', widget.sellerId)
              .maybeSingle() ??
          {};
    } catch (e) {
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final inventoryAsync = ref.watch(sellerInventoryProvider(widget.sellerId));

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: CustomScrollView(
        slivers: [
          _buildHeroHeader(),
          _buildStatsSection(),
          _buildInventoryHeader(),

          inventoryAsync.when(
            data: (fabrics) {
              if (fabrics.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'NO ACTIVE LISTINGS',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverToBoxAdapter(
                  child: FabricCardGrid(isGridView: true, fabrics: fabrics),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.amber),
              ),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'MERCHANT OFFLINE',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => ref.invalidate(
                        sellerInventoryProvider(widget.sellerId),
                      ),
                      child: const Text(
                        'RETRY',
                        style: TextStyle(color: AppColors.amber),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 60)),
        ],
      ),
    );
  }

  Widget _buildHeroHeader() {
    final colors = context.colors;
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: colors.scaffoldBg,
      flexibleSpace: FlexibleSpaceBar(
        background: FutureBuilder<Map<String, dynamic>>(
          future: _sellerFuture,
          builder: (context, snapshot) {
            final data = snapshot.data ?? {};
            final name = data['name'] ?? data['business_name'] ?? 'Merchant';
            final isVerified = data['is_verified'] ?? false;

            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFF1A1A1A), colors.scaffoldBg],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.amber.withValues(alpha: 0.1),
                    child: Text(
                      name.length >= 2
                          ? name.substring(0, 2).toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: AppColors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isVerified)
                    const Text(
                      'VERIFIED MERCHANT',
                      style: TextStyle(
                        color: AppColors.amber,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  Text(
                    name,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      leading: ShellScope.isInside(context)
          ? const SizedBox.shrink()
          : IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: colors.textPrimary,
                size: 20,
              ),
              onPressed: () => ref.popShell(),
            ),
    );
  }

  Widget _buildStatsSection() {
    final colors = context.colors;
    return SliverToBoxAdapter(
      child: FutureBuilder<Map<String, dynamic>>(
        future: _sellerFuture,
        builder: (context, snapshot) {
          final data = snapshot.data ?? {};
          final rating = (data['rating'] as num?)?.toDouble();
          final isVerified = data['is_verified'] ?? false;

          return Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat(
                  'Rating',
                  rating != null && rating > 0
                      ? rating.toStringAsFixed(1)
                      : 'New',
                  Icons.star_rounded,
                  AppColors.amber,
                ),
                _buildStat(
                  'Status',
                  isVerified ? 'Verified' : 'Active',
                  Icons.bolt_rounded,
                  Colors.green,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon, Color color) {
    final colors = context.colors;
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: colors.textMuted,
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryHeader() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Text(
          'COLLECTION INVENTORY',
          style: TextStyle(
            color: AppColors.amber,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}
