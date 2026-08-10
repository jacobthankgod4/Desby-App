import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../theme/colors.dart';
import '../../../../core/services/image_upload_service.dart';
import '../../../../core/network/eachlabs_client.dart';

class AiTryOnWidget extends StatefulWidget {
  final Function(String imageUrl) onGenerated;
  const AiTryOnWidget({super.key, required this.onGenerated});

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
    if (_personImage == null || _garmentImage == null) return;
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please describe the garment (e.g. Silk Kaftan)')));
      return;
    }

    setState(() {
      _isGenerating = true;
      _status = 'Uploading Assets...';
    });

    try {
      final personUrl = await _imageService.uploadImage(_personImage!, 'tryon', 'models');
      final garmentUrl = await _imageService.uploadImage(_garmentImage!, 'tryon', 'garments');

      if (personUrl == null || garmentUrl == null) throw 'Upload failed';

      setState(() => _status = 'Neural Texture Mapping...');
      
      final id = await _eachLabsClient.createPrediction(
        humanImg: personUrl,
        garmImg: garmentUrl,
        description: _descriptionController.text,
        category: _category,
      );

      if (id == null) throw 'AI Initiation failed';

      setState(() => _status = 'Diffusing Design (10-30s)...');

      final result = await _eachLabsClient.waitForResult(id);

      if (result.status == 'success' && result.output != null) {
        widget.onGenerated(result.output!);
        if (mounted) Navigator.pop(context);
      } else {
        throw result.error ?? 'Generation failed';
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI Error: $e'), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: Color(0xFF0A1921),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('IDM-VTON NEURAL FITTING', 
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2, color: AppColors.amber)),
            const SizedBox(height: 32),
            Row(
              children: [
                _buildImageSlot('CUSTOMER', _personImage, () => _pickImage(true)),
                const SizedBox(width: 24),
                const Icon(Icons.auto_awesome_mosaic_rounded, color: Colors.white10),
                const SizedBox(width: 24),
                _buildImageSlot('GARMENT', _garmentImage, () => _pickImage(false)),
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
                labelStyle: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
                hintText: 'e.g. Traditional African Lace Kaftan',
                hintStyle: const TextStyle(color: Colors.white10, fontSize: 12),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.03),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white10)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.amber)),
              ),
            ),
            const SizedBox(height: 40),
            if (_isGenerating) ...[
              const CircularProgressIndicator(color: AppColors.amber, strokeWidth: 2),
              const SizedBox(height: 24),
              Text(_status.toUpperCase(), style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1)),
            ] else
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: (_personImage != null && _garmentImage != null) ? _generate : null,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber, foregroundColor: AppColors.darkNavy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 0),
                  child: const Text('INITIALIZE TRY-ON', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    final categories = {
      'upper_body': 'TOPS',
      'lower_body': 'BOTTOMS',
      'dresses': 'ONE-PIECE'
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
                color: isSel ? AppColors.amber : Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSel ? AppColors.amber : Colors.white10),
              ),
              alignment: Alignment.center,
              child: Text(e.value, style: TextStyle(color: isSel ? AppColors.darkNavy : Colors.white60, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildImageSlot(String label, XFile? file, VoidCallback onTap) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 12),
          InkWell(
            onTap: onTap,
            child: Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: file != null ? AppColors.amber : Colors.white10, width: 1.5),
              ),
              child: file != null 
                ? ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.network(file.path, fit: BoxFit.cover))
                : const Icon(Icons.add_a_photo_rounded, color: Colors.white10, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}
