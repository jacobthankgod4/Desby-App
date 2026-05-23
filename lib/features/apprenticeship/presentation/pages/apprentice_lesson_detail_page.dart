import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desby_app/features/apprenticeship/presentation/providers/apprenticeship_provider.dart';
import '../../../../theme/colors.dart';

class ApprenticeLessonDetailPage extends ConsumerWidget {
  final String lessonId;
  const ApprenticeLessonDetailPage({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonAsync = ref.watch(lessonDetailProvider(lessonId));

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      appBar: AppBar(
        title: const Text('ACADEMY LESSON', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.amber, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: lessonAsync.when(
        data: (lesson) => SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('LESSON ${lesson.orderIndex + 1}', style: const TextStyle(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
              const SizedBox(height: 24),
              Text(lesson.title.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1, height: 1.1)),
              const SizedBox(height: 32),
              const Divider(color: Colors.white12),
              const SizedBox(height: 32),
              if (lesson.videoUrl != null) _buildVideoStation(lesson.videoUrl!),
              if (lesson.videoUrl != null) const SizedBox(height: 48),
              Text(lesson.content, style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.8, fontWeight: FontWeight.w500)),
              const SizedBox(height: 56),
              _buildTechnicalGuide(),
              const SizedBox(height: 60),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amber)),
        error: (err, _) => Center(child: Text('Lesson unavailable: $err', style: const TextStyle(color: Colors.white38))),
      ),
    );
  }

  Widget _buildVideoStation(String url) {
    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.3), width: 2),
        image: const DecorationImage(
          image: AssetImage('assets/images/masterclass_placeholder.jpg'),
          fit: BoxFit.cover,
          opacity: 0.4,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Neural Glow for the play button
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.amber,
              boxShadow: [
                BoxShadow(color: AppColors.amber.withValues(alpha: 0.4), blurRadius: 40, spreadRadius: 10)
              ],
            ),
            child: const Icon(Icons.play_arrow_rounded, color: AppColors.darkNavy, size: 48),
          ),
          Positioned(
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(12)),
              child: const Text('MASTERCLASS: PROCESS DEMONSTRATION', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalGuide() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.architecture_rounded, color: AppColors.amber, size: 20),
              SizedBox(width: 16),
              Text('TECHNICAL ARCHITECTURE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Ensure you have a 2H pencil, tracing paper, and a calibrated tailor square before initiating this sequence.', 
            style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.5)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber, foregroundColor: AppColors.darkNavy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('MARK AS CONSUMED', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}
