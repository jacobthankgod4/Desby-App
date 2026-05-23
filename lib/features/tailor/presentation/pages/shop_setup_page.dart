import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../theme/colors.dart';
import '../../../../core/services/image_upload_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/shop_product.dart';

class ShopSetupPage extends ConsumerStatefulWidget {
  const ShopSetupPage({super.key});

  @override
  ConsumerState<ShopSetupPage> createState() => _ShopSetupPageState();
}

class _ShopSetupPageState extends ConsumerState<ShopSetupPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImageUploadService _imageService = ImageUploadService();
  
  List<ShopProduct> _products = [];
  bool _isLoading = true;
  bool _isUploading = false;
  bool _shopVisible = true;
  
  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  String _selectedCategory = ShopCategory.custom;
  
  // Image handling
  final List<XFile> _selectedImages = [];
  List<String> _existingImageUrls = [];
  
  // Edit mode
  bool _isEditMode = false;
  String? _editingProductId;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final currentUser = ref.read(currentUserProvider);
    final tailorId = currentUser?.id ?? '';
    
    if (tailorId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final snapshot = await _firestore
          .collection('shops')
          .doc(tailorId)
          .collection('products')
          .orderBy('sortOrder', descending: false)
          .get();

      if (mounted) {
        setState(() {
          _products = snapshot.docs
              .map((doc) => ShopProduct.fromMap(doc.data()))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImages(ImageSource source) async {
    XFile? image;
    if (source == ImageSource.gallery) {
      image = await _imageService.pickImageFromGallery();
    } else if (source == ImageSource.camera) {
      image = await _imageService.pickImageFromCamera();
    }
    
    if (image != null && mounted) {
      setState(() => _selectedImages.add(image!));
    }
  }

  void _showEditProductDialog(ShopProduct product) {
    setState(() {
      _isEditMode = true;
      _editingProductId = product.id;
      _nameController.text = product.name;
      _descriptionController.text = product.description;
      _priceController.text = product.price.toString();
      _selectedCategory = product.category;
      _existingImageUrls = List.from(product.imageUrls);
      _selectedImages.clear();
    });
  }

  void _resetForm() {
    setState(() {
      _isEditMode = false;
      _editingProductId = null;
      _nameController.clear();
      _descriptionController.clear();
      _priceController.clear();
      _selectedCategory = ShopCategory.custom;
      _selectedImages.clear();
      _existingImageUrls.clear();
    });
  }

  Future<void> _saveProduct() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and Price are required.'), backgroundColor: Colors.orangeAccent),
      );
      return;
    }

    final currentUser = ref.read(currentUserProvider);
    final tailorId = currentUser?.id ?? '';
    if (tailorId.isEmpty) return;

    setState(() => _isUploading = true);

    try {
      final productId = _editingProductId ?? 'PRD_${DateTime.now().millisecondsSinceEpoch}';
      
      // Upload new images
      List<String> newImageUrls = [];
      if (_selectedImages.isNotEmpty) {
        newImageUrls = await _imageService.uploadImages(_selectedImages, tailorId, 'products');
      }

      final allImageUrls = [..._existingImageUrls, ...newImageUrls];

      final productData = {
        'id': productId,
        'tailorId': tailorId,
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'category': _selectedCategory,
        'imageUrls': allImageUrls,
        'isVisible': true,
        'isAvailable': true,
        'sortOrder': _isEditMode ? _products.indexWhere((p) => p.id == productId) : _products.length,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      };

      await _firestore
          .collection('shops')
          .doc(tailorId)
          .collection('products')
          .doc(productId)
          .set(productData);

      _resetForm();
      await _loadProducts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'DESIGN MODIFIED' : 'DESIGN UPLOADED'),
            backgroundColor: Colors.greenAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteProduct(ShopProduct product) async {
    try {
      final currentUser = ref.read(currentUserProvider);
      final tailorId = currentUser?.id ?? '';
      
      if (tailorId.isNotEmpty) {
        if (product.imageUrls.isNotEmpty) {
          await _imageService.deleteImages(product.imageUrls);
        }
        
        await _firestore
            .collection('shops')
            .doc(tailorId)
            .collection('products')
            .doc(product.id)
            .delete();
      }

      await _loadProducts();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('DESIGN REMOVED')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
    }
  }

  void _reorderProducts(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _products.removeAt(oldIndex);
      _products.insert(newIndex, item);
    });
    _saveProductOrder();
  }

  Future<void> _saveProductOrder() async {
    final currentUser = ref.read(currentUserProvider);
    final tailorId = currentUser?.id ?? '';
    if (tailorId.isEmpty) return;

    for (int i = 0; i < _products.length; i++) {
      _firestore
          .collection('shops')
          .doc(tailorId)
          .collection('products')
          .doc(_products[i].id)
          .update({'sortOrder': i});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      appBar: AppBar(
        title: const Text('DESIGNER SHOP SETUP',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.amber, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isEditMode) IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white38), onPressed: _resetForm),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.amber))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildShopHeader(),
                  const SizedBox(height: 40),
                  _buildProductForm(),
                  const SizedBox(height: 40),
                  _buildSectionHeader('SHOP CATALOG (${_products.length})'),
                  _buildReorderableProductList(),
                  const SizedBox(height: 60),
                ],
              ),
            ),
    );
  }

  Widget _buildShopHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(color: AppColors.amber, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.storefront_rounded, color: AppColors.darkNavy, size: 30),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MY TAILOR SHOP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 4),
                Text('${_products.length} Items Live', style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          Switch.adaptive(
            value: _shopVisible,
            activeTrackColor: AppColors.amber,
            onChanged: (v) => setState(() => _shopVisible = v),
          ),
        ],
      ),
    );
  }

  Widget _buildProductForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_isEditMode ? 'EDIT DESIGN' : 'ADD NEW DESIGN', 
            style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11)),
          const SizedBox(height: 20),
          
          _buildImageUploadSection(),
          const SizedBox(height: 20),
          
          _buildField('PRODUCT NAME *', _nameController),
          const SizedBox(height: 16),
          _buildField('PRICE (NGN) *', _priceController, isNumber: true),
          const SizedBox(height: 16),
          _buildField('DESIGN NARRATIVE (DESCRIPTION)', _descriptionController, maxLines: 3),
          const SizedBox(height: 20),
          _buildCategorySelector(),
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _isUploading ? null : _saveProduct,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber, foregroundColor: AppColors.darkNavy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: _isUploading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.darkNavy))
                : Text(_isEditMode ? 'SAVE MODIFICATIONS' : 'UPLOAD TO SHOP', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('MEDIA ASSETS', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildAddImageButton(),
              ..._selectedImages.map((file) => _buildLocalImageThumbnail(file)),
              ..._existingImageUrls.map((url) => _buildNetworkImageThumbnail(url)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddImageButton() {
    return InkWell(
      onTap: () => _showImageSourceDialog(),
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
        child: const Icon(Icons.add_a_photo_rounded, color: AppColors.amber, size: 28),
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkNavy,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSourceOption(Icons.camera_alt_rounded, 'CAMERA', () => _pickImages(ImageSource.camera)),
            _buildSourceOption(Icons.photo_library_rounded, 'GALLERY', () => _pickImages(ImageSource.gallery)),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: () { Navigator.pop(context); onTap(); },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle), child: Icon(icon, color: AppColors.amber, size: 28)),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildLocalImageThumbnail(XFile xFile) {
    return Container(
      width: 100, margin: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16), 
              child: FutureBuilder<Uint8List>(
                future: xFile.readAsBytes(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) return Image.memory(snapshot.data!, fit: BoxFit.cover);
                  return Container(color: Colors.black26);
                }
              ),
            ),
          ),
          Positioned(top: 4, right: 4, child: InkWell(onTap: () => setState(() => _selectedImages.remove(xFile)), child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 12)))),
          Positioned(top: 4, left: 4, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.amber, borderRadius: BorderRadius.circular(4)), child: const Text('NEW', style: TextStyle(color: AppColors.darkNavy, fontSize: 7, fontWeight: FontWeight.w900)))),
        ],
      ),
    );
  }

  Widget _buildNetworkImageThumbnail(String url) {
    return Container(
      width: 100, margin: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(url, fit: BoxFit.cover))),
          Positioned(top: 4, right: 4, child: InkWell(onTap: () => setState(() => _existingImageUrls.remove(url)), child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle), child: const Icon(Icons.delete_rounded, color: Colors.white, size: 12)))),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {bool isNumber = false, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.multiline,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.amber)),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('DESIGN CATEGORY', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: ShopCategory.all.map((cat) {
              final isSel = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: InkWell(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.amber : Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSel ? AppColors.amber : Colors.white10),
                    ),
                    child: Text(cat.toUpperCase(), style: TextStyle(color: isSel ? AppColors.darkNavy : Colors.white60, fontSize: 10, fontWeight: FontWeight.w900)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 20),
      child: Text(title, style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)),
    );
  }

  Widget _buildReorderableProductList() {
    if (_products.isEmpty) return const Center(child: Text('SHOP EMPTY', style: TextStyle(color: Colors.white12, fontWeight: FontWeight.w900, fontSize: 24)));

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _products.length,
      onReorder: _reorderProducts,
      itemBuilder: (context, index) {
        final p = _products[index];
        return Container(
          key: ValueKey(p.id),
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              const Icon(Icons.drag_indicator_rounded, color: Colors.white12, size: 20),
              const SizedBox(width: 12),
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(14)),
                child: p.imageUrls.isNotEmpty 
                  ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(p.imageUrls.first, fit: BoxFit.cover))
                  : const Icon(Icons.checkroom_rounded, color: AppColors.amber),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
                    Text('₦${p.price.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.w900, fontSize: 16)),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.edit_note_rounded, color: Colors.white38), onPressed: () => _showEditProductDialog(p)),
              IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20), onPressed: () => _confirmDelete(p)),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(ShopProduct product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('DELETE DESIGN?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
        content: const Text('This action will permanently remove this design from your tailor shop.', style: TextStyle(color: Colors.white38, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.white60))),
          ElevatedButton(
            onPressed: () {
              _deleteProduct(product);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('DELETE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
