import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;
import 'package:desby_app/theme/colors.dart';
import 'package:desby_app/core/providers/navigation_provider.dart';
import 'package:desby_app/features/apprenticeship/data/services/hyperserve_service.dart';
import 'package:fleather/fleather.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/apprenticeship_provider.dart';
import '../widgets/rich_text_editor.dart';
import '../../../../core/widgets/shell_app_bar.dart';
import '../../../../core/widgets/app_network_image.dart';

const _lessonTypes = ['video', 'text', 'assignment', 'download'];
const _lessonTypeLabels = {
  'video': 'Video Lesson',
  'text': 'Text / Article',
  'assignment': 'Practice Assignment',
  'download': 'Downloadable Resource',
};
const _lessonTypeIcons = {
  'video': Icons.videocam_rounded,
  'text': Icons.article_rounded,
  'assignment': Icons.assignment_turned_in_rounded,
  'download': Icons.download_rounded,
};

class LessonCreatePage extends ConsumerStatefulWidget {
  final String moduleId;
  final String moduleName;
  final String? lessonId;
  final String? existingTitle;
  final String? existingContent;
  final String? existingVideoUrl;
  final String? existingShortDescription;
  final String? existingThumbnailUrl;
  final int? existingDurationMinutes;
  final String? existingLessonType;
  final bool? existingIsPublished;
  final bool? existingIsFreePreview;
  final List<String>? existingAttachments;

  const LessonCreatePage({
    super.key,
    required this.moduleId,
    required this.moduleName,
    this.lessonId,
    this.existingTitle,
    this.existingContent,
    this.existingVideoUrl,
    this.existingShortDescription,
    this.existingThumbnailUrl,
    this.existingDurationMinutes,
    this.existingLessonType,
    this.existingIsPublished,
    this.existingIsFreePreview,
    this.existingAttachments,
  });

  @override
  ConsumerState<LessonCreatePage> createState() => _LessonCreatePageState();
}

class _LessonCreatePageState extends ConsumerState<LessonCreatePage> {
  late final TextEditingController _titleController;
  late final TextEditingController _shortDescController;
  late final FleatherController _contentController;
  late final TextEditingController _videoUrlController;
  late final TextEditingController _thumbnailController;
  late final TextEditingController _durationController;
  late final TextEditingController _attachmentController;
  bool _isSaving = false;
  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _videoPreviewViewType;
  String _lessonType = 'video';
  bool _isPublished = true;
  bool _isFreePreview = false;
  List<String> _attachments = [];
  double? _videoAspectRatio;

