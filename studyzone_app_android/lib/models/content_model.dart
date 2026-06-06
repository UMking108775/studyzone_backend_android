/// Content/Material model representing study material
class ContentModel {
  final int id;
  final String title;
  final String contentType;
  final String backblazeUrl;
  final String? body;
  final bool isActive;
  final ContentCategory? category;
  final DateTime createdAt;
  final DateTime updatedAt;

  ContentModel({
    required this.id,
    required this.title,
    required this.contentType,
    required this.backblazeUrl,
    this.body,
    required this.isActive,
    this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  /// True for rich-text/article content that carries an HTML [body].
  bool get isRichText =>
      contentType.toLowerCase() == 'rich_text' ||
      contentType.toLowerCase() == 'richtext' ||
      contentType.toLowerCase() == 'article';

  /// True for video content.
  bool get isVideo => contentType.toLowerCase() == 'video';

  /// The media URL, provider-neutral. (Historically named "backblaze" but it is
  /// just an absolute URL that may point to ANY host — Backblaze, S3, a CDN, a
  /// self-hosted server, or YouTube.)
  String get mediaUrl => backblazeUrl;

  /// Media URL safe to request: literal spaces are percent-encoded so an
  /// admin-pasted link with raw spaces (very common for PDF filenames, e.g.
  /// "Lecture No. 1 (Module 1-4).pdf") forms a valid request instead of failing.
  /// Already-encoded sequences (%20) are left untouched — no double-encoding.
  String get safeMediaUrl => backblazeUrl.trim().replaceAll(' ', '%20');

  /// A non-empty absolute http/https URL we can actually stream/download/open.
  bool get hasPlayableUrl {
    final uri = Uri.tryParse(backblazeUrl.trim());
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  static final RegExp _ytId = RegExp(r'^[A-Za-z0-9_-]{11}$');

  /// The 11-char YouTube video id if [backblazeUrl] is a real YouTube link,
  /// else null. Host-validated (so `notyoutube.com`, `fakeyoutu.be`, or a path
  /// that merely contains `youtube.com/embed/…` are NOT treated as YouTube),
  /// and uses the FIRST `v=` param (matching YouTube's own behaviour).
  String? get youtubeId {
    final raw = backblazeUrl.trim();
    if (raw.isEmpty) return null;
    var uri = Uri.tryParse(raw);
    if (uri == null) return null;
    // Tolerate a missing scheme (e.g. "youtu.be/ID") by assuming https.
    if (!uri.hasScheme) uri = Uri.tryParse('https://$raw');
    if (uri == null) return null;

    final host = uri.host.toLowerCase();
    final isYtDotCom = host == 'youtube.com' || host.endsWith('.youtube.com');
    final isYouTuBe = host == 'youtu.be';
    if (!isYtDotCom && !isYouTuBe) return null;

    // youtu.be/<id>
    if (isYouTuBe) {
      final seg = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
      return _ytId.hasMatch(seg) ? seg : null;
    }
    // youtube.com/watch?v=<id> (first v= wins)
    final vs = uri.queryParametersAll['v'];
    if (vs != null && vs.isNotEmpty && _ytId.hasMatch(vs.first)) {
      return vs.first;
    }
    // youtube.com/{embed,shorts,v,live}/<id>
    final segs = uri.pathSegments;
    if (segs.length >= 2 &&
        const {'embed', 'shorts', 'v', 'live'}.contains(segs[0].toLowerCase()) &&
        _ytId.hasMatch(segs[1])) {
      return segs[1];
    }
    return null;
  }

  /// True when this video should be played via the YouTube player.
  bool get isYoutube => youtubeId != null;

  /// Create ContentModel from JSON
  factory ContentModel.fromJson(Map<String, dynamic> json) {
    return ContentModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      contentType: json['content_type']?.toString() ?? '',
      // Tolerant of the provider-neutral keys the backend also emits, so the
      // app keeps working if `backblaze_url` is ever renamed to `media_url`/`url`.
      backblazeUrl:
          (json['media_url'] ?? json['url'] ?? json['backblaze_url'])
              ?.toString() ??
          '',
      body: json['body']?.toString(),
      isActive: json['is_active'] == null ? true : json['is_active'] == true,
      category: json['category'] is Map<String, dynamic>
          ? ContentCategory.fromJson(json['category'])
          : null,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  /// Convert ContentModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content_type': contentType,
      'backblaze_url': backblazeUrl,
      'body': body,
      'is_active': isActive,
      'category': category?.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get icon for content type
  String get typeIcon {
    switch (contentType.toLowerCase()) {
      case 'pdf':
        return '📄';
      case 'video':
        return '📹';
      case 'audio':
        return '🎵';
      case 'ppt':
        return '📊';
      case 'doc':
        return '📝';
      case 'image':
        return '🖼️';
      case 'zip':
        return '📦';
      case 'link':
        return '🔗';
      default:
        return '📁';
    }
  }

  /// Get display name for content type
  String get typeDisplayName {
    switch (contentType.toLowerCase()) {
      case 'pdf':
        return 'PDF Document';
      case 'video':
        return 'Video';
      case 'audio':
        return 'Audio';
      case 'ppt':
        return 'Presentation';
      case 'doc':
        return 'Document';
      case 'image':
        return 'Image';
      case 'zip':
        return 'Archive';
      case 'link':
        return 'Link';
      default:
        return 'File';
    }
  }
}

/// Simplified category info for content
class ContentCategory {
  final int id;
  final String title;
  final int level;

  ContentCategory({required this.id, required this.title, required this.level});

  factory ContentCategory.fromJson(Map<String, dynamic> json) {
    return ContentCategory(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      level: (json['level'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title, 'level': level};
  }
}
