import 'package:flutter/material.dart';
import 'package:pod_player/pod_player.dart';
import 'package:screen_protector/screen_protector.dart';
import '../../../../theme/colors.dart';

class SecureVideoPlayer extends StatefulWidget {
  final String videoId;
  final String? vimeoToken;

  const SecureVideoPlayer({
    super.key,
    required this.videoId,
    this.vimeoToken,
  });

  @override
  State<SecureVideoPlayer> createState() => _SecureVideoPlayerState();
}

class _SecureVideoPlayerState extends State<SecureVideoPlayer> {
  late final PodPlayerController controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _setupSecurity();
    _initPlayer();
  }

  Future<void> _setupSecurity() async {
    // Enable screen recording and screenshot protection
    await ScreenProtector.preventScreenshotOn();
    // processAppCycle removed in 1.5.3, preventScreenshotOn persists by default
  }

  void _initPlayer() {
    controller = PodPlayerController(
      playVideoFrom: widget.vimeoToken != null
          ? PlayVideoFrom.vimeoPrivateVideos(
              widget.videoId,
              httpHeaders: {'Authorization': 'Bearer ${widget.vimeoToken}'},
            )
          : PlayVideoFrom.vimeo(widget.videoId),
      podPlayerConfig: const PodPlayerConfig(
        autoPlay: false,
        isLooping: false,
        videoQualityPriority: [720, 480, 360],
      ),
    )..initialise().then((_) {
        if (mounted) setState(() => _isInitialized = true);
      });
  }

  @override
  void dispose() {
    // Disable protection when leaving the page to allow normal app use
    ScreenProtector.preventScreenshotOff();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        height: 240,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(32),
        ),
        child: const Center(child: CircularProgressIndicator(color: AppColors.amber)),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: PodVideoPlayer(
        controller: controller,
        frameAspectRatio: 16 / 9,
        videoAspectRatio: 16 / 9,
      ),
    );
  }
}
