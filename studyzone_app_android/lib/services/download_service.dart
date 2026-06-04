import 'dart:convert';
import 'dart:io';
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
}
