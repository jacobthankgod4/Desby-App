import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../theme/colors.dart';
import '../../../../core/services/image_upload_service.dart';
import '../../domain/entities/apprentice_task.dart';
import '../providers/apprenticeship_provider.dart';

class ApprenticeTaskSubmissionPage extends ConsumerStatefulWidget {
  final ApprenticeTask task;
  const ApprenticeTaskSubmissionPage({super.key, required this.task});

  @override
  ConsumerState<ApprenticeTaskSubmissionPage> createState() => _ApprenticeTaskSubmissionPageState();
}

class _ApprenticeTaskSubmissionPageState extends ConsumerState<ApprenticeTaskSubmissionPage> {
  final _imageService = ImageUploadService();
  final _notesController = TextEditingController();
  final List<XFile> _selectedImages = [];
  bool _isUploading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final images = await _imageService.pickMultipleImages();
    if (images.isNotEmpty) {
      setState(() => _selectedImages.addAll(images));
    }
  }

  Future<void> _submit() async {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload physical proof of your craft.'), backgroundColor: Colors.orangeAccent));
      return;
    }

    setState(() => _isUploading = true);

    try {
      // 1. Upload proof images
      final imageUrls = await _imageService.uploadImages(_selectedImages, widget.task.apprenticeshipId, 'tasks');

      // 2. Update task state
      final updatedTask = widget.task.copyWith(
        status: ApprenticeTaskStatus.underReview,
        proofImageUrls: imageUrls,
        submissionNotes: _notesController.text.trim(),
        completedAt: DateTime.now(),
      );

      await ref.read(apprenticeshipRepositoryProvider).updateTask(updatedTask);
      ref.invalidate(apprenticeshipTasksProvider(widget.task.apprenticeshipId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SUBMISSION SENT FOR MASTER REVIEW!'), backgroundColor: Color(0xFF00FF7F)));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submission Error: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      appBar: AppBar(
        title: const Text('SUBMIT PROOF', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2)),
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
            _buildTaskHeader(),
            const SizedBox(height: 40),
            const Text('MEDIA ASSETS', style: TextStyle(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            const SizedBox(height: 16),
            _buildImagePicker(),
            const SizedBox(height: 40),
            const Text('SUBMISSION NOTES', style: TextStyle(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            const SizedBox(height: 16),
            _buildNotesField(),
            const SizedBox(height: 48),
            _buildSubmitButton(),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.task.title.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        const SizedBox(height: 8),
        Text(widget.task.description, style: const TextStyle(color: Colors.white38, fontSize: 14, height: 1.4)),
      ],
    );
  }

  Widget _buildImagePicker() {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          InkWell(
            onTap: _pickImages,
            child: Container(
              width: 120,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
              child: const Icon(Icons.add_a_photo_rounded, color: AppColors.amber, size: 28),
            ),
          ),
          ..._selectedImages.map((file) => _buildImageThumbnail(file)),
        ],
      ),
    );
  }

  Widget _buildImageThumbnail(XFile file) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.amber.withValues(alpha: 0.3))),
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
            Positioned(top: 4, right: 4, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 16), onPressed: () => setState(() => _selectedImages.remove(file)))),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return TextField(
      controller: _notesController,
      maxLines: 4,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        hintText: 'Describe your process or challenges encountered...',
        hintStyle: const TextStyle(color: Colors.white10),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: _isUploading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.amber,
          foregroundColor: AppColors.darkNavy,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: _isUploading 
          ? const CircularProgressIndicator(color: AppColors.darkNavy)
          : const Text('SUBMIT FOR MASTER REVIEW', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
      ),
    );
  }
}
