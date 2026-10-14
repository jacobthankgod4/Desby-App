import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../theme/colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../providers/shop_provider.dart';
import '../../domain/entities/shop_product.dart';
import '../../../../core/widgets/shell_app_bar.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/price_text_field.dart';

class AddProductPage extends ConsumerStatefulWidget {
  const AddProductPage({super.key});

  @override
  ConsumerState<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends ConsumerState<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _fabricController = TextEditingController();
  final _nameFocus = FocusNode();
  final _priceFocus = FocusNode();

  final List<XFile> _newImages = [];
  final List<String> _existingImageUrls = [];
  final List<String> _selectedSizes = [];
  final List<String> _selectedFabrics = [];
  String _selectedCategory = ShopCategory.custom;
  bool _isVisible = true;
  bool _isSaving = false;
  bool _isInitialized = false;

  ShopProduct? _editingProduct;
  String _productId = '';

  static const List<String> _sizes = [
    'XS',
    'S',
    'M',
    'L',
    'XL',
    'XXL',
    'XXXL',
    'Custom',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFromArguments();
    });
  }

  void _initializeFromArguments() {
    if (_isInitialized) return;
    _isInitialized = true;

    _productId = const Uuid().v4();

    final navState = ref.read(navigationProvider);
    final product = navState.arguments?['product'] as ShopProduct?;

    if (product != null) {
      _editingProduct = product;
      _productId = product.id;
      _nameController.text = product.name;
      _descriptionController.text = product.description;
      _priceController.text = product.price > 0
          ? formatPriceDigits(product.price.toInt().toString())
          : '';
      _selectedCategory = product.category;
      _selectedSizes.addAll(product.availableSizes);
      _selectedFabrics.addAll(product.availableFabrics);
      _existingImageUrls.addAll(product.imageUrls);
      _isVisible = product.isVisible;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _fabricController.dispose();
    _nameFocus.dispose();
    _priceFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _editingProduct != null;

    return Scaffold(
      backgroundColor: context.colors.scaffoldBg,
      appBar: shellAppBar(
        context,
        title: isEditing ? 'EDIT PRODUCT' : 'ADD PRODUCT',
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSection(),
              const SizedBox(height: 32),

              const Text(
                'PRODUCT DETAILS',
                style: TextStyle(
                  color: AppColors.amber,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'PRODUCT NAME',
                controller: _nameController,
                focusNode: _nameFocus,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'DESCRIPTION',
                controller: _descriptionController,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'PRICE (\u20A6)',
                controller: _priceController,
                focusNode: _priceFocus,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Price is required';
                  final price = double.tryParse(
                    v.replaceAll(RegExp(r'[^0-9.]'), ''),
                  );
                  if (price == null || price <= 0) return 'Enter a valid price';
                  return null;
                },
                inputFormatters: priceInputFormatters,
              ),
              const SizedBox(height: 24),

              _buildCategorySection(),
              const SizedBox(height: 24),

              _buildSizesSection(),
              const SizedBox(height: 24),

              _buildFabricsSection(),
              const SizedBox(height: 24),

              _buildVisibilityToggle(),
              const SizedBox(height: 40),

              CustomButton(
                text: isEditing ? 'UPDATE PRODUCT' : 'SAVE PRODUCT',
                onPressed: _isSaving ? null : _saveProduct,
                isLoading: _isSaving,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    FocusNode? focusNode,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: context.colors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          style: TextStyle(color: context.colors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: context.colors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.colors.borderDefault),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.colors.borderDefault),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.amber, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.colors.statusError),
            ),
            errorStyle: TextStyle(
              color: context.colors.statusError,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PRODUCT IMAGES (${_existingImageUrls.length + _newImages.length}/5)',
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            if (_existingImageUrls.length + _newImages.length < 5)
              TextButton.icon(
                onPressed: _addImages,
                icon: const Icon(
                  Icons.add_a_photo_outlined,
                  size: 18,
                  color: AppColors.amber,
                ),
                label: const Text(
                  'ADD',
                  style: TextStyle(
                    color: AppColors.amber,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_existingImageUrls.isEmpty && _newImages.isEmpty)
          GestureDetector(
            onTap: _addImages,
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: context.colors.borderDefault),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 40,
                    color: context.colors.borderSubtle,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'SELECT PRODUCT IMAGES',
                    style: TextStyle(
                      color: context.colors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: _existingImageUrls.length + _newImages.length,
            itemBuilder: (context, index) {
              if (index < _existingImageUrls.length) {
                return _buildExistingImage(index);
              }
              return _buildNewImage(index - _existingImageUrls.length);
            },
          ),
      ],
    );
  }

  Widget _buildExistingImage(int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AppNetworkImage(
            url: _existingImageUrls[index],
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        Positioned(
          right: 4,
          top: 4,
          child: GestureDetector(
            onTap: () => setState(() => _existingImageUrls.removeAt(index)),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: context.colors.textMuted,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 14,
                color: context.colors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewImage(int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: FutureBuilder<Uint8List>(
            future: _newImages[index].readAsBytes(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Image.memory(
                  snapshot.data!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                );
              }
              return Container(color: context.colors.surface);
            },
          ),
        ),
        Positioned(
          right: 4,
          top: 4,
          child: GestureDetector(
            onTap: () => setState(() => _newImages.removeAt(index)),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: context.colors.textMuted,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 14,
                color: context.colors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CATEGORY',
          style: TextStyle(
            color: context.colors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ShopCategory.all.map((cat) {
            final isSelected = _selectedCategory == cat;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.amber : context.colors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected
                      ? null
                      : Border.all(color: context.colors.borderSubtle),
                ),
                child: Text(
                  cat.toUpperCase(),
                  style: TextStyle(
                    color: isSelected
                        ? context.colors.scaffoldBg
                        : context.colors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSizesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AVAILABLE SIZES',
          style: TextStyle(
            color: context.colors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _sizes.map((size) {
            final isSelected = _selectedSizes.contains(size);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedSizes.remove(size);
                  } else {
                    _selectedSizes.add(size);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.amber : context.colors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected
                      ? null
                      : Border.all(color: context.colors.borderSubtle),
                ),
                child: Text(
                  size,
                  style: TextStyle(
                    color: isSelected
                        ? context.colors.scaffoldBg
                        : context.colors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFabricsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AVAILABLE FABRICS',
          style: TextStyle(
            color: context.colors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _fabricController,
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 13,
                ),
                textCapitalization: TextCapitalization.words,
                onSubmitted: (_) => _addFabric(),
                decoration: InputDecoration(
                  hintText: 'e.g. Cotton, Silk, Ankara...',
                  hintStyle: TextStyle(
                    color: context.colors.textMuted,
                    fontSize: 12,
                  ),
                  filled: true,
                  fillColor: context.colors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.colors.borderDefault),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.colors.borderDefault),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.amber,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _showFabricPicker,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.amber,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: context.colors.scaffoldBg,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
        if (_selectedFabrics.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedFabrics.map((fabric) {
              return Chip(
                label: Text(
                  fabric.toUpperCase(),
                  style: TextStyle(
                    color: context.colors.scaffoldBg,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                backgroundColor: AppColors.amber,
                deleteIcon: Icon(
                  Icons.close,
                  size: 16,
                  color: context.colors.scaffoldBg,
                ),
                onDeleted: () {
                  setState(() => _selectedFabrics.remove(fabric));
                },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildVisibilityToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.borderDefault),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VISIBILITY',
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isVisible ? 'Visible to clients' : 'Hidden from clients',
                style: TextStyle(color: context.colors.textMuted, fontSize: 11),
              ),
            ],
          ),
          Switch.adaptive(
            value: _isVisible,
            onChanged: (val) => setState(() => _isVisible = val),
            activeThumbColor: AppColors.amber,
            activeTrackColor: AppColors.amber.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  void _addImages() async {
    final remaining = 5 - _existingImageUrls.length - _newImages.length;
    if (remaining <= 0) return;

    final images = await ImagePicker().pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (images.isNotEmpty) {
      final toAdd = images.take(remaining).toList();
      setState(() => _newImages.addAll(toAdd));
    }
  }

  void _showFabricPicker() {
    final user = ref.read(currentUserProvider);
    if (user == null || user.id.isEmpty) return;

    final profileAsync = ref.read(userProfileProvider(user.id));
    final profile = profileAsync.valueOrNull;
    final availableFabrics = profile?.availableFabrics ?? [];

    if (availableFabrics.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'No fabrics added yet. Add fabrics in your profile.',
          ),
          backgroundColor: context.colors.statusError,
        ),
      );
      return;
    }

    final tempSelected = Set<String>.from(_selectedFabrics);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.3,
              maxChildSize: 0.85,
              expand: false,
              builder: (ctx, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: context.colors.surfaceElevated,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'SELECT FABRICS',
                              style: TextStyle(
                                color: AppColors.amber,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedFabrics.clear();
                                  _selectedFabrics.addAll(
                                    tempSelected.where(
                                      (f) => !_selectedFabrics.any(
                                        (s) =>
                                            s.toLowerCase() == f.toLowerCase(),
                                      ),
                                    ),
                                  );
                                });
                                Navigator.pop(ctx);
                              },
                              child: const Text('DONE'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView(
                            controller: scrollController,
                            children: availableFabrics.map((fabric) {
                              final isSelected = tempSelected.any(
                                (f) => f.toLowerCase() == fabric.toLowerCase(),
                              );
                              return ListTile(
                                onTap: () {
                                  setSheetState(() {
                                    if (isSelected) {
                                      tempSelected.removeWhere(
                                        (f) =>
                                            f.toLowerCase() ==
                                            fabric.toLowerCase(),
                                      );
                                    } else {
                                      tempSelected.add(fabric);
                                    }
                                  });
                                },
                                title: Text(
                                  fabric.toUpperCase(),
                                  style: TextStyle(
                                    color: context.colors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                trailing: Icon(
                                  isSelected
                                      ? Icons.check_circle_rounded
                                      : Icons.circle_outlined,
                                  color: isSelected
                                      ? AppColors.amber
                                      : context.colors.textMuted,
                                  size: 22,
                                ),
                              );
                            }).toList(),
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
      },
    );
  }

  void _addFabric() {
    final name = _fabricController.text.trim();
    if (name.isEmpty) return;
    if (_selectedFabrics.contains(name)) {
      _fabricController.clear();
      return;
    }
    setState(() {
      _selectedFabrics.add(name);
      _fabricController.clear();
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    if (user == null || user.id.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Session expired. Please sign in again.'),
            backgroundColor: context.colors.statusError,
          ),
        );
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 1. Upload new images
      final imageUrls = List<String>.from(_existingImageUrls);
      for (final file in _newImages) {
        final bytes = await file.readAsBytes();
        final ext = file.name.split('.').last;
        final path =
            'products/${user.id}/$_productId/${const Uuid().v4()}.$ext';
        await Supabase.instance.client.storage
            .from('images')
            .uploadBinary(
              path,
              bytes,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            );
        final url = Supabase.instance.client.storage
            .from('images')
            .getPublicUrl(path);
        imageUrls.add(url);
      }

      // 2. Build product
      final price =
          double.tryParse(
            _priceController.text.replaceAll(RegExp(r'[^0-9.]'), ''),
          ) ??
          0.0;

      final product = ShopProduct(
        id: _productId,
        tailorId: user.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: price,
        imageUrls: imageUrls,
        category: _selectedCategory,
        availableFabrics: _selectedFabrics,
        availableSizes: _selectedSizes,
        isVisible: _isVisible,
        createdAt: _editingProduct?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 3. Save
      final shopNotifier = ref.read(shopNotifierProvider.notifier);
      final success = _editingProduct != null
          ? await shopNotifier.updateProduct(product)
          : await shopNotifier.addProduct(product);

      if (!mounted) return;

      if (success) {
        ref.invalidate(shopNotifierProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _editingProduct != null
                  ? 'Product updated successfully'
                  : 'Product added successfully',
            ),
            backgroundColor: AppColors.successGreen,
          ),
        );
        if (ref.canPopShell) {
          ref.popShell();
        } else {
          ref.setShell('/product-list');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save product. Please try again.'),
            backgroundColor: context.colors.statusError,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: context.colors.statusError,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
