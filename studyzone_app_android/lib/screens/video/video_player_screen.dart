import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../config/app_theme.dart';
import '../../models/content_model.dart';
import '../../widgets/common/screen_header.dart';
import '../../widgets/common/study_zone_app_bar.dart';

/// Plays a video content item. Streams from [ContentModel.backblazeUrl] or, when
/// [localPath] is provided, plays the downloaded file (offline).
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
  bool _initializing = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final controller = widget.localPath != null
          ? VideoPlayerController.file(File(widget.localPath!))
          : VideoPlayerController.networkUrl(
              Uri.parse(widget.content.backblazeUrl),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
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
        child: Text(
          _error ?? 'Unable to load video.',
          style: const TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      );
    }
    return AspectRatio(
      aspectRatio: _chewieController!.aspectRatio ?? 16 / 9,
      child: Chewie(controller: _chewieController!),
    );
  }
}
