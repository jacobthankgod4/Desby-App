import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import 'package:desby_app/features/apprenticeship/presentation/providers/apprenticeship_provider.dart';
import 'package:desby_app/features/apprenticeship/domain/entities/apprenticeship.dart';
import '../widgets/secure_video_player.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../theme/colors.dart';

class ApprenticeLessonDetailPage extends ConsumerStatefulWidget {
  final String lessonId;
  const ApprenticeLessonDetailPage({super.key, required this.lessonId});

  @override
  ConsumerState<ApprenticeLessonDetailPage> createState() => _ApprenticeLessonDetailPageState();
}

class _ApprenticeLessonDetailPageState extends ConsumerState<ApprenticeLessonDetailPage> {
  late ConfettiController _confettiController;
  bool _isConsuming = false;
  double _fontSize = 16.0;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lessonAsync = ref.watch(lessonDetailProvider(widget.lessonId));
    final currentUser = ref.watch(currentUserProvider);
    final apprenticeId = currentUser?.id ?? '';
    final apprenticeshipAsync = ref.watch(apprenticeApprenticeshipProvider(apprenticeId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('ACADEMY MODULE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2)),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_fields_rounded, size: 20),
            onPressed: () => setState(() => _fontSize = _fontSize == 16.0 ? 20.0 : 16.0),
          ),
        ],
      ),
      body: Stack(
        children: [
          lessonAsync.when(
            data: (lesson) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLessonHeader(lesson),
                  const SizedBox(height: 32),
                  
                  // 1. SECURE VIDEO STATION
                  if (lesson.videoUrl != null) 
                    _buildVideoSection(apprenticeshipAsync, lesson.videoUrl!),
                  
                  if (lesson.videoUrl != null) const SizedBox(height: 48),
                  
                  // 2. CONTENT READER
                  _buildContentBody(lesson.content),
                  
                  const SizedBox(height: 56),
                  
                  // 3. INTERACTIVE TECHNICAL GUIDE
                  _buildModernTechnicalGuide(ref, apprenticeId),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amber)),
            error: (err, _) => Center(child: Text('Lesson unavailable: $err', style: const TextStyle(color: Colors.white38))),
          ),
          
          // Confetti Overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [AppColors.amber, Colors.orange, Colors.white],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonHeader(dynamic lesson) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: AppColors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text('CHAPTER ${lesson.orderIndex + 1}', style: const TextStyle(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
        const SizedBox(height: 16),
        Text(lesson.title.toUpperCase(), 
          style: TextStyle(
            fontSize: 28, 
            fontWeight: FontWeight.w900, 
            letterSpacing: -1, 
            height: 1.1,
            color: Theme.of(context).colorScheme.onSurface,
          )),
      ],
    );
  }

  Widget _buildVideoSection(AsyncValue<Apprenticeship?> apprenticeshipAsync, String videoUrl) {
    return apprenticeshipAsync.when(
      data: (app) {
        final bool isActive = app != null && app.status == ApprenticeshipStatus.active;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: isActive 
            ? SecureVideoPlayer(videoId: _extractVimeoId(videoUrl))
            : _buildLockedStation(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Text('Authentication Loop Fault'),
    );
  }

  Widget _buildContentBody(String content) {
    return Text(
      content, 
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8), 
        fontSize: _fontSize, 
        height: 1.8, 
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildModernTechnicalGuide(WidgetRef ref, String apprenticeId) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, spreadRadius: 0),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.amber.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.architecture_rounded, color: AppColors.amber, size: 18),
              ),
              const SizedBox(width: 16),
              const Text('TECHNICAL CHECKLIST', 
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 24),
          _buildChecklistItem('Calibrate your industrial machine to 12 stitches per inch.'),
          _buildChecklistItem('Ensure all pattern weights are placed on the grain line.'),
          _buildChecklistItem('Prepare physical swatches for Master review.'),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton(
              onPressed: _isConsuming ? null : () => _markAsConsumed(ref, apprenticeId),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amber,
                foregroundColor: AppColors.darkNavy,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: _isConsuming 
                ? const CircularProgressIndicator(color: AppColors.darkNavy)
                : const Text('SYNC PROGRESS TO MASTER', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_box_outline_blank_rounded, size: 16, color: Colors.white24),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white38, fontSize: 12))),
        ],
      ),
    );
  }

  Future<void> _markAsConsumed(WidgetRef ref, String apprenticeId) async {
    setState(() => _isConsuming = true);
    HapticFeedback.heavyImpact();
    
    final apprenticeshipAsync = ref.read(apprenticeApprenticeshipProvider(apprenticeId));
    apprenticeshipAsync.whenData((app) async {
      if (app != null) {
        final newProgress = (app.progress + 0.05).clamp(0.0, 1.0);
        await ref.read(apprenticeshipRepositoryProvider).updateApprenticeship(app.copyWith(progress: newProgress));
        ref.invalidate(apprenticeApprenticeshipProvider(apprenticeId));
        
        _confettiController.play();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('MODULE SYNCED. EXCELLENT WORK!'), backgroundColor: Color(0xFF00FF7F))
          );
        }
      }
    });
    
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _isConsuming = false);
  }

  String _extractVimeoId(String url) {
    final uri = Uri.parse(url);
    if (uri.pathSegments.isNotEmpty) return uri.pathSegments.last;
    return url;
  }

  Widget _buildLockedStation() {
    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(32)),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_person_rounded, color: AppColors.amber, size: 48),
          SizedBox(height: 16),
          Text('RESTRICTED ACCESS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2)),
          Text('Active enrollment required.', style: TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }
}
