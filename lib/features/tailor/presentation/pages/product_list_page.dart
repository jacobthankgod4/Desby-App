import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../theme/colors.dart';
import '../providers/shop_provider.dart';
import '../../domain/entities/shop_product.dart';
import '../../../../core/widgets/shell_app_bar.dart';
import '../../../../core/widgets/app_network_image.dart';

class ProductListPage extends ConsumerStatefulWidget {
  const ProductListPage({super.key});

  @override
  ConsumerState<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends ConsumerState<ProductListPage> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
            onPressed: () => ref.pushShell('/add-product'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.amber,
        backgroundColor: colors.scaffoldBg,
        onRefresh: () async {
          ref.read(shopNotifierProvider.notifier).loadProducts();
        },
        child: productsAsync.when(
          data: (products) => products.isEmpty
              ? _buildEmptyState()
              : _buildProductGrid(products),
          loading: () => _buildLoadingSkeleton(),
          error: (err, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: colors.statusError,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load products',
                  style: TextStyle(color: colors.textPrimary, fontSize: 12),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () =>
                      ref.read(shopNotifierProvider.notifier).loadProducts(),
                  child: const Text(
                    'RETRY',
                    style: TextStyle(
                      color: AppColors.amber,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: AppColors.amber,
                size: 36,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'YOUR SHOP IS EMPTY',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first product to start selling to clients.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              height: 48,
              child: ElevatedButton(
                onPressed: () => ref.pushShell('/add-product'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  foregroundColor: colors.scaffoldBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'ADD FIRST PRODUCT',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.72,
        ),
        itemCount: 6,
        itemBuilder: (context, index) => Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
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
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colors.surfaceHover,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 50,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors.borderDefault,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductGrid(List<ShopProduct> products) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${products.length} PRODUCT${products.length == 1 ? '' : 'S'}',
                  style: const TextStyle(
                    color: AppColors.amber,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => ref.pushShell('/add-product'),
                  icon: const Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: AppColors.amber,
                  ),
                  label: const Text(
                    'ADD NEW',
                    style: TextStyle(
                      color: AppColors.amber,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.72,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildProductCard(products[index]),
              childCount: products.length,
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ],
    );
  }

  Widget _buildProductCard(ShopProduct product) {
    final colors = context.colors;
    return GestureDetector(
      onTap: () => ref.pushShell('/add-product', {'product': product}),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.colors.surface),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
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
                  if (!product.isVisible)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.colors.scaffoldBg,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.visibility_off_rounded,
                            color: colors.textMuted,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _toggleVisibility(product),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: context.colors.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          product.isVisible
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          color: product.isVisible
                              ? AppColors.successGreen
                              : colors.textMuted,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
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
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '\u20A6${product.price.toInt()}',
                        style: const TextStyle(
                          color: AppColors.amber,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.category.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.amber,
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      color: colors.textMuted,
                      size: 18,
                    ),
                    onPressed: () =>
                        ref.pushShell('/add-product', {'product': product}),
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: colors.statusError,
                      size: 18,
                    ),
                    onPressed: () => _deleteProduct(product),
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleVisibility(ShopProduct product) {
    ref
        .read(shopNotifierProvider.notifier)
        .toggleVisibility(product.id, !product.isVisible);
  }

  void _deleteProduct(ShopProduct product) {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.scaffoldBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'DELETE PRODUCT?',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${product.name}"? This action cannot be undone.',
          style: TextStyle(color: colors.textPrimary, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: TextStyle(color: colors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              ref.read(shopNotifierProvider.notifier).deleteProduct(product.id);
              Navigator.pop(context);
            },
            child: Text(
              'DELETE',
              style: TextStyle(
                color: colors.statusError,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
