import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../config/app_theme.dart';
import '../../models/content_model.dart';
import '../../services/access_guard.dart';
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

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with ContentAccessGuard {
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
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => guardContentAccess(widget.content),
    );
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
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _openExternally,
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Open in YouTube'),
              ),
              Expanded(child: _buildDetails(colors)),
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
          _videoArea(),
          // Below the player: the optional video description (fills the space
          // that used to be empty). Empty when no description was provided.
          Expanded(child: _buildDetails(colors)),
        ],
      ),
    );
  }

  /// Black video region sized to the video's aspect ratio, but capped in height
  /// so a portrait video doesn't push the description off-screen.
  Widget _videoArea() {
    final media = MediaQuery.of(context);
    final ratio = (_chewieController?.aspectRatio ?? 0) > 0
        ? _chewieController!.aspectRatio!
        : 16 / 9;
    final maxH = media.size.height * 0.45;
    double h = media.size.width / ratio;
    if (h > maxH) h = maxH;
    return Container(
      color: Colors.black,
      width: double.infinity,
      height: h,
      alignment: Alignment.center,
      child: AspectRatio(aspectRatio: ratio, child: _buildPlayer()),
    );
  }

  /// The video's description (stored in `content.body`), shown under the player.
  Widget _buildDetails(ThemeColors colors) {
    final desc = widget.content.body?.trim() ?? '';
    if (desc.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.subject_rounded, size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            desc,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.55,
              color: colors.textSecondary,
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
    return Chewie(controller: _chewieController!);
  }
}
