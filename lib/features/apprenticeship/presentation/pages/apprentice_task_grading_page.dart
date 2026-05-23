import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/colors.dart';
import '../../domain/entities/apprentice_task.dart';
import '../providers/apprenticeship_provider.dart';

class ApprenticeTaskGradingPage extends ConsumerStatefulWidget {
  final ApprenticeTask task;
  const ApprenticeTaskGradingPage({super.key, required this.task});

  @override
  ConsumerState<ApprenticeTaskGradingPage> createState() => _ApprenticeTaskGradingPageState();
}

class _ApprenticeTaskGradingPageState extends ConsumerState<ApprenticeTaskGradingPage> {
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('GRADE SUBMITTED & CERTIFIED!'), backgroundColor: Color(0xFF00FF7F)));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Grading Error: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      appBar: AppBar(
        title: const Text('GRADING STATION', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2)),
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
            _buildProofGallery(),
            const SizedBox(height: 40),
            _buildSubmissionDetails(),
            const SizedBox(height: 48),
            _buildGradingSection(),
            const SizedBox(height: 48),
            _buildActionButtons(),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildProofGallery() {
    final urls = widget.task.proofImageUrls ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PHYSICAL PROOF', style: TextStyle(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        if (urls.isEmpty)
          const Text('NO MEDIA ATTACHED', style: TextStyle(color: Colors.white10, fontWeight: FontWeight.w900, fontSize: 18))
        else
          SizedBox(
            height: 240,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: urls.length,
              separatorBuilder: (ctx, idx) => const SizedBox(width: 16),
              itemBuilder: (context, index) => ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.network(urls[index], fit: BoxFit.cover, width: 240),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubmissionDetails() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.white10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SUBMISSION NARRATIVE', style: TextStyle(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 16),
          Text(widget.task.submissionNotes ?? 'No notes provided.', style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildGradingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('SCORE MASTERY', style: TextStyle(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            Text('${_score.toInt()}/100', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
          ],
        ),
        Slider.adaptive(
          value: _score, min: 0, max: 100,
          divisions: 100, activeColor: AppColors.amber,
          onChanged: (v) => setState(() => _score = v),
        ),
        const SizedBox(height: 32),
        const Text('MENTOR FEEDBACK', style: TextStyle(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        TextField(
          controller: _feedbackController, maxLines: 3,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: 'Share expert insights...',
            hintStyle: const TextStyle(color: Colors.white10),
            filled: true, fillColor: Colors.white.withValues(alpha: 0.03),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('RE-ASSIGN', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _submitGrade,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber, foregroundColor: AppColors.darkNavy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
            child: _isSaving 
              ? const CircularProgressIndicator(color: AppColors.darkNavy)
              : const Text('CERTIFY MODULE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          ),
        ),
      ],
    );
  }
}
