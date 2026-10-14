import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desby_app/theme/colors.dart';

import '../../../tailor/domain/entities/shop_product.dart';
import '../../../tailor/presentation/providers/shop_provider.dart';
import '../providers/invite_provider.dart';

class InviteShopStep extends ConsumerWidget {
  const InviteShopStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inviteState = ref.watch(inviteNotifierProvider);
    final tailorId = inviteState.client?.tailorId ?? '';
    final selectedProduct = inviteState.selectedProduct;

    if (tailorId.isEmpty) {
      return _buildNoTailor(context, ref);
    }

    final productsAsync = ref.watch(shopProductsProvider(tailorId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'BROWSE SHOP',
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a garment you like, or skip to describe your own.',
            style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 32),

          if (selectedProduct != null) ...[
            _buildSelectedProductCard(selectedProduct, ref, context),
            const SizedBox(height: 24),
          ],

          productsAsync.when(
            data: (products) {
              if (products.isEmpty) {
                return _buildNoProducts(context, ref);
              }
              return _buildProductGrid(products, selectedProduct, ref, context);
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(color: AppColors.amber),
              ),
            ),
            error: (e, _) => _buildNoProducts(context, ref),
          ),

          const SizedBox(height: 24),

          Center(
            child: TextButton(
              onPressed: () {
                ref
                    .read(inviteNotifierProvider.notifier)
                    .clearProductSelection();
                ref.read(inviteNotifierProvider.notifier).nextStep();
              },
              child: Text(
                "SKIP — I'll describe what I want",
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSelectedProductCard(
    Map<String, dynamic> product,
    WidgetRef ref,
    BuildContext buildContext,
  ) {
    final name = product['name'] as String? ?? '';
    final price = (product['price'] as num?)?.toDouble() ?? 0.0;
    final images = (product['image_urls'] as List?)?.cast<String>() ?? [];
    final image = images.isNotEmpty ? images.first : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: buildContext.colors.surfaceHover,
              borderRadius: BorderRadius.circular(12),
              image: image != null
                  ? DecorationImage(
                      image: NetworkImage(image),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: image == null
                ? const Icon(Icons.checkroom, color: AppColors.amber, size: 28)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SELECTED',
                  style: TextStyle(
                    color: AppColors.amber,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name.toUpperCase(),
                  style: TextStyle(
                    color: buildContext.colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₦${price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppColors.amber,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => ref
                .read(inviteNotifierProvider.notifier)
                .clearProductSelection(),
            icon: Icon(
              Icons.close_rounded,
              color: buildContext.colors.textSecondary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(
    List<ShopProduct> products,
    Map<String, dynamic>? selectedProduct,
    WidgetRef ref,
    BuildContext context,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final isSelected =
            selectedProduct != null && selectedProduct['id'] == product.id;

        return _buildProductCard(product, isSelected, ref, context);
      },
    );
  }

  Widget _buildProductCard(
    ShopProduct product,
    bool isSelected,
    WidgetRef ref,
    BuildContext context,
  ) {
    final hasImages = product.imageUrls.isNotEmpty;
    final image = hasImages ? product.imageUrls.first : null;

    return InkWell(
      onTap: () {
        ref.read(inviteNotifierProvider.notifier).selectProduct({
          'id': product.id,
          'name': product.name,
          'price': product.price,
          'image_urls': product.imageUrls,
          'category': product.category,
          'available_fabrics': product.availableFabrics,
          'available_sizes': product.availableSizes,
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.amber.withValues(alpha: 0.1)
              : context.colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: AppColors.amber, width: 2)
              : Border.all(color: context.colors.borderDefault),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: context.colors.surfaceHover,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  image: image != null
                      ? DecorationImage(
                          image: NetworkImage(image),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: image == null
                    ? Icon(
                        Icons.checkroom_rounded,
                        color: context.colors.borderSubtle,
                        size: 40,
                      )
                    : null,
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name.toUpperCase(),
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₦${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: AppColors.amber,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.amber,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'SELECTED',
                          style: TextStyle(
                            color: context.colors.textOnAmber,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoTailor(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store_outlined,
              size: 48,
              color: context.colors.borderSubtle,
            ),
            const SizedBox(height: 16),
            Text(
              'No tailor linked',
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () =>
                    ref.read(inviteNotifierProvider.notifier).nextStep(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  foregroundColor: AppColors.darkNavy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'CONTINUE',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoProducts(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.checkroom_outlined,
              size: 48,
              color: context.colors.borderSubtle,
            ),
            const SizedBox(height: 16),
            Text(
              'No products yet',
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your tailor hasn\'t added products to their shop yet.',
              style: TextStyle(color: context.colors.textMuted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
