import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:desby_app/theme/colors.dart';

class SecureVideoPlayer extends StatefulWidget {
  final String videoId;
  final String? videoUrl;

  const SecureVideoPlayer({super.key, required this.videoId, this.videoUrl});

  @override
  State<SecureVideoPlayer> createState() => _SecureVideoPlayerState();
}

class _SecureVideoPlayerState extends State<SecureVideoPlayer> {
  late String _viewType;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _viewType =
        'video-player-${widget.videoId}-${DateTime.now().millisecondsSinceEpoch}';
    _registerView();
  }

  void _registerView() {
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final video = html.VideoElement()
        ..src = widget.videoUrl ?? ''
        ..controls = true
        ..preload = 'metadata'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.borderRadius = '24px'
        ..style.backgroundColor = '#000000';

      video.onLoadedData.listen((_) {
        if (mounted) setState(() => _isLoading = false);
      });

      video.onError.listen((_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Could not load video';
          });
        }
      });

      return video;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        height: 240,
        color: colors.scaffoldBg,
        child: Stack(
          children: [
            HtmlElementView(viewType: _viewType),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: AppColors.amber),
              ),
            if (_errorMessage != null)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.redAccent,
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
