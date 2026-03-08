import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../config/theme.dart';
import '../utils/download_utils.dart';

class VideoResultView extends StatefulWidget {
  final String videoUrl;

  const VideoResultView({
    super.key,
    required this.videoUrl,
  });

  @override
  State<VideoResultView> createState() => _VideoResultViewState();
}

class _VideoResultViewState extends State<VideoResultView> {
  late final Player _player;
  late final VideoController _controller;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _player.open(Media(widget.videoUrl));
    _player.setPlaylistMode(PlaylistMode.loop);
  }

  @override
  void didUpdateWidget(VideoResultView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _player.open(Media(widget.videoUrl));
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Result', style: AppTypography.headingLg)
              .animate()
              .fadeIn(duration: 400.ms),
          const SizedBox(height: 16),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Video(
                    controller: _controller,
                    controls: MaterialVideoControls,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => downloadFile(
                    url: widget.videoUrl,
                    defaultFilename: 'style_dna_${DateTime.now().millisecondsSinceEpoch}.mp4',
                    context: context,
                  ),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.download,
                          color: Colors.white70, size: 16),
                    ),
                  ),
                ),
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(
                begin: const Offset(1.02, 1.02),
                end: const Offset(1, 1),
                duration: 800.ms,
                curve: Curves.easeOutCubic,
              ),
        ],
      ),
    );
  }
}
