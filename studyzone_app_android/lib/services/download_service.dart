import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/content_model.dart';

/// Model for downloaded items
class DownloadedItem {
  final int contentId;
  final String title;
  final String contentType;
  final String localPath;
  final String originalUrl;
  final DateTime downloadedAt;
  final int fileSize;
  final String userId; // user ID of user who downloaded this

  DownloadedItem({
    required this.contentId,
    required this.title,
    required this.contentType,
    required this.localPath,
    required this.originalUrl,
    required this.downloadedAt,
    this.fileSize = 0,
    required this.userId,
  });

  factory DownloadedItem.fromJson(Map<String, dynamic> json) {
    return DownloadedItem(
      contentId: (json['content_id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      contentType: json['content_type']?.toString() ?? '',
      localPath: json['local_path']?.toString() ?? '',
      originalUrl: json['original_url']?.toString() ?? '',
      downloadedAt:
          DateTime.tryParse(json['downloaded_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
      userId:
          json['user_id']?.toString() ?? '', // Handle legacy downloads
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content_id': contentId,
      'title': title,
      'content_type': contentType,
      'local_path': localPath,
      'original_url': originalUrl,
      'downloaded_at': downloadedAt.toIso8601String(),
      'file_size': fileSize,
      'user_id': userId,
    };
  }

  factory DownloadedItem.fromContent(
    ContentModel content,
    String localPath,
    int fileSize,
    String userId,
  ) {
    return DownloadedItem(
      contentId: content.id,
      title: content.title,
      contentType: content.contentType,
      localPath: localPath,
      originalUrl: content.backblazeUrl,
      downloadedAt: DateTime.now(),
      fileSize: fileSize,
      userId: userId,
    );
  }
}

/// Service for managing downloaded files in app's private storage
/// Downloads are organized by user user ID for multi-account support
class DownloadService {
  static const String _downloadedItemsKey = 'downloaded_items';

  SharedPreferences? _prefs;

  Future<void> _init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get base downloads directory
  Future<Directory> _getDownloadsBaseDir() async {
    final dir = await getApplicationDocumentsDirectory();
    return Directory('${dir.path}/downloads');
  }

  /// Get download directory for a specific user (by user ID)
  Future<Directory> getUserDownloadDir(String userId) async {
    final baseDir = await _getDownloadsBaseDir();
    final userDir = Directory('${baseDir.path}/$userId');
    if (!await userDir.exists()) {
      await userDir.create(recursive: true);
    }
    return userDir;
  }

  /// Get audio download directory for a specific user
  Future<Directory> getUserAudioDir(String userId) async {
    final userDir = await getUserDownloadDir(userId);
    final audioDir = Directory('${userDir.path}/audio');
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    return audioDir;
  }

  /// Get PDF download directory for a specific user
  Future<Directory> getUserPdfDir(String userId) async {
    final userDir = await getUserDownloadDir(userId);
    final pdfDir = Directory('${userDir.path}/pdf');
    if (!await pdfDir.exists()) {
      await pdfDir.create(recursive: true);
    }
    return pdfDir;
  }

  /// Get all downloaded items (all users)
  Future<List<DownloadedItem>> getAllDownloads() async {
    await _init();
    final jsonStr = _prefs!.getString(_downloadedItemsKey);
    if (jsonStr == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      final List<DownloadedItem> items = [];
      for (final e in jsonList) {
        try {
          items.add(DownloadedItem.fromJson(e as Map<String, dynamic>));
        } catch (_) {
          // Skip corrupt/legacy entries instead of breaking the whole list
        }
      }
      return items;
    } catch (_) {
      // Top-level decode failed; treat as no downloads
      return [];
    }
  }

  /// Get downloaded audio files for a specific user (by user ID)
  Future<List<DownloadedItem>> getDownloadedAudioForUser(String userId) async {
    final all = await getAllDownloads();
    return all
        .where(
          (item) =>
              item.contentType.toLowerCase() == 'audio' &&
              item.userId == userId,
        )
        .toList();
  }

  /// Get downloaded PDF files for a specific user (by user ID)
  Future<List<DownloadedItem>> getDownloadedPDFsForUser(String userId) async {
    final all = await getAllDownloads();
    return all
        .where(
          (item) =>
              item.contentType.toLowerCase() == 'pdf' &&
              item.userId == userId,
        )
        .toList();
  }

  /// Get all downloads for a specific user (by user ID)
  Future<List<DownloadedItem>> getDownloadsForUser(String userId) async {
    final all = await getAllDownloads();
    return all.where((item) => item.userId == userId).toList();
  }

  /// Check if content is downloaded by a specific user
  Future<bool> isDownloadedByUser(int contentId, String userId) async {
    final all = await getAllDownloads();
    return all.any(
      (item) => item.contentId == contentId && item.userId == userId,
    );
  }

  /// Check if content is downloaded (by any user - for backward compatibility)
  Future<bool> isDownloaded(int contentId) async {
    final all = await getAllDownloads();
    return all.any((item) => item.contentId == contentId);
  }

  /// Get downloaded item by content ID for a specific user
  Future<DownloadedItem?> getDownloadedItemForUser(
    int contentId,
    String userId,
  ) async {
    final all = await getAllDownloads();
    try {
      return all.firstWhere(
        (item) => item.contentId == contentId && item.userId == userId,
      );
    } catch (_) {
      return null;
    }
  }

  /// Get downloaded item by content ID (any user - for backward compatibility)
  Future<DownloadedItem?> getDownloadedItem(int contentId) async {
    final all = await getAllDownloads();
    try {
      return all.firstWhere((item) => item.contentId == contentId);
    } catch (_) {
      return null;
    }
  }

  /// Save download record
  Future<void> saveDownload(DownloadedItem item) async {
    await _init();
    final all = await getAllDownloads();

    // Remove existing if any (same content, same user)
    all.removeWhere(
      (i) => i.contentId == item.contentId && i.userId == item.userId,
    );
    all.add(item);

    final jsonStr = jsonEncode(all.map((e) => e.toJson()).toList());
    await _prefs!.setString(_downloadedItemsKey, jsonStr);
  }

  /// Remove download record for a specific user
  Future<void> removeDownloadForUser(int contentId, String userId) async {
    await _init();
    final all = await getAllDownloads();

    // Find and delete the actual file
    final item = all
        .where((i) => i.contentId == contentId && i.userId == userId)
        .firstOrNull;

    if (item != null) {
      try {
        final file = File(item.localPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }

    // Remove from records
    all.removeWhere((i) => i.contentId == contentId && i.userId == userId);

    final jsonStr = jsonEncode(all.map((e) => e.toJson()).toList());
    await _prefs!.setString(_downloadedItemsKey, jsonStr);
  }

  /// Remove download record (legacy - removes first match)
  Future<void> removeDownload(int contentId) async {
    await _init();
    final all = await getAllDownloads();
    all.removeWhere((i) => i.contentId == contentId);

    final jsonStr = jsonEncode(all.map((e) => e.toJson()).toList());
    await _prefs!.setString(_downloadedItemsKey, jsonStr);
  }

  /// Clear all downloads for a specific user only
  Future<void> clearDownloadsForUser(String userId) async {
    await _init();

    // Get downloads for this user and delete files
    final userDownloads = await getDownloadsForUser(userId);
    for (final item in userDownloads) {
      try {
        final file = File(item.localPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // Ignore errors with individual files
      }
    }

    // Delete user's download directory
    try {
      final userDir = await getUserDownloadDir(userId);
      if (await userDir.exists()) {
        await userDir.delete(recursive: true);
      }
    } catch (e) {
      // Ignore directory deletion errors
    }

    // Remove only this user's records from the list
    final all = await getAllDownloads();
    all.removeWhere((i) => i.userId == userId);
    final jsonStr = jsonEncode(all.map((e) => e.toJson()).toList());
    await _prefs!.setString(_downloadedItemsKey, jsonStr);
  }

  // ── Network download ───────────────────────────────────────────────────────

  /// A Dio configured for downloading media from ARBITRARY hosts (not just
  /// Backblaze). A browser-like User-Agent is the key fix: many CDNs/WAFs
  /// reject the default Dart agent and reset the TLS connection — which the
  /// user sees as a "handshake failed"/download error. Also follows redirects
  /// (http→https, signed-URL hops) and uses generous timeouts for large files.
  static Dio _buildDio() => Dio(
        BaseOptions(
          followRedirects: true,
          maxRedirects: 5,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 10),
          sendTimeout: const Duration(seconds: 30),
          headers: const {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 12) AppleWebKit/537.36 '
                '(KHTML, like Gecko) StudyZone/1.0 Mobile',
            'Accept': '*/*',
          },
          // Accept 2xx and 3xx so redirects/ranges are handled, not thrown.
          validateStatus: (s) => s != null && s >= 200 && s < 400,
        ),
      );

  /// Choose a file extension from the URL path first (so a host serving
  /// .m4a/.webm/.mov/.png is saved correctly), falling back to the content type.
  String _extensionFor(ContentModel content) {
    final path = Uri.tryParse(content.safeMediaUrl)?.path ?? '';
    final lastSlash = path.lastIndexOf('/');
    final lastDot = path.lastIndexOf('.');
    if (lastDot != -1 && lastDot > lastSlash) {
      final ext = path.substring(lastDot);
      if (ext.length <= 6 && !ext.contains('%')) return ext.toLowerCase();
    }
    switch (content.contentType.toLowerCase()) {
      case 'pdf':
        return '.pdf';
      case 'audio':
        return '.mp3';
      case 'video':
        return '.mp4';
      case 'ppt':
        return '.pptx';
      case 'doc':
        return '.docx';
      case 'image':
        return '.jpg';
      case 'zip':
        return '.zip';
      default:
        return '';
    }
  }

  Future<Directory> _dirForContent(ContentModel content, String userId) {
    switch (content.contentType.toLowerCase()) {
      case 'audio':
        return getUserAudioDir(userId);
      case 'pdf':
        return getUserPdfDir(userId);
      default:
        return getUserDownloadDir(userId);
    }
  }

  /// Download a content item to per-user private storage, record it, and return
  /// the saved item. Works for any absolute http(s) URL. On failure the partial
  /// file is removed and the error is rethrown for the caller to surface.
  Future<DownloadedItem> downloadContent(
    ContentModel content,
    String userId, {
    void Function(int received, int total)? onProgress,
  }) async {
    final dir = await _dirForContent(content, userId);
    final ext = _extensionFor(content);
    final filePath =
        '${dir.path}/${content.id}_${DateTime.now().millisecondsSinceEpoch}$ext';
    final file = File(filePath);

    try {
      final dio = _buildDio();
      await dio.download(
        content.safeMediaUrl,
        filePath,
        onReceiveProgress: onProgress,
      );
      final size = await file.length();
      final item = DownloadedItem.fromContent(content, filePath, size, userId);
      await saveDownload(item);
      return item;
    } catch (e) {
      // Don't leave a truncated file behind — something could later open it.
      try {
        if (await file.exists()) await file.delete();
      } catch (_) {}
      rethrow;
    }
  }

  /// A human, actionable message for a download/stream failure.
  static String describeError(Object e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return 'Connection timed out. Please try again.';
        case DioExceptionType.badCertificate:
          return 'Secure connection (TLS) failed for this host.';
        case DioExceptionType.connectionError:
          return 'Could not reach the server. Check your connection.';
        case DioExceptionType.badResponse:
          return 'Server error ${e.response?.statusCode ?? ''}.'.trim();
        default:
          return 'Download failed. Please try again.';
      }
    }
    return 'Download failed. Please try again.';
  }
}
