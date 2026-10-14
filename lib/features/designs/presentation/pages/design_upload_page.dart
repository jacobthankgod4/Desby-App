import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../../theme/colors.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/services/image_upload_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/entities/design.dart';
import '../providers/design_provider.dart';
import '../../../../core/widgets/shell_app_bar.dart';
import '../../../../core/widgets/price_text_field.dart';

class DesignUploadPage extends ConsumerStatefulWidget {
  const DesignUploadPage({super.key});

  @override
  ConsumerState<DesignUploadPage> createState() => _DesignUploadPageState();
}

class _DesignUploadPageState extends ConsumerState<DesignUploadPage> {
  final List<XFile> _selectedFiles = [];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ImageUploadService _imageService = ImageUploadService();
  bool _isUploading = false;

  String _selectedCategory = 'AGBADA';
  String _selectedGender = 'MALE';
  bool _isVisible = true;

  static const List<String> _categories = [
    'AGBADA',
    'DRESS',
    'GOWN',
    'ANKARA',
    'ASO EBI',
    'SUITS',
    'KAFTAN',
    'SENATOR',
    'BABARIGA',
    'JEAN',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.scaffoldBg,
      appBar: shellAppBar(context, title: 'UPLOAD DESIGN'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageGrid(),
            const SizedBox(height: 32),
            const Text(
              'DESIGN DETAILS',
              style: TextStyle(
                color: AppColors.amber,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField('TITLE', _titleController),
            const SizedBox(height: 16),
            _buildTextField(
              'PRICE (₦)',
              _priceController,
              keyboardType: TextInputType.number,
              inputFormatters: priceInputFormatters,
            ),
            const SizedBox(height: 16),
            _buildTextField('DESCRIPTION', _descriptionController, maxLines: 3),
            const SizedBox(height: 16),
            _buildCategoryPicker(),
            const SizedBox(height: 16),
            _buildGenderPicker(),
            const SizedBox(height: 40),
            _buildUploadButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      style: TextStyle(
        color: context.colors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: context.colors.textMuted,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
        filled: true,
        fillColor: context.colors.surface,
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

  Widget _buildCategoryPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CATEGORY',
          style: TextStyle(
            color: context.colors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((cat) {
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
                      : Border.all(color: context.colors.divider),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.darkNavy
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

  Widget _buildGenderPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GENDER',
          style: TextStyle(
            color: context.colors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: ['MALE', 'FEMALE', 'UNISEX'].map((g) {
            final isSelected = _selectedGender == g;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedGender = g),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.amber
                        : context.colors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: isSelected
                        ? null
                        : Border.all(color: context.colors.divider),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    g,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.darkNavy
                          : context.colors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'VISIBILITY',
              style: TextStyle(
                color: context.colors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            Switch(
              value: _isVisible,
              onChanged: (v) => setState(() => _isVisible = v),
              activeColor: AppColors.amber,
              activeTrackColor: AppColors.amber.withValues(alpha: 0.3),
              inactiveTrackColor: context.colors.borderSubtle,
            ),
          ],
        ),
        Text(
          _isVisible
              ? 'Visible to all clients'
              : 'Hidden — only you can see this',
          style: TextStyle(color: context.colors.textMuted, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildImageGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'DESIGN IMAGES',
              style: TextStyle(
                color: context.colors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            TextButton.icon(
              onPressed: _addImages,
              icon: const Icon(
                Icons.add_a_photo_outlined,
                size: 18,
                color: AppColors.amber,
              ),
              label: const Text(
                'ADD MORE',
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
        if (_selectedFiles.isEmpty)
          GestureDetector(
            onTap: _addImages,
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: context.colors.borderSubtle),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 40,
                    color: context.colors.textMuted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'SELECT DESIGN IMAGES',
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
            itemCount: _selectedFiles.length,
            itemBuilder: (context, index) {
              final file = _selectedFiles[index];
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: FutureBuilder<Uint8List>(
                      future: file.readAsBytes(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData)
                          return Image.memory(
                            snapshot.data!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          );
                        return Container(color: context.colors.overlayLight);
                      },
                    ),
                  ),
                  Positioned(
                    right: 4,
                    top: 4,
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedFiles.removeAt(index)),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: context.colors.overlayHeavy,
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
            },
          ),
      ],
    );
  }

  Widget _buildUploadButton() {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: _selectedFiles.isEmpty || _isUploading
            ? null
            : _handleUpload,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.amber,
          foregroundColor: AppColors.darkNavy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: _isUploading
            ? CircularProgressIndicator(color: context.colors.scaffoldBg)
            : const Text(
                'PUBLISH TO PORTFOLIO',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
      ),
    );
  }

  void _addImages() async {
    final images = await _imageService.pickMultipleImages();
    if (images.isNotEmpty) {
      setState(() => _selectedFiles.addAll(images));
    }
  }

  void _handleUpload() async {
    final title = _titleController.text.trim();
    final priceText = _priceController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty || priceText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in title and price'),
          backgroundColor: context.colors.statusError,
        ),
      );
      return;
    }

    final price = double.tryParse(priceText.replaceAll(RegExp(r'[^0-9.]'), ''));
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid price'),
          backgroundColor: context.colors.statusError,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      // Fetch tailor profile for location info
      final profile = await ref.read(userProfileProvider(user.id).future);

      // 1. Upload images to Supabase Storage
      final imageUrls = <String>[];
      for (final file in _selectedFiles) {
        final url = await _imageService.uploadImage(file, user.id, 'designs');
        if (url == null) {
          throw const ImageUploadException('Upload returned no URL');
        }
        imageUrls.add(url);
      }

      // 2. Save design record to Supabase
      final design = Design(
        id: const Uuid().v4(),
        title: title,
        category: _selectedCategory,
        price: price,
        tailorId: user.id,
        tailorName: user.name,
        tailorAvatarUrl: user.profileImage,
        tailorLocation: profile?.address ?? profile?.state,
        tailorState: profile?.state,
        tailorLga: profile?.lga,
        imageUrls: imageUrls,
        description: description.isNotEmpty ? description : null,
        gender: _selectedGender.toLowerCase(),
        isVisible: _isVisible,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = await ref
          .read(designRepositoryProvider)
          .uploadDesign(design);

      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload failed: ${failure.message}'),
              backgroundColor: context.colors.statusError,
            ),
          );
        },
        (_) {
          ref.invalidate(designListProvider(null));
          if (ref.canPopShell) {
            ref.popShell();
          } else {
            ref.setShell('/designs');
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('DESIGN PUBLISHED SUCCESSFULLY'),
              backgroundColor: Colors.greenAccent,
            ),
          );
        },
      );
    } on ImageUploadException catch (e) {
      debugPrint('Design image upload failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image upload failed — please try again'),
            backgroundColor: Colors.redAccent,
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
      if (mounted) setState(() => _isUploading = false);
    }
  }
}
