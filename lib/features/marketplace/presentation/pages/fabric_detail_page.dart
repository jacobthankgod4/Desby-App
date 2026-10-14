import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../config/app_config.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/providers/layout_provider.dart';
import '../../../../theme/colors.dart';
import '../../domain/entities/fabric.dart';
import '../providers/fabric_provider.dart';
import '../widgets/specification_table.dart';
import '../widgets/product_narrative.dart';
import '../widgets/seller_trust_card.dart';
import '../widgets/trust_action_footer.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../../core/widgets/shell_app_bar.dart';
import '../../../../core/widgets/app_network_image.dart';

/// FabricDetailPage - Shows detailed view of a fabric with images, specs, and purchase options
class FabricDetailPage extends ConsumerStatefulWidget {
  final String fabricId;

  const FabricDetailPage({super.key, required this.fabricId});

  @override
  ConsumerState<FabricDetailPage> createState() => _FabricDetailPageState();
}

class _FabricDetailPageState extends ConsumerState<FabricDetailPage> {
  int _currentImageIndex = 0;
  String? _selectedColor;
  double _quantity = 1.0;
  bool _isAddingToCart = false;
  bool _isFavorite = false;

  final _supabase = Supabase.instance.client;
  late final String _orderId =
      'MKT_${widget.fabricId}_${DateTime.now().millisecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    try {
      final result = await _supabase
          .from('favorites')
          .select('is_favorite')
          .eq('user_id', user.id)
          .eq('fabric_id', widget.fabricId)
          .maybeSingle();
      if (mounted && result != null) {
        setState(() => _isFavorite = result['is_favorite'] == true);
      }
    } catch (e) {
      debugPrint('[FABRIC_DETAIL] Error loading favorite status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Try direct lookup first, fall back to catalog stream
    final fabricAsync = ref.watch(fabricByIdProvider(widget.fabricId));

    final bool isMobile = !ref.watch(isDesktopProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: shellAppBar(
        context,
        title: 'FABRIC DETAILS',
        actions: [
          IconButton(
            icon: Icon(
              Icons.chat_bubble_outline_rounded,
              color: colors.textPrimary,
            ),
            onPressed: () => fabricAsync.whenData((f) => _initChat(f.sellerId)),
          ),
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : colors.textPrimary,
            ),
            onPressed: () => _toggleFavorite(),
          ),
          IconButton(
            icon: Icon(Icons.share_rounded, color: colors.textPrimary),
            onPressed: _shareFabric,
          ),
        ],
      ),
      body: fabricAsync.when(
        data: (fabric) => _buildContent(fabric, isMobile),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.amber),
        ),
        error: (error, stack) {
          final colors = context.colors;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'FABRIC NOT FOUND',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This listing may have been removed.',
                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    final nav = ref.read(navigationStackProvider.notifier);
                    if (nav.canPop) {
                      nav.pop();
                    } else {
                      nav.set('/main');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    foregroundColor: AppColors.darkNavy,
                  ),
                  child: const Text('GO BACK'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(Fabric fabric, bool isMobile) {
    if (isMobile) {
      return _buildMobileLayout(fabric);
    } else {
      return _buildDesktopLayout(fabric);
    }
  }

  Widget _buildMobileLayout(Fabric fabric) {
    final colors = context.colors;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image gallery
          _buildImageGallery(fabric),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.amber,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    fabric.category,
                    style: TextStyle(
                      color: colors.textOnAmber,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  fabric.name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // Price
                Text(
                  '\u20A6${fabric.pricePerYard.toStringAsFixed(0)}/yard',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.amber,
                  ),
                ),
                const SizedBox(height: 20),

                // Origin and stock
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: colors.iconMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      fabric.origin ?? 'Global',
                      style: TextStyle(color: colors.textMuted, fontSize: 13),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 16,
                      color: colors.iconMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${fabric.stockQuantity.toInt()} yards available',
                      style: TextStyle(color: colors.textMuted, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Color selector
                if (fabric.availableColors.isNotEmpty) ...[
                  Text(
                    'SELECT COLOR',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: colors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildColorSelector(fabric.availableColors),
                  const SizedBox(height: 24),
                ],

                // Quantity selector
                _buildQuantitySelector(),
                const SizedBox(height: 24),

                // Add to cart button
                _buildAddToCartButton(fabric),
                const SizedBox(height: 32),

                // Product narrative
                if (fabric.composition != null || fabric.weight != null)
                  ProductNarrative(
                    fabricName: fabric.name,
                    composition: fabric.composition,
                    weight: fabric.weight,
                  ),
                const SizedBox(height: 24),

                // Specifications
                SpecificationTable(fabric: fabric),
                const SizedBox(height: 24),

                // Seller trust card
                SellerTrustCard(sellerId: fabric.sellerId),
                const SizedBox(height: 32),

                // ZONE C: TRUST & ACTION ZONE (ESCORW GUARANTEE)
                TrustActionFooter(
                  amount: fabric.pricePerYard * _quantity,
                  orderId: _orderId,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(Fabric fabric) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side - Images (50%)
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                // Main image
                Container(
                  height: 400,
                  decoration: BoxDecoration(
                    color: colors.surfaceHover,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: fabric.imageUrls.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: AppNetworkImage(
                            url:
                                fabric.imageUrls[_currentImageIndex.clamp(
                                  0,
                                  fabric.imageUrls.length - 1,
                                )],
                            fit: BoxFit.contain,
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.texture_rounded,
                            size: 80,
                            color: colors.iconMuted,
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                // Thumbnail strip
                if (fabric.imageUrls.length > 1)
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: fabric.imageUrls.length,
                      itemBuilder: (context, index) {
                        final isSelected = index == _currentImageIndex;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _currentImageIndex = index),
                          child: Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.amber
                                    : Colors.transparent,
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: AppNetworkImage(
                                url: fabric.imageUrls[index],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Right side - Details (50%)
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.amber,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    fabric.category,
                    style: TextStyle(
                      color: colors.textOnAmber,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  fabric.name,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // Price
                Text(
                  '\u20A6${fabric.pricePerYard.toStringAsFixed(0)}/yard',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.amber,
                  ),
                ),
                const SizedBox(height: 20),

                // Origin and stock
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: colors.iconMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      fabric.origin ?? 'Global',
                      style: TextStyle(color: colors.textMuted, fontSize: 13),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 16,
                      color: colors.iconMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${fabric.stockQuantity.toInt()} yards available',
                      style: TextStyle(color: colors.textMuted, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Color selector
                if (fabric.availableColors.isNotEmpty) ...[
                  Text(
                    'SELECT COLOR',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: colors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildColorSelector(fabric.availableColors),
                  const SizedBox(height: 32),
                ],

                // Quantity selector
                _buildQuantitySelector(),
                const SizedBox(height: 32),

                // Total price
                Text(
                  'Total: \u20A6${(fabric.pricePerYard * _quantity).toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // Add to cart button
                _buildAddToCartButton(fabric),
                const SizedBox(height: 40),

                // Divider
                const Divider(),
                const SizedBox(height: 24),

                // Product narrative
                if (fabric.composition != null || fabric.weight != null)
                  ProductNarrative(
                    fabricName: fabric.name,
                    composition: fabric.composition,
                    weight: fabric.weight,
                  ),
                const SizedBox(height: 24),

                // Specifications
                SpecificationTable(fabric: fabric),
                const SizedBox(height: 24),

                // Seller trust card
                SellerTrustCard(sellerId: fabric.sellerId),
                const SizedBox(height: 32),

                // ZONE C: TRUST & ACTION ZONE
                TrustActionFooter(
                  amount: fabric.pricePerYard * _quantity,
                  orderId: _orderId,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageGallery(Fabric fabric) {
    final colors = context.colors;
    return Container(
      height: 350,
      color: colors.surfaceHover,
      child: fabric.imageUrls.isNotEmpty
          ? AppNetworkImage(
              url:
                  fabric.imageUrls[_currentImageIndex.clamp(
                    0,
                    fabric.imageUrls.length - 1,
                  )],
              fit: BoxFit.contain,
            )
          : Center(
              child: Icon(
                Icons.texture_rounded,
                size: 80,
                color: colors.iconMuted,
              ),
            ),
    );
  }

  Widget _buildColorSelector(List<String> colorList) {
    final colors = context.colors;
    return Wrap(
      spacing: 12,
      children: colorList.map((colorName) {
        final isSelected = _selectedColor == colorName;
        return GestureDetector(
          onTap: () => setState(() => _selectedColor = colorName),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.amber : colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.amber : colors.borderDefault,
              ),
            ),
            child: Text(
              colorName,
              style: TextStyle(
                color: isSelected ? colors.textOnAmber : colors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuantitySelector() {
    final colors = context.colors;
    return Row(
      children: [
        Text(
          'QUANTITY',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: colors.textMuted,
          ),
        ),
        const SizedBox(width: 20),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: colors.borderDefault),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove, size: 18),
                onPressed: _quantity > 1
                    ? () => setState(() => _quantity--)
                    : null,
              ),
              Container(
                width: 60,
                alignment: Alignment.center,
                child: Text(
                  _quantity.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 18),
                onPressed: () => setState(() => _quantity++),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text('yards', style: TextStyle(color: colors.textMuted, fontSize: 14)),
      ],
    );
  }

  Widget _buildAddToCartButton(Fabric fabric) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isAddingToCart ? null : () => _addToCart(fabric),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.amber,
          foregroundColor: AppColors.darkNavy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isAddingToCart
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.colors.textOnAmber,
                ),
              )
            : const Text(
                'ADD TO CART',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 1.5,
                ),
              ),
      ),
    );
  }

  Future<void> _addToCart(Fabric fabric) async {
    setState(() => _isAddingToCart = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login to add to cart'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final newItem = {
        'fabricId': fabric.id,
        'fabricName': fabric.name,
        'sellerId': fabric.sellerId,
        'quantity': _quantity,
        'pricePerYard': fabric.pricePerYard,
        'selectedColor': _selectedColor,
        'totalPrice': fabric.pricePerYard * _quantity,
        'addedAt': DateTime.now().toIso8601String(),
      };

      // Read the existing cart first so we append instead of overwriting it
      final existing = await _supabase
          .from('carts')
          .select('items')
          .eq('user_id', user.id)
          .maybeSingle();

      final existingItems = (existing?['items'] as List<dynamic>? ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map<String, dynamic>))
          .toList();

      // Deduplicate: remove any existing entry for this fabric+color combo
      existingItems.removeWhere(
        (e) =>
            e['fabricId'] == fabric.id && e['selectedColor'] == _selectedColor,
      );
      existingItems.add(newItem);

      await _supabase.from('carts').upsert({
        'user_id': user.id,
        'items': existingItems,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added $_quantity yards of ${fabric.name} to cart'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add to cart. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAddingToCart = false);
    }
  }

  void _toggleFavorite() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to save favorites'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final newFavorite = !_isFavorite;
    setState(() => _isFavorite = newFavorite);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newFavorite ? 'Added to favorites' : 'Removed from favorites',
        ),
        duration: const Duration(seconds: 1),
      ),
    );

    try {
      await _supabase.from('favorites').upsert({
        'user_id': user.id,
        'fabric_id': widget.fabricId,
        'is_favorite': newFavorite,
      });
    } catch (e) {
      debugPrint('[FabricDetail] favorite upsert failed: $e');
      if (mounted) {
        // Revert optimistic UI on failure
        setState(() => _isFavorite = !newFavorite);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not update favorites. Try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareFabric() {
    final shareUrl =
        '${AppConfig.websiteUrl}/fabric-details?fabricId=${widget.fabricId}';
    Clipboard.setData(ClipboardData(text: shareUrl));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Marketplace listing link copied to clipboard.'),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  Future<void> _initChat(String sellerId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('LOGIN REQUIRED FOR MESSAGING')),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Connecting to Secure Merchant Channel...')),
    );

    final result = await ref.read(chatRepositoryProvider).createConversation([
      user.id,
      sellerId,
    ]);

    result.fold(
      (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Connection Failed: $failure'))),
      (conversation) {
        ref.pushShell('/chat-detail', {
          'conversationId': conversation.id,
          'peerId': sellerId,
        });
      },
    );
  }
}
