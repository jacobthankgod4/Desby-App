import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../theme/colors.dart';
import '../../domain/entities/apprentice_task.dart';
import '../providers/apprenticeship_provider.dart';
import '../../../../core/widgets/shell_app_bar.dart';
import '../../../../core/widgets/app_network_image.dart';

class ApprenticeTaskGradingPage extends ConsumerStatefulWidget {
  final ApprenticeTask task;
  const ApprenticeTaskGradingPage({super.key, required this.task});

  @override
  ConsumerState<ApprenticeTaskGradingPage> createState() =>
      _ApprenticeTaskGradingPageState();
}

class _ApprenticeTaskGradingPageState
    extends ConsumerState<ApprenticeTaskGradingPage> {
  double _score = 80.0;
  final _feedbackController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitGrade() async {
    setState(() => _isSaving = true);
    try {
      final updatedTask = widget.task.copyWith(
        status: ApprenticeTaskStatus.completed,
        score: _score,
        feedback: _feedbackController.text.trim(),
      );

      await ref.read(apprenticeshipRepositoryProvider).updateTask(updatedTask);
      ref.invalidate(apprenticeshipTasksProvider(widget.task.apprenticeshipId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Grade submitted!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        ref.popShell();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not submit grade. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: shellAppBar(context, title: 'Grade Task'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProofGallery(),
            const SizedBox(height: 40),
            _buildSubmissionDetails(colors),
            const SizedBox(height: 48),
            _buildGradingSection(colors),
            const SizedBox(height: 48),
            _buildActionButtons(),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildProofGallery() {
    final colors = context.colors;
    final urls = widget.task.proofImageUrls ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Submitted Work',
          style: TextStyle(
            color: AppColors.amber,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        if (urls.isEmpty)
          Text(
            'No photos attached',
            style: TextStyle(
              color: colors.textMuted,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          )
        else
          SizedBox(
            height: 240,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: urls.length,
              separatorBuilder: (ctx, idx) => const SizedBox(width: 16),
              itemBuilder: (context, index) => ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: AppNetworkImage(
                  url: urls[index],
                  fit: BoxFit.cover,
                  width: 240,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubmissionDetails(DesbyThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notes from Apprentice',
            style: TextStyle(
              color: AppColors.amber,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.task.submissionNotes ?? 'No notes provided.',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradingSection(DesbyThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Score',
              style: TextStyle(
                color: AppColors.amber,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              '${_score.toInt()}/100',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
          ],
        ),
        Slider.adaptive(
          value: _score,
          min: 0,
          max: 100,
          divisions: 100,
          activeColor: AppColors.amber,
          onChanged: (v) => setState(() => _score = v),
        ),
        const SizedBox(height: 32),
        const Text(
          'MENTOR FEEDBACK',
          style: TextStyle(
            color: AppColors.amber,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _feedbackController,
          maxLines: 3,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            hintText: 'Share expert insights...',
            hintStyle: TextStyle(color: colors.textHint),
            filled: true,
            fillColor: colors.inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final colors = context.colors;
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => ref.popShell(),
            child: const Text(
              'Back',
              style: TextStyle(
                color: Colors.orangeAccent,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _submitGrade,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amber,
              foregroundColor: AppColors.darkNavy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _isSaving
                ? CircularProgressIndicator(color: colors.iconPrimary)
                : const Text(
                    'Submit Grade',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
