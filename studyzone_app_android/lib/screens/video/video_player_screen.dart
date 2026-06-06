import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../config/app_theme.dart';
import '../../models/content_model.dart';
import '../../widgets/common/screen_header.dart';
import '../../widgets/common/study_zone_app_bar.dart';

/// Plays a video content item. Three sources, picked automatically:
///  - a downloaded local file ([localPath]) → video_player/chewie,
///  - a YouTube link → the in-app YouTube IFrame player,
///  - any other absolute URL (MP4/HLS on any host) → video_player/chewie.
class VideoPlayerScreen extends StatefulWidget {
  final ContentModel content;
  final String? localPath;

  const VideoPlayerScreen({super.key, required this.content, this.localPath});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  YoutubePlayerController? _ytController;
  bool _initializing = true;
  String? _error;

  /// Stream a YouTube link only when it isn't a downloaded file.
  bool get _isYoutube => widget.localPath == null && widget.content.isYoutube;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // YouTube link → in-app IFrame player (there is no direct media file).
    if (_isYoutube) {
      _ytController = YoutubePlayerController(
        initialVideoId: widget.content.youtubeId!,
        flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
      );
      if (mounted) setState(() => _initializing = false);
      return;
    }

    // Guard: streaming a remote video needs a valid absolute http(s) URL.
    if (widget.localPath == null && !widget.content.hasPlayableUrl) {
      if (mounted) {
        setState(() {
          _initializing = false;
          _error = 'This video has no valid URL.';
        });
      }
      return;
    }

    try {
      final controller = widget.localPath != null
          ? VideoPlayerController.file(File(widget.localPath!))
          : VideoPlayerController.networkUrl(
              Uri.parse(widget.content.safeMediaUrl),
              // Browser-like UA so non-Backblaze CDNs/WAFs don't reject the
              // stream (same fix as the download/audio paths).
              httpHeaders: const {
                'User-Agent':
                    'Mozilla/5.0 (Linux; Android 12) StudyZone/1.0 Mobile',
              },
            );
      _videoController = controller;
      await controller.initialize();

      _chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        aspectRatio: controller.value.aspectRatio == 0
            ? 16 / 9
            : controller.value.aspectRatio,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
        ),
        errorBuilder: (context, msg) => Center(
          child: Text(msg, style: const TextStyle(color: Colors.white70)),
        ),
      );
      if (mounted) setState(() => _initializing = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _initializing = false;
          _error = 'Could not play this video.';
        });
      }
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    _ytController?.dispose();
    super.dispose();
  }

  Future<void> _openExternally() async {
    final uri = Uri.tryParse(widget.content.safeMediaUrl);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    // YouTube path — wrapped in YoutubePlayerBuilder so fullscreen/orientation
    // work, with an "Open in YouTube" fallback for embedding-restricted videos.
    if (_ytController != null) {
      return YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: _ytController!,
          progressIndicatorColor: AppColors.primary,
          progressColors: ProgressBarColors(
            playedColor: AppColors.primary,
            handleColor: AppColors.primary,
          ),
        ),
        builder: (context, player) => Scaffold(
          backgroundColor: colors.background,
          appBar: const StudyZoneAppBar(),
          body: Column(
            children: [
              ScreenHeader(title: widget.content.title),
              Divider(height: 1, color: colors.border),
              Container(color: Colors.black, child: player),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _openExternally,
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Open in YouTube'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      appBar: const StudyZoneAppBar(),
      body: Column(
        children: [
          ScreenHeader(title: widget.content.title),
          Divider(height: 1, color: colors.border),
          Expanded(
            child: Container(
              color: Colors.black,
              alignment: Alignment.center,
              child: _buildPlayer(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayer() {
    if (_initializing) {
      return const CircularProgressIndicator(color: Colors.white);
    }
    if (_error != null || _chewieController == null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error ?? 'Unable to load video.',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            // Offer an external-open escape hatch for a valid-but-unplayable URL.
            if (widget.localPath == null && widget.content.hasPlayableUrl) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _openExternally,
                icon: const Icon(Icons.open_in_new, size: 18, color: Colors.white70),
                label: const Text(
                  'Open in browser',
                  style: TextStyle(color: Colors.white70),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                ),
              ),
            ],
          ],
        ),
      );
    }
    return AspectRatio(
      aspectRatio: _chewieController!.aspectRatio ?? 16 / 9,
      child: Chewie(controller: _chewieController!),
    );
  }
}
