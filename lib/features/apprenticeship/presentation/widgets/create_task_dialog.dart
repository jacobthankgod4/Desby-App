import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../theme/colors.dart';
import '../../domain/entities/apprentice_task.dart';
import '../providers/apprenticeship_provider.dart';

class CreateTaskDialog extends ConsumerStatefulWidget {
  final String apprenticeshipId;
  const CreateTaskDialog({super.key, required this.apprenticeshipId});

  @override
  ConsumerState<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends ConsumerState<CreateTaskDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final task = ApprenticeTask(
        id: const Uuid().v4(),
        apprenticeshipId: widget.apprenticeshipId,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        status: ApprenticeTaskStatus.todo,
        dueDate: _dueDate,
      );

      await ref.read(apprenticeshipRepositoryProvider).createTask(task);
      ref.invalidate(apprenticeshipTasksProvider(widget.apprenticeshipId));

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not create task. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Dialog(
      backgroundColor: colors.dialogBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ASSIGN NEW TASK',
              style: TextStyle(
                color: AppColors.amber,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              decoration: _inputDecoration(
                'Task Title (e.g. Draft Trouser Block)',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              maxLines: 3,
              style: TextStyle(color: colors.textPrimary),
              decoration: _inputDecoration('Detailed Instructions...'),
            ),
            const SizedBox(height: 24),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dueDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) setState(() => _dueDate = date);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      color: AppColors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'DUE DATE: ${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  foregroundColor: AppColors.darkNavy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSaving
                    ? CircularProgressIndicator(color: colors.iconPrimary)
                    : const Text(
                        'DEPLOY TASK',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    final colors = context.colors;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: colors.textHint, fontSize: 13),
      filled: true,
      fillColor: colors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }
}
