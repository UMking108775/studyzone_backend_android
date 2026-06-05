import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/content_model.dart';
import '../../providers/auth_provider.dart';
import '../../screens/audio/audio_player_screen.dart';
import '../../services/audio_service.dart';
import '../../services/download_service.dart';
import '../../widgets/audio/mini_player.dart';
import '../../widgets/common/study_zone_app_bar.dart';

/// Screen showing downloaded audio files for the current user
class MyDownloadedAudioScreen extends StatefulWidget {
  const MyDownloadedAudioScreen({super.key});

  @override
  State<MyDownloadedAudioScreen> createState() =>
      _MyDownloadedAudioScreenState();
}

class _MyDownloadedAudioScreenState extends State<MyDownloadedAudioScreen> {
  final DownloadService _downloadService = DownloadService();
  List<DownloadedItem> _downloads = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  Future<void> _loadDownloads() async {
    setState(() => _isLoading = true);

    // Get current user's user ID
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.user;

    if (currentUser == null) {
      // Not logged in - show empty
      setState(() {
        _downloads = [];
        _isLoading = false;
        _currentUserId = null;
      });
      return;
    }

    _currentUserId = currentUser.storageKey;

    // Get downloads for this user only (filtered by user ID)
    final downloads = await _downloadService.getDownloadedAudioForUser(
      currentUser.storageKey,
    );

    setState(() {
      _downloads = downloads;
      _isLoading = false;
    });
  }

  Future<void> _deleteDownload(DownloadedItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colors = AppColors.of(context);
        return AlertDialog(
          backgroundColor: colors.surface,
          title: Text(
            'Delete Download',
            style: TextStyle(color: colors.textPrimary),
          ),
          content: Text(
            'Delete "${item.title}"?',
            style: TextStyle(color: colors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: colors.error),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && _currentUserId != null) {
      try {
        final file = File(item.localPath);
        if (await file.exists()) await file.delete();
      } catch (_) {}
      await _downloadService.removeDownloadForUser(
        item.contentId,
        _currentUserId!,
      );
      await _loadDownloads();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download deleted'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  void _playAudio(DownloadedItem item, int index) {
    final playlist = _downloads
        .map(
          (d) => ContentModel(
            id: d.contentId,
            title: d.title,
            contentType: d.contentType,
            backblazeUrl: d.originalUrl,
            isActive: true,
            createdAt: d.downloadedAt,
            updatedAt: d.downloadedAt,
          ),
        )
        .toList();
    final localPaths = _downloads.map((d) => d.localPath).toList();
    final audioService = context.read<AudioService>();
    audioService.initPlaylist(playlist, index, localPaths: localPaths);
    audioService.play();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AudioPlayerScreen()),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: const StudyZoneAppBar(),
      body: Column(
            children: [
              // Section header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: [
                    // Icon and title
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00ACC1), Color(0xFF4DD0E1)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.audiotrack,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Audio',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            '${_downloads.length} files offline',
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _downloads.isEmpty
                    ? _buildEmptyState()
                    : _buildList(),
              ),
              const MiniPlayer(),
            ],
          ),
    );
  }

  Widget _buildEmptyState() {
    final colors = AppColors.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.audiotrack_outlined,
              size: 28,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No Downloads',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Download audio to listen offline',
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final colors = AppColors.of(context);

    return RefreshIndicator(
      onRefresh: _loadDownloads,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _downloads.length,
        itemBuilder: (context, index) {
          final item = _downloads[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.border, width: 0.5),
            ),
            child: InkWell(
              onTap: () => _playAudio(item, index),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00ACC1).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.audiotrack,
                        color: Color(0xFF00ACC1),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatFileSize(item.fileSize),
                            style: TextStyle(
                              fontSize: 10,
                              color: colors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.play_circle_fill, size: 26),
                      color: colors.primary,
                      onPressed: () => _playAudio(item, index),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      color: colors.error,
                      onPressed: () => _deleteDownload(item),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