  bool get _isEditing => widget.lessonId != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingTitle ?? '');
    _shortDescController = TextEditingController(
      text: widget.existingShortDescription ?? '',
    );
    final existingContent = widget.existingContent ?? '';
    if (existingContent.isNotEmpty) {
      try {
        final json = jsonDecode(existingContent);
        _contentController = FleatherController(
          document: ParchmentDocument.fromJson(json),
        );
      } catch (_) {
        _contentController = FleatherController(
          document: ParchmentDocument.fromJson([
            {'insert': '$existingContent\n'},
          ]),
        );
      }
    } else {
      _contentController = FleatherController(document: ParchmentDocument());
    }
    _videoUrlController = TextEditingController(
      text: widget.existingVideoUrl ?? '',
    );
    _thumbnailController = TextEditingController(
      text: widget.existingThumbnailUrl ?? '',
    );
    _durationController = TextEditingController(
      text: widget.existingDurationMinutes?.toString() ?? '',
    );
    _attachmentController = TextEditingController();
    _lessonType = widget.existingLessonType ?? 'video';
    _isPublished = widget.existingIsPublished ?? true;
    _isFreePreview = widget.existingIsFreePreview ?? false;
    _attachments = List.from(widget.existingAttachments ?? []);
    if (_videoUrlController.text.isNotEmpty) {
      _registerVideoPreview(_videoUrlController.text);
    }
  }

  void _registerVideoPreview(String url) {
    final viewId =
        'lesson-video-preview-${DateTime.now().millisecondsSinceEpoch}';
    _videoPreviewViewType = viewId;
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
      final video = html.VideoElement()
        ..src = url
        ..controls = true
        ..preload = 'metadata'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'contain'
        ..style.borderRadius = '16px'
        ..style.backgroundColor = '#0a0a0a';
      video.onLoadedMetadata.listen((_) {
        final w = video.videoWidth.toDouble();
        final h = video.videoHeight.toDouble();
        if (w > 0 && h > 0 && mounted) {
          setState(() => _videoAspectRatio = w / h);
        }
      });
      return video;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _shortDescController.dispose();
    _contentController.dispose();
    _videoUrlController.dispose();
    _thumbnailController.dispose();
    _durationController.dispose();
    _attachmentController.dispose();
    super.dispose();
  }

  void _uploadVideo() {
    if (_isUploading) return;

    final uploadInput = html.FileUploadInputElement()..accept = 'video/*';
    uploadInput.click();

    uploadInput.onChange.listen((event) async {
      final file = uploadInput.files?.first;
      if (file == null) return;

      final hyperserve = HyperserveService();
      if (!hyperserve.isConfigured) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video upload is not configured. Contact support.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        _isUploading = true;
        _uploadProgress = 0;
      });

      try {
        final bytesCompleter = Completer<Uint8List>();
        final reader = html.FileReader();
        reader.onLoadEnd.listen((_) {
          bytesCompleter.complete(
            Uint8List.fromList(reader.result as List<int>),
          );
        });
        reader.readAsArrayBuffer(file);
        final fileBytes = await bytesCompleter.future;

        setState(() => _uploadProgress = 0.2);

        final createResult = await hyperserve.createVideo(
          filename: file.name,
          fileSizeBytes: fileBytes.length,
        );
        setState(() => _uploadProgress = 0.6);

        await hyperserve.uploadFile(
          createResult.uploadUrl,
          fileBytes,
          createResult.contentType,
        );
        setState(() => _uploadProgress = 0.85);

        await hyperserve.completeUpload(createResult.videoId);
        setState(() => _uploadProgress = 0.95);

        final playbackUrl = await hyperserve.getPlaybackUrl(
          createResult.videoId,
        );

        if (!mounted) return;

        if (playbackUrl != null) {
          setState(() {
            _videoUrlController.text = playbackUrl;
            _isUploading = false;
            _uploadProgress = 0;
          });
          _registerVideoPreview(playbackUrl);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Video uploaded successfully!'),
              backgroundColor: AppColors.successGreen,
            ),
          );
        } else {
          setState(() {
            _isUploading = false;
            _uploadProgress = 0;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Upload complete. Video is processing — check back in a minute.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isUploading = false;
          _uploadProgress = 0;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Video upload failed: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    });
  }

  Future<void> _uploadThumbnail() async {
    final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((event) async {
      final file = uploadInput.files?.first;
      if (file == null) return;

      setState(() => _isUploading = true);

      final reader = html.FileReader();
      reader.onLoadEnd.listen((_) async {
        final bytes = Uint8List.fromList(reader.result as List<int>);
        try {
          final ext = file.name.split('.').last.toLowerCase();
          final contentType = ext == 'png'
              ? 'image/png'
              : ext == 'webp'
              ? 'image/webp'
              : 'image/jpeg';
          final fileName =
              'lessons/thumbnails/${DateTime.now().millisecondsSinceEpoch}.$ext';

          await Supabase.instance.client.storage
              .from('images')
              .uploadBinary(
                fileName,
                bytes,
                fileOptions: FileOptions(
                  contentType: contentType,
                  upsert: true,
                ),
              );

          final url = Supabase.instance.client.storage
              .from('images')
              .getPublicUrl(fileName);
          if (mounted) {
            setState(() {
              _thumbnailController.text = url;
              _isUploading = false;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() => _isUploading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Thumbnail upload failed: $e'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
      });
      reader.readAsArrayBuffer(file);
    });
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _isSaving = true);

    final repo = ref.read(apprenticeshipRepositoryProvider);
    final videoUrl = _videoUrlController.text.trim().isEmpty
        ? null
        : _videoUrlController.text.trim();
    final shortDesc = _shortDescController.text.trim().isEmpty
        ? null
        : _shortDescController.text.trim();
    final thumbnail = _thumbnailController.text.trim().isEmpty
        ? null
        : _thumbnailController.text.trim();
    final duration = int.tryParse(_durationController.text.trim());

    if (_isEditing) {
      final result = await repo.updateLesson(
        widget.lessonId!,
        title: _titleController.text.trim(),
        content: _contentController.document.toPlainText().trim(),
        videoUrl: videoUrl,
        shortDescription: shortDesc,
        thumbnailUrl: thumbnail,
        durationMinutes: duration,
        lessonType: _lessonType,
        isPublished: _isPublished,
        isFreePreview: _isFreePreview,
        attachments: _attachments,
      );
      if (result.isSuccess && mounted) {
        ref.invalidate(curriculumProvider);
        ref.invalidate(moduleLessonsProvider(widget.moduleId));
        ref.popShell();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lesson updated!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } else {
      final moduleAsync = ref.read(curriculumProvider);
      final modules = moduleAsync.valueOrNull ?? [];
      final module = modules.firstWhere(
        (m) => m.id == widget.moduleId,
        orElse: () => modules.first,
      );
      final result = await repo.createLesson(
        widget.moduleId,
        _titleController.text.trim(),
        _contentController.document.toPlainText().trim(),
        module.lessonIds.length,
        videoUrl: videoUrl,
        shortDescription: shortDesc,
        thumbnailUrl: thumbnail,
        durationMinutes: duration,
        lessonType: _lessonType,
        isPublished: _isPublished,
        isFreePreview: _isFreePreview,
        attachments: _attachments,
      );
      if (result.isSuccess && mounted) {
        ref.invalidate(curriculumProvider);
        ref.invalidate(moduleLessonsProvider(widget.moduleId));
        ref.popShell();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lesson added!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    }

    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: shellAppBar(
        context,
        title: _isEditing ? 'EDIT LESSON' : 'NEW LESSON',
        actions: [
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _isFreePreview = !_isFreePreview),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _isFreePreview
                        ? AppColors.amber.withValues(alpha: 0.15)
                        : colors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isFreePreview
                          ? AppColors.amber.withValues(alpha: 0.3)
                          : colors.borderDefault,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility_rounded,
                        size: 13,
                        color: _isFreePreview
                            ? AppColors.amber
                            : colors.iconMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Free Preview',
                        style: TextStyle(
                          fontSize: 10,
                          color: _isFreePreview
                              ? AppColors.amber
                              : colors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _isPublished ? 'Published' : 'Draft',
                style: TextStyle(
                  color: _isPublished
                      ? AppColors.successGreen
                      : colors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Switch(
                value: _isPublished,
                onChanged: (v) => setState(() => _isPublished = v),
                activeThumbColor: AppColors.successGreen,
                inactiveTrackColor: colors.borderDefault,
              ),
              const SizedBox(width: 8),
            ],
          ),
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.amber,
                    ),
                  )
                : Text(
                    _isEditing ? 'SAVE' : 'ADD',
                    style: TextStyle(
                      color: AppColors.amber,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: isWide
                ? _buildWideLayout(constraints)
                : _buildNarrowLayout(constraints),
          );
        },
      ),
    );
  }

  Widget _buildWideLayout(BoxConstraints constraints) {
    final hasVideo = _videoUrlController.text.trim().isNotEmpty;
    final rightWidth = (constraints.maxWidth * 0.35).clamp(280.0, 400.0);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildLeftColumn()),
        const SizedBox(width: 32),
        SizedBox(width: rightWidth, child: _buildRightColumn(hasVideo)),
      ],
    );
  }

  Widget _buildNarrowLayout(BoxConstraints constraints) {
    final hasVideo = _videoUrlController.text.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLeftColumn(),
        const SizedBox(height: 32),
        _buildRightColumn(hasVideo),
      ],
    );
  }

  Widget _buildLeftColumn() {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Module: ${widget.moduleName}',
            style: TextStyle(
              color: AppColors.amber,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 32),
        _buildField(_titleController, 'LESSON TITLE'),
        const SizedBox(height: 20),
        _buildField(_shortDescController, 'SHORT DESCRIPTION', maxLines: 2),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _buildLessonTypeDropdown()),
            const SizedBox(width: 16),
            Expanded(
              child: _buildField(
                _durationController,
                'DURATION (min)',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.edit_note_rounded,
              color: AppColors.amber.withValues(alpha: 0.7),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'LESSON CONTENT',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        RichTextEditor(
          controller: _contentController,
          hintText: 'Write your lesson content here...',
          maxLines: 16,
        ),
        const SizedBox(height: 32),
        _buildThumbnailUpload(),
      ],
    );
  }

  Widget _buildRightColumn(bool hasVideo) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.videocam_rounded,
              color: AppColors.amber.withValues(alpha: 0.7),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'VIDEO',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildVideoSection(hasVideo),
        const SizedBox(height: 32),
        Row(
          children: [
            Icon(
              Icons.attach_file_rounded,
              color: AppColors.amber.withValues(alpha: 0.7),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'ATTACHMENTS',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Patterns, measurement charts, reference images',
          style: TextStyle(color: colors.textMuted, fontSize: 11),
        ),
        const SizedBox(height: 12),
        _buildAttachmentsSection(),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amber,
              foregroundColor: AppColors.darkNavy,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isSaving
                ? CircularProgressIndicator(color: colors.iconPrimary)
                : Text(
                    _isEditing ? 'SAVE CHANGES' : 'ADD LESSON',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
    IconData? prefixIcon,
  }) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: label,
            hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: colors.iconMuted, size: 18)
                : null,
            filled: true,
            fillColor: colors.inputFill,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.borderDefault),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.borderDefault),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.amber, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThumbnailUpload() {
    final colors = context.colors;
    final hasThumb = _thumbnailController.text.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.image_rounded,
              color: AppColors.amber.withValues(alpha: 0.7),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'THUMBNAIL',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Preview image shown in lesson list',
          style: TextStyle(color: colors.textMuted, fontSize: 11),
        ),
        const SizedBox(height: 12),
        if (hasThumb) ...[
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AppNetworkImage(
                  url: _thumbnailController.text.trim(),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 160,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => setState(() => _thumbnailController.clear()),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colors.scaffoldBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: colors.textPrimary,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isUploading ? null : _uploadThumbnail,
              icon: const Icon(Icons.swap_horiz_rounded, size: 16),
              label: const Text('CHANGE THUMBNAIL'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.textSecondary,
                side: BorderSide(color: colors.borderDefault),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ] else ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isUploading ? null : _uploadThumbnail,
              icon: const Icon(Icons.add_a_photo_rounded, size: 20),
              label: const Text('UPLOAD THUMBNAIL'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.amber,
                side: BorderSide(color: AppColors.amber.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 18),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLessonTypeDropdown() {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LESSON TYPE',
          style: TextStyle(
            color: colors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: colors.inputFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.borderDefault),
          ),
          child: DropdownButton<String>(
            value: _lessonType,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            dropdownColor: colors.dropdownBg,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            items: _lessonTypes
                .map(
                  (t) => DropdownMenuItem(
                    value: t,
                    child: Row(
                      children: [
                        Icon(
                          _lessonTypeIcons[t],
                          color: AppColors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 10),
                        Text(_lessonTypeLabels[t] ?? t),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _lessonType = v ?? 'video'),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoSection(bool hasVideo) {
    final colors = context.colors;
    if (_isUploading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.inputFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_upload_rounded,
              color: AppColors.amber,
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              'Uploading video...',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _uploadProgress > 0 ? _uploadProgress : null,
                backgroundColor: colors.divider,
                color: AppColors.amber,
                minHeight: 6,
              ),
            ),
          ],
        ),
      );
    }

    if (hasVideo && _videoPreviewViewType != null) {
      final ratio = _videoAspectRatio;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              height: ratio != null ? null : 280,
              constraints: ratio != null
                  ? BoxConstraints(maxHeight: 400)
                  : null,
              decoration: BoxDecoration(
                color: colors.scaffoldBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ratio != null
                  ? AspectRatio(
                      aspectRatio: ratio,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: HtmlElementView(
                          viewType: _videoPreviewViewType!,
                        ),
                      ),
                    )
                  : HtmlElementView(viewType: _videoPreviewViewType!),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.successGreen,
                size: 14,
              ),
              const SizedBox(width: 6),
              if (ratio != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    ratio > 1
                        ? 'Landscape'
                        : ratio < 1
                        ? 'Portrait'
                        : 'Square',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (ratio != null) const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _videoUrlController.text.trim(),
                  style: TextStyle(color: AppColors.successGreen, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _videoUrlController.clear();
                    _videoPreviewViewType = null;
                    _videoAspectRatio = null;
                  });
                },
                icon: const Icon(Icons.close_rounded, size: 14),
                label: const Text('Remove', style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _uploadVideo,
            icon: const Icon(Icons.cloud_upload_rounded, size: 20),
            label: const Text('UPLOAD VIDEO'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.amber,
              side: BorderSide(color: AppColors.amber.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 18),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: Divider(color: colors.divider)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'OR',
                style: TextStyle(
                  color: colors.textHint,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(child: Divider(color: colors.divider)),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _videoUrlController,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          onChanged: (val) {
            setState(() {});
            if (val.trim().isNotEmpty) {
              _registerVideoPreview(val.trim());
            } else {
              _videoAspectRatio = null;
            }
          },
          decoration: InputDecoration(
            hintText: 'Paste video URL',
            hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
            prefixIcon: Icon(
              Icons.link_rounded,
              color: colors.iconMuted,
              size: 18,
            ),
            filled: true,
            fillColor: colors.inputFill,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.borderDefault),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.borderDefault),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.amber, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentsSection() {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _attachmentController,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          onSubmitted: (val) {
            final url = val.trim();
            if (url.isNotEmpty && Uri.tryParse(url)?.hasAbsolutePath == true) {
              setState(() {
                _attachments.add(url);
                _attachmentController.clear();
              });
            }
          },
          decoration: InputDecoration(
            hintText: 'Paste URL and press Enter',
            hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
            prefixIcon: Icon(
              Icons.link_rounded,
              color: colors.iconMuted,
              size: 18,
            ),
            suffixIcon: IconButton(
              icon: const Icon(
                Icons.add_rounded,
                color: AppColors.amber,
                size: 20,
              ),
              onPressed: () {
                final url = _attachmentController.text.trim();
                if (url.isNotEmpty &&
                    Uri.tryParse(url)?.hasAbsolutePath == true) {
                  setState(() {
                    _attachments.add(url);
                    _attachmentController.clear();
                  });
                }
              },
            ),
            filled: true,
            fillColor: colors.inputFill,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.borderDefault),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.borderDefault),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.amber, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
        if (_attachments.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _attachments.asMap().entries.map((entry) {
              final i = entry.key;
              final url = entry.value;
              final filename = url.split('/').last;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.amber.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.attach_file_rounded,
                      color: AppColors.amber,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: Text(
                        filename,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => setState(() => _attachments.removeAt(i)),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.redAccent,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
