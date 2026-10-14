import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../theme/colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../providers/shop_provider.dart';
import '../../domain/entities/shop_product.dart';
import '../../../../core/widgets/shell_app_bar.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/price_text_field.dart';

class VirtualAtelierPage extends ConsumerStatefulWidget {
  const VirtualAtelierPage({super.key});

  @override
  ConsumerState<VirtualAtelierPage> createState() => _VirtualAtelierPageState();
}

class _VirtualAtelierPageState extends ConsumerState<VirtualAtelierPage> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final user = ref.watch(currentUserProvider);
    final userId = user?.id ?? '';

    final profileAsync = ref.watch(userProfileProvider(userId));
    final productsAsync = ref.watch(shopNotifierProvider);

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: shellAppBar(
        context,
        title: 'MY SHOP',
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.amber,
            ),
            onPressed: () => _showAddProductDialog(context),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          // 5-column compact grid on wide screens, 3 on tablets and a
          // full-bleed 2-up lookbook layout on phones.
          final columns = width >= 1180 ? 5 : (width >= 820 ? 3 : 2);
          final overlayStyle = width < 820;
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: profileAsync.when(
                  data: (profile) => Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: _buildShopHeader(
                      profile?.businessName ?? 'Bespoke Atelier',
                      profile?.bio ?? 'No bio established yet.',
                    ),
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Text('Profile sync failed: $err'),
                ),
              ),

              _buildSectionHeader('YOUR DESIGNS'),
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: productsAsync.when(
                  data: (products) => products.isEmpty
                      ? SliverToBoxAdapter(
                          child: Center(
                            child: Text(
                              'YOUR SHOP IS EMPTY',
                              style: TextStyle(
                                color: colors.textMuted,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        )
                      : SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: overlayStyle ? 0.66 : 0.74,
                              ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildProductCard(
                              context,
                              products[index],
                              overlay: overlayStyle,
                            ),
                            childCount: products.length,
                          ),
                        ),
                  loading: () => const SliverToBoxAdapter(
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.amber),
                    ),
                  ),
                  error: (err, _) {
                    final msg = err.toString();
                    final isAuthError =
                        msg.contains('AuthRetryableFetchException') ||
                        msg.contains('statusCode: null');
                    if (isAuthError) {
                      return SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'YOUR SHOP IS EMPTY',
                              style: TextStyle(
                                color: colors.textMuted,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Text(
                              'Sync Error: $err',
                              style: TextStyle(
                                color: colors.statusError,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () => ref
                                  .read(shopNotifierProvider.notifier)
                                  .loadProducts(),
                              child: const Text(
                                'RETRY',
                                style: TextStyle(color: AppColors.amber),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildShopHeader(String name, String bio) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name.toUpperCase(),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.edit_note_rounded,
                  color: AppColors.amber,
                  size: 20,
                ),
                onPressed: () => ref.pushShell('/shop-setup'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            bio,
            style: TextStyle(
              color: context.colors.textMuted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Text(
          title,
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

  Widget _buildProductCard(
    BuildContext context,
    ShopProduct product, {
    bool overlay = false,
  }) {
    if (overlay) return _buildOverlayProductCard(context, product);
    return _buildCompactProductCard(context, product);
  }

  /// Phone layout: the photograph fills the whole tile and a premium
  /// gradient overlay carries the category, name, description and price.
  Widget _buildOverlayProductCard(BuildContext context, ShopProduct product) {
    final colors = context.colors;
    return GestureDetector(
      onTap: () => ref.pushShell('/add-product', {'product': product}),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.borderDefault),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (product.imageUrls.isNotEmpty)
              AppNetworkImage(
                url: product.imageUrls.first,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                placeholderIcon: Icons.checkroom_rounded,
              )
            else
              Container(
                color: colors.surface,
                child: const Center(
                  child: Icon(
                    Icons.checkroom_rounded,
                    color: AppColors.textMuted,
                    size: 36,
                  ),
                ),
              ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.9),
                    ],
                    stops: const [0, 0.45, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.amber.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  product.category.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.amber,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white.withValues(alpha: 0.85),
                  size: 18,
                ),
                onPressed: () => _deleteProduct(product.id),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      product.description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 10,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    '\u20A6${formatPriceDigits(product.price.toInt().toString())}',
                    style: const TextStyle(
                      color: AppColors.amber,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Desktop/tablet layout: a compact card optimised for dense 5-up grids.
  Widget _buildCompactProductCard(BuildContext context, ShopProduct product) {
    final colors = context.colors;
    return GestureDetector(
      onTap: () => ref.pushShell('/add-product', {'product': product}),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.borderDefault),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: product.imageUrls.isNotEmpty
                    ? AppNetworkImage(
                        url: product.imageUrls.first,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        placeholderIcon: Icons.checkroom_rounded,
                      )
                    : Center(
                        child: Icon(
                          Icons.checkroom_rounded,
                          color: colors.textMuted,
                          size: 40,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name.toUpperCase(),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\u20A6${formatPriceDigits(product.price.toInt().toString())}',
                    style: TextStyle(
                      color: AppColors.amber,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: colors.statusError,
                      size: 18,
                    ),
                    onPressed: () => _deleteProduct(product.id),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    ref.pushShell('/add-product');
  }

  void _deleteProduct(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          'DELETE PRODUCT?',
          style: TextStyle(
            color: context.colors.textOnAmber,
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
        content: const Text(
          'This action cannot be undone.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(shopNotifierProvider.notifier).deleteProduct(id);
              Navigator.pop(context);
            },
            child: const Text(
              'DELETE',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
