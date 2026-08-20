import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../theme/colors.dart';
import '../../domain/entities/fabric.dart';
import '../providers/fabric_provider.dart';
import '../widgets/specification_table.dart';
import '../widgets/product_narrative.dart';
import '../widgets/seller_trust_card.dart';
import '../widgets/trust_action_footer.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../chat/presentation/providers/chat_provider.dart';

/// FabricDetailPage - Shows detailed view of a fabric with images, specs, and purchase options
class FabricDetailPage extends ConsumerStatefulWidget {
  final String fabricId;
  
  const FabricDetailPage({
    super.key,
    required this.fabricId,
  });

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

  @override
  Widget build(BuildContext context) {
    // Try direct lookup first, fall back to catalog stream
    final fabricAsync = ref.watch(fabricByIdProvider(widget.fabricId));
    
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.darkNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/main');
            }
          },
        ),
        title: const Text(
          'FABRIC DETAILS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
            onPressed: () => fabricAsync.whenData((f) => _initChat(f.sellerId)),
          ),
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : Colors.white,
            ),
            onPressed: () => _toggleFavorite(),
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            onPressed: _shareFabric,
          ),
        ],
      ),
      body: fabricAsync.when(
        data: (fabric) => _buildContent(fabric, isMobile),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.amber),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
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
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  foregroundColor: AppColors.darkNavy,
                ),
                child: const Text('GO BACK'),
              ),
            ],
          ),
        ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.amber,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    fabric.category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Title
                Text(
                  fabric.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Price
                Text(
                  '₦${fabric.pricePerYard.toStringAsFixed(0)}/yard',
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
                    const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      fabric.origin ?? 'Global',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.inventory_2_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${fabric.stockQuantity.toInt()} yards available',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Color selector
                if (fabric.availableColors.isNotEmpty) ...[
                  const Text(
                    'SELECT COLOR',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: AppColors.textMuted,
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
                  orderId: 'MKT_${fabric.id.substring(0, 5)}_${DateTime.now().millisecondsSinceEpoch}',
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
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: fabric.imageUrls.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            fabric.imageUrls[_currentImageIndex],
                            fit: BoxFit.contain,
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.texture_rounded,
                            size: 80,
                            color: Colors.grey,
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
                          onTap: () => setState(() => _currentImageIndex = index),
                          child: Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected ? AppColors.amber : Colors.transparent,
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                fabric.imageUrls[index],
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.amber,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    fabric.category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Title
                Text(
                  fabric.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Price
                Text(
                  '₦${fabric.pricePerYard.toStringAsFixed(0)}/yard',
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
                    const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      fabric.origin ?? 'Global',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.inventory_2_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${fabric.stockQuantity.toInt()} yards available',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Color selector
                if (fabric.availableColors.isNotEmpty) ...[
                  const Text(
                    'SELECT COLOR',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: AppColors.textMuted,
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
                  'Total: ₦${(fabric.pricePerYard * _quantity).toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
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
                  orderId: 'MKT_${fabric.id.substring(0, 5)}_${DateTime.now().millisecondsSinceEpoch}',
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
    return Container(
      height: 350,
      color: Colors.grey.shade100,
      child: fabric.imageUrls.isNotEmpty
          ? Image.network(
              fabric.imageUrls[_currentImageIndex],
              fit: BoxFit.contain,
            )
          : const Center(
              child: Icon(
                Icons.texture_rounded,
                size: 80,
                color: Colors.grey,
              ),
            ),
    );
  }

  Widget _buildColorSelector(List<String> colors) {
    return Wrap(
      spacing: 12,
      children: colors.map((colorName) {
        final isSelected = _selectedColor == colorName;
        return GestureDetector(
          onTap: () => setState(() => _selectedColor = colorName),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.amber : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.amber : Colors.grey.shade300,
              ),
            ),
            child: Text(
              colorName,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
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
    return Row(
      children: [
        const Text(
          'QUANTITY',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(width: 20),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
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
        const Text(
          'yards',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
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
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.darkNavy,
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
      
      await _supabase.from('carts').upsert({
        'user_id': user.id,
        'items': [
           {
            'fabricId': fabric.id,
            'fabricName': fabric.name,
            'quantity': _quantity,
            'pricePerYard': fabric.pricePerYard,
            'selectedColor': _selectedColor,
            'totalPrice': fabric.pricePerYard * _quantity,
            'addedAt': DateTime.now().toIso8601String(),
          }
        ],
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

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    
    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to save favorites'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Simplified favorite logic for Supabase
    _supabase.from('favorites').upsert({
      'user_id': user.id,
      'fabric_id': widget.fabricId,
      'is_favorite': _isFavorite,
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFavorite ? 'Added to favorites' : 'Removed from favorites'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _shareFabric() {
    final shareUrl = 'https://desby.app/fabric-details?fabricId=${widget.fabricId}';
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('LOGIN REQUIRED FOR MESSAGING')));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connecting to Secure Merchant Channel...')));
    
    final result = await ref.read(chatRepositoryProvider).createConversation([user.id, sellerId]);
    
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Connection Failed: $failure'))),
      (conversation) {
        ref.pushShell('/chat-detail', {
          'conversationId': conversation.id,
          'peerId': sellerId,
        });
      },
    );
  }
}
