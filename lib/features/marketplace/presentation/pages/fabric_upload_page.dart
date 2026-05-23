import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../theme/colors.dart';
import '../../../../core/services/image_upload_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/fabric.dart';
import '../providers/fabric_provider.dart';

class FabricUploadPage extends ConsumerStatefulWidget {
  const FabricUploadPage({super.key});

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
  bool _isUploading = false;

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
    if (_nameController.text.isEmpty || _priceController.text.isEmpty || _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name, Price, and at least one image are mandatory.'), backgroundColor: Colors.orangeAccent),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);

      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final fabricId = 'FAB_${DateTime.now().millisecondsSinceEpoch}';
      
      // 1. Upload Images using byte-based architecture
      final imageUrls = await _imageService.uploadImages(_selectedImages, user.id, 'fabrics');

      // 2. Create Fabric Entity
      final fabric = Fabric(
        id: fabricId,
        name: _nameController.text.trim(),
        category: _category,
        pricePerYard: double.tryParse(_priceController.text) ?? 0.0,
        stockQuantity: double.tryParse(_stockController.text) ?? 0.0,
        sellerId: user.id,
        imageUrls: imageUrls,
        composition: _compositionController.text.trim(),
        weight: _weightController.text.trim(),
        origin: _originController.text.trim(),
        availableColors: const ['Standard'], 
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 3. Save to Firestore
      final result = await ref.read(fabricRepositoryProvider).uploadFabric(fabric);

      result.fold(
        (failure) => messenger.showSnackBar(SnackBar(content: Text('Upload Failed: $failure'), backgroundColor: Colors.redAccent)),
        (_) {
          messenger.showSnackBar(const SnackBar(content: Text('FABRIC PUBLISHED TO MARKETPLACE!'), backgroundColor: Colors.greenAccent));
          navigator.pop();
        },
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('System Error: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      appBar: AppBar(
        title: const Text('MARKETPLACE UPLOAD', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.amber, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
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
                Expanded(child: _buildField('PRICE PER YARD (NGN) *', _priceController, isNumber: true)),
                const SizedBox(width: 16),
                Expanded(child: _buildField('INITIAL STOCK (YDS)', _stockController, isNumber: true)),
              ],
            ),
            const SizedBox(height: 16),
            _buildCategoryDropdown(),
            const SizedBox(height: 32),
            _buildSectionTitle('PROFESSIONAL METADATA'),
            const SizedBox(height: 16),
            _buildField('COMPOSITION (e.g. 100% COTTON)', _compositionController),
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
    return Text(title, style: const TextStyle(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5));
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('DESIGN ASSETS', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildAddImageButton(),
              ..._selectedImages.map((file) => _buildImageThumbnail(file)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddImageButton() {
    return InkWell(
      onTap: _pickImages,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: const Icon(Icons.add_a_photo_rounded, color: AppColors.amber, size: 28),
      ),
    );
  }

  Widget _buildImageThumbnail(XFile file) {
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
              child: FutureBuilder(
                future: file.readAsBytes(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) return Image.memory(snapshot.data!, fit: BoxFit.cover);
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
            Positioned(
              top: 4, right: 4,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 16),
                onPressed: () => setState(() => _selectedImages.remove(file)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.w900),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.amber)),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    final items = ['Cotton', 'Silk', 'Linen', 'Wool', 'Lace', 'Velvet', 'Leather', 'Satin', 'Damask'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(16)),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          initialValue: _category,
          dropdownColor: AppColors.darkNavy,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          items: items.map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase(), style: const TextStyle(fontSize: 12)))).toList(),
          onChanged: (v) => setState(() => _category = v!),
          decoration: const InputDecoration(labelText: 'CATEGORY', labelStyle: TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.w900), border: InputBorder.none),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: _isUploading 
          ? const CircularProgressIndicator(color: AppColors.darkNavy)
          : const Text('PUBLISH TO MARKETPLACE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
      ),
    );
  }
}
