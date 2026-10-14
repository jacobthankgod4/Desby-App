import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../theme/colors.dart';
import '../../../../core/services/image_upload_service.dart';
import '../../../../core/network/eachlabs_client.dart';
import '../../../../core/widgets/app_network_image.dart';

class AiTryOnWidget extends StatefulWidget {
  final Function(String imageUrl) onGenerated;
  final String? garmentImageUrl;
  const AiTryOnWidget({
    super.key,
    required this.onGenerated,
    this.garmentImageUrl,
  });

  @override
  State<AiTryOnWidget> createState() => _AiTryOnWidgetState();
}

class _AiTryOnWidgetState extends State<AiTryOnWidget> {
  final _imageService = ImageUploadService();
  final _eachLabsClient = EachLabsClient();
  final _descriptionController = TextEditingController();

  XFile? _personImage;
  XFile? _garmentImage;
  bool _isGenerating = false;
  String _status = 'Standby';
  String _category = 'upper_body';

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isPerson) async {
    final img = await _imageService.pickImageFromGallery();
    if (img != null) {
      setState(() => isPerson ? _personImage = img : _garmentImage = img);
    }
  }

  Future<void> _generate() async {
    if (_personImage == null) return;
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe the garment (e.g. Silk Kaftan)'),
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _status = 'Uploading Assets...';
    });

    try {
      final personUrl = await _imageService.uploadImage(
        _personImage!,
        'tryon',
        'models',
      );
      String? garmentUrl;
      if (widget.garmentImageUrl != null) {
        garmentUrl = widget.garmentImageUrl;
      } else if (_garmentImage != null) {
        garmentUrl = await _imageService.uploadImage(
          _garmentImage!,
          'tryon',
          'garments',
        );
      } else {
        throw 'Please select a garment image';
      }

      if (personUrl == null || garmentUrl == null) {
        throw const ImageUploadException('Upload returned no URL');
      }

      setState(() => _status = 'Creating your try-on...');

      final id = await _eachLabsClient.createPrediction(
        humanImg: personUrl,
        garmImg: garmentUrl,
        description: _descriptionController.text,
        category: _category,
      );

      if (id == null) throw 'Could not start the try-on. Please try again.';

      setState(() => _status = 'Finalizing your look...');

      final result = await _eachLabsClient.waitForResult(id);

      if (result.status == 'success' && result.output != null) {
        widget.onGenerated(result.output!);
        if (mounted) Navigator.pop(context);
      } else {
        throw result.error ?? 'Generation failed';
      }
    } on ImageUploadException catch (e) {
      debugPrint('AI try-on image upload failed: $e');
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
            content: Text(
              'Something went wrong with the try-on. Please try again.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colors.scaffoldBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Virtual Try-On',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 2,
                color: AppColors.amber,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                _buildImageSlot(
                  'CUSTOMER',
                  _personImage,
                  () => _pickImage(true),
                ),
                const SizedBox(width: 24),
                Icon(Icons.arrow_forward_rounded, color: colors.borderSubtle),
                const SizedBox(width: 24),
                widget.garmentImageUrl != null
                    ? _buildNetworkImageSlot('GARMENT', widget.garmentImageUrl!)
                    : _buildImageSlot(
                        'GARMENT',
                        _garmentImage,
                        () => _pickImage(false),
                      ),
              ],
            ),
            const SizedBox(height: 32),
            _buildCategorySelector(),
            const SizedBox(height: 24),
            TextField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'GARMENT DESCRIPTION',
                labelStyle: TextStyle(
                  color: colors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
                hintText: 'e.g. Traditional African Lace Kaftan',
                hintStyle: TextStyle(color: colors.borderSubtle, fontSize: 12),
                filled: true,
                fillColor: colors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colors.borderSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.amber),
                ),
              ),
            ),
            const SizedBox(height: 40),
            if (_isGenerating) ...[
              const CircularProgressIndicator(
                color: AppColors.amber,
                strokeWidth: 2,
              ),
              const SizedBox(height: 24),
              Text(
                _status.toUpperCase(),
                style: TextStyle(
                  color: AppColors.amber,
                  fontWeight: FontWeight.w900,
                  fontSize: 9,
                  letterSpacing: 1,
                ),
              ),
            ] else
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed:
                      (_personImage != null &&
                          (widget.garmentImageUrl != null ||
                              _garmentImage != null))
                      ? _generate
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    foregroundColor: AppColors.darkNavy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Start Try-On',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    final colors = context.colors;
    final categories = {
      'upper_body': 'TOPS',
      'lower_body': 'BOTTOMS',
      'dresses': 'ONE-PIECE',
    };

    return Row(
      children: categories.entries.map((e) {
        final isSel = _category == e.key;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _category = e.key),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSel ? AppColors.amber : colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSel ? AppColors.amber : colors.borderSubtle,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                e.value,
                style: TextStyle(
                  color: isSel ? AppColors.darkNavy : colors.textMuted,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildImageSlot(String label, XFile? file, VoidCallback onTap) {
    final colors = context.colors;
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: onTap,
            child: Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: file != null ? AppColors.amber : colors.borderSubtle,
                  width: 1.5,
                ),
              ),
              child: file != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: AppNetworkImage(url: file.path, fit: BoxFit.cover),
                    )
                  : Icon(
                      Icons.add_a_photo_rounded,
                      color: colors.borderSubtle,
                      size: 28,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkImageSlot(String label, String imageUrl) {
    final colors = context.colors;
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.amber, width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AppNetworkImage(url: imageUrl, fit: BoxFit.cover),
            ),
          ),
        ],
      ),
    );
  }
}
