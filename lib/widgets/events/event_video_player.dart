import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../../services/media_upload_service.dart';
import '../../theme/theme.dart';

/// Plays an uploaded mp4 in-app. YouTube / Vimeo / other hosts open externally.
///
/// The whole video surface is tappable to play/pause, a spinner shows while the
/// clip loads, a scrubber lets people seek, and controls fade while playing.
class EventVideoPlayer extends StatefulWidget {
  final String videoUrl;

  /// Gallery callers provide their own numbered heading.
  final bool showTitle;

  const EventVideoPlayer({
    super.key,
    required this.videoUrl,
    this.showTitle = true,
  });

  @override
  State<EventVideoPlayer> createState() => _EventVideoPlayerState();
}

class _EventVideoPlayerState extends State<EventVideoPlayer> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (isDirectVideoUrl(widget.videoUrl)) {
      final controller =
          VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      _controller = controller;
      controller.addListener(_onControllerUpdate);
      controller.initialize().then((_) {
        if (!mounted) return;
        setState(() => _ready = true);
      }).catchError((_) {
        if (!mounted) return;
        setState(() => _failed = true);
      });
    }
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _openExternal() async {
    final uri = Uri.tryParse(widget.videoUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null) return;
    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        // Loop back to the start if the clip finished.
        if (controller.value.position >= controller.value.duration) {
          controller.seekTo(Duration.zero);
        }
        controller.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final controller = _controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle) ...[
          Text('Event video', style: text.titleSmall),
          const SizedBox(height: AppTheme.spacingSm),
        ],
        // Direct uploads that are still initialising: show a spinner surface.
        if (controller != null && !_ready && !_failed)
          _surface(
            colors,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          )
        else if (controller != null && _ready && !_failed)
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio == 0
                  ? 16 / 9
                  : controller.value.aspectRatio,
              child: GestureDetector(
                onTap: _togglePlay,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(controller),
                    // Big play/pause affordance; fades out while playing.
                    AnimatedOpacity(
                      opacity: controller.value.isPlaying ? 0 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          controller.value.position >=
                                      controller.value.duration &&
                                  controller.value.duration > Duration.zero
                              ? Icons.replay_rounded
                              : Icons.play_arrow_rounded,
                          color: colors.onPrimary,
                          size: AppTheme.iconLg,
                        ),
                      ),
                    ),
                    // Scrubber pinned to the bottom.
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: VideoProgressIndicator(
                        controller,
                        allowScrubbing: true,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        colors: VideoProgressColors(
                          playedColor: colors.primary,
                          bufferedColor: Colors.white54,
                          backgroundColor: Colors.white24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          // Externally hosted video (YouTube, Vimeo, …): open in the browser.
          GestureDetector(
            onTap: _openExternal,
            child: _surface(
              colors,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_circle_fill_rounded,
                        size: 56, color: colors.primary),
                    const SizedBox(height: 8),
                    Text(
                      _failed ? 'Tap to open video' : 'Tap to watch',
                      style: text.labelMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _surface(ColorScheme colors, {required Widget child}) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        color: colors.primaryContainer,
      ),
      child: child,
    );
  }
}
