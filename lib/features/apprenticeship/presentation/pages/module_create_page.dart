import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desby_app/theme/colors.dart';
import 'package:desby_app/core/providers/navigation_provider.dart';
import '../providers/apprenticeship_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/widgets/shell_app_bar.dart';

class ModuleCreatePage extends ConsumerStatefulWidget {
  final String? moduleId;
  final String? existingTitle;
  final String? existingDescription;
  final String? existingThumbnail;

  const ModuleCreatePage({
    super.key,
    this.moduleId,
    this.existingTitle,
    this.existingDescription,
    this.existingThumbnail,
  });

  @override
  ConsumerState<ModuleCreatePage> createState() => _ModuleCreatePageState();
}

class _ModuleCreatePageState extends ConsumerState<ModuleCreatePage> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _thumbnailController;
  bool _isSaving = false;

  bool get _isEditing => widget.moduleId != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingTitle ?? '');
    _descController = TextEditingController(
      text: widget.existingDescription ?? '',
    );
    _thumbnailController = TextEditingController(
      text: widget.existingThumbnail ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _thumbnailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _isSaving = true);

    final repo = ref.read(apprenticeshipRepositoryProvider);

    if (_isEditing) {
      final result = await repo.updateModule(
        widget.moduleId!,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
      );
      if (result.isSuccess && mounted) {
        ref.invalidate(curriculumProvider);
        ref.popShell();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Module updated!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } else {
      final curriculumAsync = ref.read(curriculumProvider);
      final orderIndex = curriculumAsync.valueOrNull?.length ?? 0;
      final currentUser = ref.read(currentUserProvider);
      final result = await repo.createModule(
        _titleController.text.trim(),
        _descController.text.trim(),
        orderIndex,
        tailorId: currentUser?.id,
      );
      if (result.isSuccess && mounted) {
        ref.invalidate(curriculumProvider);
        ref.popShell();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Module created!'),
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
        title: _isEditing ? 'EDIT MODULE' : 'NEW MODULE',
        actions: [
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
                    _isEditing ? 'SAVE' : 'CREATE',
                    style: TextStyle(
                      color: AppColors.amber,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      color: AppColors.amber.withValues(alpha: 0.7),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isEditing ? 'EDIT MODULE' : 'CREATE NEW MODULE',
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
                  'Modules group related lessons together',
                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 32),
                _buildField(_titleController, 'MODULE TITLE'),
                const SizedBox(height: 24),
                _buildField(_descController, 'DESCRIPTION', maxLines: 4),
                const SizedBox(height: 24),
                _buildField(
                  _thumbnailController,
                  'THUMBNAIL IMAGE URL (optional)',
                ),
                const SizedBox(height: 48),
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
                            _isEditing ? 'SAVE CHANGES' : 'CREATE MODULE',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
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
          decoration: InputDecoration(
            hintText: label,
            hintStyle: TextStyle(color: colors.textHint, fontSize: 13),
            filled: true,
            fillColor: colors.inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
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
}
