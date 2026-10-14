import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:confetti/confetti.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:desby_app/features/apprenticeship/presentation/providers/apprenticeship_provider.dart';
import 'package:desby_app/features/apprenticeship/domain/entities/apprenticeship.dart';
import 'package:desby_app/features/apprenticeship/domain/entities/apprentice_module.dart';
import 'package:desby_app/core/providers/navigation_provider.dart';
import '../widgets/secure_video_player.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../theme/colors.dart';
import '../../../../core/widgets/shell_app_bar.dart';

class ApprenticeLessonDetailPage extends ConsumerStatefulWidget {
  final String lessonId;
  const ApprenticeLessonDetailPage({super.key, required this.lessonId});

  @override
  ConsumerState<ApprenticeLessonDetailPage> createState() =>
      _ApprenticeLessonDetailPageState();
}

class _ApprenticeLessonDetailPageState
    extends ConsumerState<ApprenticeLessonDetailPage> {
  late ConfettiController _confettiController;
  bool _isConsuming = false;
  double _fontSize = 16.0;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final lessonAsync = ref.watch(lessonDetailProvider(widget.lessonId));
    final currentUser = ref.watch(currentUserProvider);
    final apprenticeId = currentUser?.id ?? '';
    final apprenticeshipAsync = ref.watch(
      apprenticeApprenticeshipProvider(apprenticeId),
    );

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: shellAppBar(
        context,
        title: 'Lesson',
        actions: [
          IconButton(
            icon: Icon(
              Icons.text_fields_rounded,
              size: 20,
              color: AppColors.amber,
            ),
            onPressed: () =>
                setState(() => _fontSize = _fontSize == 16.0 ? 20.0 : 16.0),
            tooltip: _fontSize == 16.0 ? 'Larger text' : 'Default text',
          ),
        ],
      ),
      body: Stack(
        children: [
          lessonAsync.when(
            data: (lesson) => _LessonContent(
              lesson: lesson,
              fontSize: _fontSize,
              apprenticeId: apprenticeId,
              apprenticeshipAsync: apprenticeshipAsync,
              onMarkComplete: () =>
                  _markAsConsumed(ref, apprenticeId, apprenticeshipAsync),
              confettiController: _confettiController,
              isConsuming: _isConsuming,
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.amber),
            ),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: Colors.redAccent,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'This lesson could not be loaded.',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please check your connection and try again.',
                      style: TextStyle(color: colors.textMuted, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () =>
                          ref.invalidate(lessonDetailProvider(widget.lessonId)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.amber,
                        foregroundColor: AppColors.darkNavy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
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

  Future<void> _markAsConsumed(
    WidgetRef ref,
    String apprenticeId,
    AsyncValue<Apprenticeship?> apprenticeshipAsync,
  ) async {
    setState(() => _isConsuming = true);
    HapticFeedback.heavyImpact();

    final app = apprenticeshipAsync.valueOrNull;
    if (app == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No active apprenticeship found.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      setState(() => _isConsuming = false);
      return;
    }

    final repo = ref.read(apprenticeshipRepositoryProvider);
    final markResult = await repo.markLessonComplete(app.id, widget.lessonId);

    if (markResult.isSuccess) {
      final progressResult = await repo.calculateProgress(app.id);
      progressResult.fold(
        (f) {
          debugPrint('[APPRENTICE] Failed to calculate progress: ${f.message}');
        },
        (newProgress) async {
          await repo.updateApprenticeship(app.copyWith(progress: newProgress));
        },
      );

      ref.invalidate(completedLessonsProvider(app.id));
      ref.invalidate(apprenticeApprenticeshipProvider(apprenticeId));

      _confettiController.play();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lesson completed! Great work!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save progress. Try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _isConsuming = false);
  }
}

class _LessonContent extends ConsumerWidget {
  final ApprenticeLesson lesson;
  final double fontSize;
  final String apprenticeId;
  final AsyncValue<Apprenticeship?> apprenticeshipAsync;
  final VoidCallback onMarkComplete;
  final ConfettiController confettiController;
  final bool isConsuming;

  const _LessonContent({
    required this.lesson,
    required this.fontSize,
    required this.apprenticeId,
    required this.apprenticeshipAsync,
    required this.onMarkComplete,
    required this.confettiController,
    required this.isConsuming,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final hasVideo = lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty;
    final hasContent = lesson.content.trim().isNotEmpty;
    final hasAttachments = lesson.attachments.isNotEmpty;
    final hasShortDesc =
        lesson.shortDescription != null &&
        lesson.shortDescription!.trim().isNotEmpty;

    if (!hasVideo && !hasContent && !hasAttachments) {
      return _EmptyState(lesson: lesson);
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width > 1000 ? 48 : 20,
              vertical: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LessonHeader(lesson: lesson),
                if (hasShortDesc) ...[
                  const SizedBox(height: 12),
                  Text(
                    lesson.shortDescription!,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                if (hasVideo) ...[
                  _VideoSection(
                    apprenticeshipAsync: apprenticeshipAsync,
                    videoUrl: lesson.videoUrl!,
                  ),
                  const SizedBox(height: 32),
                ],

                if (hasContent) ...[
                  _ContentBody(content: lesson.content, fontSize: fontSize),
                  const SizedBox(height: 32),
                ],

                if (hasAttachments) ...[
                  _AttachmentsSection(attachments: lesson.attachments),
                  const SizedBox(height: 32),
                ],

                _CompletionSection(
                  lessonId: lesson.id,
                  apprenticeId: apprenticeId,
                  apprenticeshipAsync: apprenticeshipAsync,
                  onMarkComplete: onMarkComplete,
                  isConsuming: isConsuming,
                ),

                const SizedBox(height: 32),

                _LessonNavigation(currentLesson: lesson, ref: ref),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LessonHeader extends StatelessWidget {
  final ApprenticeLesson lesson;
  const _LessonHeader({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'CHAPTER ${lesson.orderIndex + 1}',
                style: TextStyle(
                  color: AppColors.amber,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _TypeBadge(lessonType: lesson.lessonType),
            if (lesson.durationMinutes != null &&
                lesson.durationMinutes! > 0) ...[
              const SizedBox(width: 8),
              _DurationBadge(minutes: lesson.durationMinutes!),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Text(
          lesson.title.toUpperCase(),
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width > 600 ? 32 : 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            height: 1.1,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _VideoSection extends ConsumerWidget {
  final AsyncValue<Apprenticeship?> apprenticeshipAsync;
  final String videoUrl;

  const _VideoSection({
    required this.apprenticeshipAsync,
    required this.videoUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return apprenticeshipAsync.when(
      data: (app) {
        final isActive =
            app != null && app.status == ApprenticeshipStatus.active;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: isActive ? _buildVideoPlayer(context) : _buildLockedStation(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => _buildLockedStation(),
    );
  }

  Widget _buildVideoPlayer(BuildContext context) {
    if (kIsWeb) {
      return SecureVideoPlayer(videoId: videoUrl, videoUrl: videoUrl);
    }
    return _buildMobileVideoPlaceholder(context);
  }

  Widget _buildMobileVideoPlaceholder(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        color: colors.scaffoldBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.play_circle_outline_rounded,
            color: AppColors.amber,
            size: 64,
          ),
          const SizedBox(height: 12),
          Text(
            'Video available on web',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedStation() {
    return Builder(
      builder: (context) {
        final colors = context.colors;
        return Container(
          width: double.infinity,
          height: 240,
          decoration: BoxDecoration(
            color: colors.scaffoldBg,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_person_rounded,
                color: AppColors.amber,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'This content is locked',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
              Text(
                'Active enrollment required.',
                style: TextStyle(color: colors.textMuted, fontSize: 10),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ContentBody extends StatelessWidget {
  final String content;
  final double fontSize;

  const _ContentBody({required this.content, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final isJson =
        content.trimLeft().startsWith('{') ||
        content.trimLeft().startsWith('[');
    if (isJson) {
      final plainText = _extractPlainText(content);
      if (plainText.isEmpty) return const SizedBox.shrink();
      return _buildRichText(plainText, colors);
    }

    final isMarkdown =
        content.contains('#') ||
        content.contains('**') ||
        content.contains('- ') ||
        content.contains('1.') ||
        content.contains('\n\n');
    if (isMarkdown) {
      return MarkdownBody(
        data: content,
        styleSheet: MarkdownStyleSheet(
          p: TextStyle(
            color: colors.textSecondary,
            fontSize: fontSize,
            height: 1.8,
            fontWeight: FontWeight.w500,
          ),
          h1: TextStyle(
            color: colors.textPrimary,
            fontSize: fontSize + 8,
            fontWeight: FontWeight.w900,
          ),
          h2: TextStyle(
            color: colors.textPrimary,
            fontSize: fontSize + 4,
            fontWeight: FontWeight.w800,
          ),
          h3: TextStyle(
            color: colors.textPrimary,
            fontSize: fontSize + 2,
            fontWeight: FontWeight.w700,
          ),
          strong: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          em: TextStyle(color: AppColors.amber, fontStyle: FontStyle.italic),
          listBullet: TextStyle(color: AppColors.amber, fontSize: fontSize),
          code: TextStyle(
            color: AppColors.amber,
            fontSize: fontSize - 1,
            backgroundColor: colors.surface,
          ),
          blockquote: TextStyle(
            color: colors.textMuted,
            fontSize: fontSize,
            fontStyle: FontStyle.italic,
          ),
          blockquoteDecoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: AppColors.amber.withValues(alpha: 0.5),
                width: 3,
              ),
            ),
          ),
        ),
      );
    }

    return _buildRichText(content, colors);
  }

  Widget _buildRichText(String text, dynamic colors) {
    return Text(
      text,
      style: TextStyle(
        color: colors.textSecondary,
        fontSize: fontSize,
        height: 1.8,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  String _extractPlainText(String jsonContent) {
    try {
      final trimmed = jsonContent.trim();
      if (!trimmed.startsWith('{') && !trimmed.startsWith('[')) {
        return trimmed;
      }

      final parts = <String>[];
      final regex = RegExp(r'"insert"\s*:\s*"([^"]*)"');
      for (final match in regex.allMatches(trimmed)) {
        final text = match.group(1);
        if (text != null && text.isNotEmpty) {
          parts.add(text);
        }
      }
      return parts.join('');
    } catch (_) {
      return jsonContent;
    }
  }
}

class _AttachmentsSection extends StatelessWidget {
  final List<String> attachments;
  const _AttachmentsSection({required this.attachments});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.attach_file_rounded, color: AppColors.amber, size: 18),
            const SizedBox(width: 8),
            Text(
              'ATTACHMENTS',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...attachments.map(
          (url) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => _launchUrl(url),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.amber.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getFileIcon(url),
                        color: AppColors.amber,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getFileName(url),
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getFileExtension(url).toUpperCase(),
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.open_in_new_rounded,
                      color: colors.textMuted,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getFileIcon(String url) {
    final ext = _getFileExtension(url);
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_rounded;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image_rounded;
      case 'mp4':
      case 'mov':
      case 'avi':
        return Icons.videocam_rounded;
      case 'mp3':
      case 'wav':
        return Icons.audiotrack_rounded;
      case 'zip':
      case 'rar':
        return Icons.folder_zip_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  String _getFileName(String url) {
    final segments = Uri.parse(url).pathSegments;
    if (segments.isEmpty) return 'File';
    final name = segments.last;
    final queryIndex = name.indexOf('?');
    return queryIndex > 0 ? name.substring(0, queryIndex) : name;
  }

  String _getFileExtension(String url) {
    final name = _getFileName(url);
    final dotIndex = name.lastIndexOf('.');
    return dotIndex > 0 ? name.substring(dotIndex + 1) : '';
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _CompletionSection extends ConsumerWidget {
  final String lessonId;
  final String apprenticeId;
  final AsyncValue<Apprenticeship?> apprenticeshipAsync;
  final VoidCallback onMarkComplete;
  final bool isConsuming;

  const _CompletionSection({
    required this.lessonId,
    required this.apprenticeId,
    required this.apprenticeshipAsync,
    required this.onMarkComplete,
    required this.isConsuming,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return apprenticeshipAsync.when(
      data: (app) {
        if (app == null) return const SizedBox.shrink();
        final completedAsync = ref.watch(completedLessonsProvider(app.id));
        return completedAsync.when(
          data: (completed) {
            final isCompleted = completed.contains(lessonId);
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isCompleted
                      ? AppColors.successGreen.withValues(alpha: 0.3)
                      : AppColors.amber.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppColors.successGreen.withValues(alpha: 0.1)
                              : AppColors.amber.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCompleted
                              ? Icons.check_circle_rounded
                              : Icons.architecture_rounded,
                          color: isCompleted
                              ? AppColors.successGreen
                              : AppColors.amber,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          isCompleted ? 'Completed' : 'Mark as Complete',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            letterSpacing: 1,
                            color: isCompleted
                                ? AppColors.successGreen
                                : colors.textPrimary,
                          ),
                        ),
                      ),
                      if (isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.successGreen.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'DONE',
                            style: TextStyle(
                              color: AppColors.successGreen,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (!isCompleted)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isConsuming ? null : onMarkComplete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.amber,
                          foregroundColor: AppColors.darkNavy,
                          disabledBackgroundColor: AppColors.amber.withValues(
                            alpha: 0.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: isConsuming
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: AppColors.darkNavy,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Mark as Complete',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.amber),
          ),
          error: (_, _) => const SizedBox.shrink(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _LessonNavigation extends ConsumerWidget {
  final ApprenticeLesson currentLesson;
  final WidgetRef ref;

  const _LessonNavigation({required this.currentLesson, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final lessonsAsync = ref.watch(
      moduleLessonsProvider(currentLesson.moduleId),
    );

    return lessonsAsync.when(
      data: (lessons) {
        if (lessons.length <= 1) return const SizedBox.shrink();

        final currentIndex = lessons.indexWhere(
          (l) => l.id == currentLesson.id,
        );
        if (currentIndex < 0) return const SizedBox.shrink();

        final hasPrev = currentIndex > 0;
        final hasNext = currentIndex < lessons.length - 1;
        final prevLesson = hasPrev ? lessons[currentIndex - 1] : null;
        final nextLesson = hasNext ? lessons[currentIndex + 1] : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.swap_horiz_rounded,
                  color: colors.textMuted,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '${currentIndex + 1} OF ${lessons.length} LESSONS',
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (hasPrev)
                  Expanded(
                    child: _NavButton(
                      label: 'Previous',
                      title: prevLesson!.title,
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => _navigateToLesson(ref, prevLesson.id),
                    ),
                  )
                else
                  const Spacer(),
                const SizedBox(width: 12),
                if (hasNext)
                  Expanded(
                    child: _NavButton(
                      label: 'Next',
                      title: nextLesson!.title,
                      icon: Icons.arrow_forward_ios_rounded,
                      isForward: true,
                      onTap: () => _navigateToLesson(ref, nextLesson.id),
                    ),
                  )
                else
                  const Spacer(),
              ],
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  void _navigateToLesson(WidgetRef ref, String lessonId) {
    ref.pushShell('/apprentice-lesson-detail', {'lessonId': lessonId});
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final String title;
  final IconData icon;
  final bool isForward;
  final VoidCallback onTap;

  const _NavButton({
    required this.label,
    required this.title,
    required this.icon,
    this.isForward = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.amber.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            if (!isForward) ...[
              Icon(icon, color: AppColors.amber, size: 14),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: isForward
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isForward) ...[
              const SizedBox(width: 8),
              Icon(icon, color: AppColors.amber, size: 14),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ApprenticeLesson lesson;
  const _EmptyState({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.menu_book_rounded,
                color: AppColors.amber,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              lesson.title.toUpperCase(),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'This lesson is being prepared.\nContent will be available soon.',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String lessonType;
  const _TypeBadge({required this.lessonType});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _typeIcons[lessonType] ?? Icons.circle,
            color: AppColors.amber,
            size: 10,
          ),
          const SizedBox(width: 4),
          Text(
            _typeLabels[lessonType] ?? lessonType,
            style: TextStyle(
              color: AppColors.amber.withValues(alpha: 0.8),
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

const _typeLabels = {
  'video': 'Video',
  'text': 'Text',
  'assignment': 'Task',
  'download': 'File',
};
const _typeIcons = {
  'video': Icons.videocam_rounded,
  'text': Icons.article_outlined,
  'assignment': Icons.assignment_turned_in_rounded,
  'download': Icons.download_rounded,
};

class _DurationBadge extends StatelessWidget {
  final int minutes;
  const _DurationBadge({required this.minutes});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final label = h > 0 ? '${h}h ${m}m' : '${m}m';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, color: colors.iconMuted, size: 10),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: colors.iconMuted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
