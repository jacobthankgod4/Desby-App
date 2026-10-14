import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../theme/colors.dart';
import '../../../../core/services/image_upload_service.dart';
import '../../domain/entities/apprentice_task.dart';
import '../providers/apprenticeship_provider.dart';
import '../../../../core/widgets/shell_app_bar.dart';

class ApprenticeTaskSubmissionPage extends ConsumerStatefulWidget {
  final ApprenticeTask task;
  const ApprenticeTaskSubmissionPage({super.key, required this.task});

  @override
  ConsumerState<ApprenticeTaskSubmissionPage> createState() =>
      _ApprenticeTaskSubmissionPageState();
}

class _ApprenticeTaskSubmissionPageState
    extends ConsumerState<ApprenticeTaskSubmissionPage> {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload physical proof of your craft.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      // 1. Upload proof images
      final imageUrls = await _imageService.uploadImages(
        _selectedImages,
        widget.task.apprenticeshipId,
        'tasks',
      );

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Submitted! Your mentor will review it soon.'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        ref.popShell();
      }
    } on ImageUploadException catch (e) {
      debugPrint('Apprentice task image upload failed: $e');
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
          SnackBar(
            content: Text('Could not submit your work. Please try again.'),
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
      appBar: shellAppBar(context, title: 'Submit Your Work'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTaskHeader(),
            const SizedBox(height: 40),
            const Text(
              'Photos',
              style: TextStyle(
                color: AppColors.amber,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _buildImagePicker(),
            const SizedBox(height: 40),
            const Text(
              'SUBMISSION NOTES',
              style: TextStyle(
                color: AppColors.amber,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
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
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.task.title.toUpperCase(),
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.task.description,
          style: TextStyle(color: colors.textMuted, fontSize: 14, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    final colors = context.colors;
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          InkWell(
            onTap: _pickImages,
            child: Container(
              width: 120,
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
          ),
          ..._selectedImages.map((file) => _buildImageThumbnail(file)),
        ],
      ),
    );
  }

  Widget _buildImageThumbnail(XFile file) {
    final colors = context.colors;
    return Container(
      width: 120,
      margin: const EdgeInsets.only(left: 12),
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
                  if (snapshot.hasData)
                    return Image.memory(snapshot.data!, fit: BoxFit.cover);
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: Icon(Icons.close, color: colors.textPrimary, size: 16),
                onPressed: () => setState(() => _selectedImages.remove(file)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    final colors = context.colors;
    return TextField(
      controller: _notesController,
      maxLines: 4,
      style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        hintText: 'Describe your process or challenges encountered...',
        hintStyle: TextStyle(color: colors.textHint),
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final colors = context.colors;
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: _isUploading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.amber,
          foregroundColor: AppColors.darkNavy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: _isUploading
            ? CircularProgressIndicator(color: colors.textOnAmber)
            : const Text(
                'Submit for Review',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
      ),
    );
  }
}
