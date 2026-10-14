import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../theme/colors.dart';
import '../../../../core/services/image_upload_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/constants/fabric_constants.dart';
import '../../domain/entities/fabric.dart';
import '../providers/fabric_provider.dart';
import '../../../../core/widgets/shell_app_bar.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/price_text_field.dart';

class FabricUploadPage extends ConsumerStatefulWidget {
  final Fabric? fabric; // Pass this for Edit Mode
  const FabricUploadPage({super.key, this.fabric});

  @override
  ConsumerState<FabricUploadPage> createState() => _FabricUploadPageState();
}

class _FabricUploadPageState extends ConsumerState<FabricUploadPage> {
  final _imageService = ImageUploadService();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _compositionController = TextEditingController();
  final _weightController = TextEditingController();
  final _originController = TextEditingController();

  String _category = 'Cotton';
  final List<XFile> _selectedImages = [];
  final List<String> _existingImageUrls = [];
  bool _isUploading = false;
  final Map<String, Uint8List> _imageBytesCache = {};

  // Variants & Tiers State
  final List<FabricVariant> _variants = [];
  final List<WholesaleTier> _tiers = [];

  @override
  void initState() {
    super.initState();
    if (widget.fabric != null) {
      _nameController.text = widget.fabric!.name;
      _priceController.text = widget.fabric!.pricePerYard.toString();
      _stockController.text = widget.fabric!.stockQuantity.toString();
      _compositionController.text = widget.fabric!.composition ?? '';
      _weightController.text = widget.fabric!.weight ?? '';
      _originController.text = widget.fabric!.origin ?? '';
      _category = widget.fabric!.category;
      _existingImageUrls.addAll(widget.fabric!.imageUrls);
      _variants.addAll(widget.fabric!.variants);
      _tiers.addAll(widget.fabric!.wholesaleTiers);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _compositionController.dispose();
    _weightController.dispose();
    _originController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final images = await _imageService.pickMultipleImages();
    if (images.isNotEmpty) {
      setState(() => _selectedImages.addAll(images));
    }
  }

  Future<void> _publish() async {
    if (_nameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        (_selectedImages.isEmpty && _existingImageUrls.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name, Price, and at least one image are mandatory.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final user = ref.read(currentUserProvider);
      if (user == null) {
        if (mounted) {
          setState(() => _isUploading = false);
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Please sign in to upload fabrics'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      // Validate required fields
      if (_nameController.text.trim().isEmpty ||
          _priceController.text.isEmpty ||
          _stockController.text.isEmpty) {
        setState(() => _isUploading = false);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Please fill in name, price, and stock'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final price =
          double.tryParse(priceToDigits(_priceController.text)) ?? 0.0;
      final stock = double.tryParse(_stockController.text) ?? 0.0;
      if (price <= 0) {
        setState(() => _isUploading = false);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Price must be greater than zero'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final fabricId =
          widget.fabric?.id ?? 'FAB_${DateTime.now().millisecondsSinceEpoch}';

      // 1. Upload New Images
      final newImageUrls = await _imageService.uploadImages(
        _selectedImages,
        user.id,
        'fabrics',
      );
      final totalImageUrls = [..._existingImageUrls, ...newImageUrls];

      // 2. Create Fabric Entity
      final fabric = Fabric(
        id: fabricId,
        name: _nameController.text.trim(),
        category: _category,
        pricePerYard: price,
        stockQuantity: stock,
        sellerId: user.id,
        imageUrls: totalImageUrls,
        composition: _compositionController.text.trim(),
        weight: _weightController.text.trim(),
        origin: _originController.text.trim(),
        availableColors: _variants.map((v) => v.colorName).toList(),
        variants: _variants,
        wholesaleTiers: _tiers,
        createdAt: widget.fabric?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 3. Save/Update
      final repository = ref.read(fabricRepositoryProvider);
      final result = widget.fabric == null
          ? await repository.uploadFabric(fabric)
          : await repository.updateFabric(fabric);

      result.fold(
        (failure) => messenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to save fabric. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        ),
        (_) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                widget.fabric == null ? 'FABRIC PUBLISHED!' : 'FABRIC UPDATED!',
              ),
              backgroundColor: Colors.greenAccent,
            ),
          );
          Navigator.maybePop(context);
        },
      );
    } on ImageUploadException catch (e) {
      debugPrint('Fabric image upload failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image upload failed — please try again'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: shellAppBar(
        context,
        title: widget.fabric == null ? 'MARKETPLACE UPLOAD' : 'EDIT MATERIAL',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(),
            const SizedBox(height: 32),
            _buildSectionTitle('MATERIAL ARCHITECTURE'),
            const SizedBox(height: 16),
            _buildField('FABRIC NAME *', _nameController),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    'PRICE PER YARD (NGN) *',
                    _priceController,
                    isPrice: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildField(
                    'INITIAL STOCK (YDS)',
                    _stockController,
                    isNumber: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCategoryDropdown(),
            const SizedBox(height: 32),

            _buildSectionTitle('VARIANTS & COLORS'),
            const SizedBox(height: 16),
            _buildVariantsSection(),
            const SizedBox(height: 32),

            _buildSectionTitle('WHOLESALE TIERS'),
            const SizedBox(height: 16),
            _buildTiersSection(),
            const SizedBox(height: 32),

            _buildSectionTitle('Additional Details'),
            const SizedBox(height: 16),
            _buildField(
              'COMPOSITION (e.g. 100% COTTON)',
              _compositionController,
            ),
            const SizedBox(height: 16),
            _buildField('WEIGHT (e.g. 250 GSM)', _weightController),
            const SizedBox(height: 16),
            _buildField('ORIGIN (e.g. MILAN, ITALY)', _originController),
            const SizedBox(height: 48),
            _buildPublishButton(),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppColors.amber,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildImageSection() {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DESIGN ASSETS',
          style: TextStyle(
            color: colors.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildAddImageButton(),
              ..._existingImageUrls.map(
                (url) => _buildExistingImageThumbnail(url),
              ),
              ..._selectedImages.map((file) => _buildImageThumbnail(file)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddImageButton() {
    final colors = context.colors;
    return InkWell(
      onTap: _pickImages,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: const Icon(
          Icons.add_a_photo_rounded,
          color: AppColors.amber,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildExistingImageThumbnail(String url) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: AppNetworkImage(url: url, fit: BoxFit.cover),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 16),
                onPressed: () => setState(() => _existingImageUrls.remove(url)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageThumbnail(XFile file) {
    // Load bytes once and cache
    if (!_imageBytesCache.containsKey(file.path)) {
      file.readAsBytes().then((bytes) {
        if (mounted) setState(() => _imageBytesCache[file.path] = bytes);
      });
    }
    final cachedBytes = _imageBytesCache[file.path];

    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: cachedBytes != null
                  ? Image.memory(cachedBytes, fit: BoxFit.cover)
                  : const Center(
                      child: CircularProgressIndicator(color: AppColors.amber),
                    ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 16),
                onPressed: () => setState(() {
                  _selectedImages.remove(file);
                  _imageBytesCache.remove(file.path);
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantsSection() {
    final colors = context.colors;
    return Column(
      children: [
        ..._variants.map(
          (v) => ListTile(
            title: Text(
              v.colorName,
              style: TextStyle(color: colors.textPrimary),
            ),
            subtitle: Text(
              '${v.stockQuantity} yds',
              style: TextStyle(color: colors.textMuted),
            ),
            trailing: const IconButton(
              icon: Icon(Icons.remove_circle_outline, color: Colors.redAccent),
              onPressed: null, // Handled by parent
            ),
          ),
        ),
        TextButton.icon(
          onPressed: _showAddVariantDialog,
          icon: const Icon(Icons.add, color: AppColors.amber),
          label: const Text(
            'ADD COLOR VARIANT',
            style: TextStyle(color: AppColors.amber),
          ),
        ),
      ],
    );
  }

  Widget _buildTiersSection() {
    final colors = context.colors;
    return Column(
      children: [
        ..._tiers.map(
          (t) => ListTile(
            title: Text(
              'Min ${t.minQuantity} yds',
              style: TextStyle(color: colors.textPrimary),
            ),
            subtitle: Text(
              '\u20A6${t.unitPrice}/yd',
              style: TextStyle(color: colors.textMuted),
            ),
            trailing: const IconButton(
              icon: Icon(Icons.remove_circle_outline, color: Colors.redAccent),
              onPressed: null, // Handled by parent
            ),
          ),
        ),
        TextButton.icon(
          onPressed: _showAddTierDialog,
          icon: const Icon(Icons.add, color: AppColors.amber),
          label: const Text(
            'ADD WHOLESALE TIER',
            style: TextStyle(color: AppColors.amber),
          ),
        ),
      ],
    );
  }

  void _showAddVariantDialog() {
    final nameController = TextEditingController();
    final stockController = TextEditingController();
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: colors.dialogBg,
          title: Text(
            'New Variant',
            style: TextStyle(color: colors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: _dialogInputDecoration('Color Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: stockController,
                decoration: _dialogInputDecoration('Stock (yds)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                nameController.dispose();
                stockController.dispose();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _variants.add(
                    FabricVariant(
                      colorName: nameController.text,
                      stockQuantity:
                          double.tryParse(stockController.text) ?? 0.0,
                    ),
                  );
                });
                nameController.dispose();
                stockController.dispose();
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTierDialog() {
    final qtyController = TextEditingController();
    final priceController = TextEditingController();
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: colors.dialogBg,
          title: Text(
            'New Wholesale Tier',
            style: TextStyle(color: colors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: qtyController,
                decoration: _dialogInputDecoration('Min Quantity'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: priceController,
                decoration: _dialogInputDecoration('Unit Price'),
                keyboardType: TextInputType.number,
                inputFormatters: priceInputFormatters,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                qtyController.dispose();
                priceController.dispose();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _tiers.add(
                    WholesaleTier(
                      minQuantity: double.tryParse(qtyController.text) ?? 0.0,
                      unitPrice:
                          double.tryParse(priceToDigits(priceController.text)) ??
                              0.0,
                    ),
                  );
                });
                qtyController.dispose();
                priceController.dispose();
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
    bool isPrice = false,
  }) {
    final colors = context.colors;
    return TextField(
      controller: controller,
      keyboardType:
          isNumber || isPrice ? TextInputType.number : TextInputType.text,
      inputFormatters: isPrice ? priceInputFormatters : null,
      style: TextStyle(
        color: colors.textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: colors.textHint,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
        filled: true,
        fillColor: colors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.amber),
        ),
      ),
    );
  }

  InputDecoration _dialogInputDecoration(String hint) {
    final colors = context.colors;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: colors.textHint, fontSize: 13),
      filled: true,
      fillColor: colors.inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.amber, width: 1.5),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    final colors = context.colors;
    final items = kFabricCategoriesWithoutAll;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.inputFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: _category,
          dropdownColor: colors.dropdownBg,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          items: items
              .map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Text(
                    c.toUpperCase(),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _category = v!),
          decoration: InputDecoration(
            labelText: 'CATEGORY',
            labelStyle: TextStyle(
              color: colors.textHint,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildPublishButton() {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: _isUploading ? null : _publish,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.amber,
          foregroundColor: AppColors.darkNavy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: _isUploading
            ? CircularProgressIndicator(color: context.colors.textOnAmber)
            : Text(
                widget.fabric == null
                    ? 'PUBLISH TO MARKETPLACE'
                    : 'UPDATE MATERIAL',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
      ),
    );
  }
}
