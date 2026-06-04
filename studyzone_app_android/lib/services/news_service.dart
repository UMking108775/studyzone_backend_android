import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

/// A single education news article.
class NewsItem {
  final String title;
  final String link;
  final String source;
  final String? imageUrl;
  final String description;
  final DateTime? published;

  NewsItem({
    required this.title,
    required this.link,
    required this.source,
    required this.imageUrl,
    required this.description,
    this.published,
  });
}

/// Fetches Pakistan education news from Dawn's RSS feed.
///
/// Free, no API key required. Dawn's feed gives direct article links AND image
/// URLs (media:content / media:thumbnail), so cards can show real thumbnails
/// and articles open inside the app. Education-relevant items are prioritised.
class NewsService {
  NewsService._();
  static final NewsService instance = NewsService._();

  static const String _feedUrl = 'https://www.dawn.com/feeds/home';

  static const List<String> _eduKeywords = [
    'education',
    'university',
    'universities',
    'exam',
    'exams',
    'paper',
    'papers',
    'past paper',
    'datesheet',
    'date sheet',
    'student',
    'students',
    'college',
    'school',
    'schools',
    'hec',
    'admission',
    'admissions',
    'degree',
    'scholarship',
    'scholarships',
    'campus',
    'teacher',
    'teachers',
    'academic',
    'matric',
    'matriculation',
    'intermediate',
    'inter',
    'fsc',
    'result',
    'results',
    'syllabus',
    'curriculum',
    'board',
    'class',
    'lecture',
    'fee',
    'fees',
    'merit',
    'enrollment',
    'semester',
    'institute',
    'faculty',
    'tuition',
    'pec',
    'nts',
    'fpsc',
    'ppsc',
    'olevel',
    'o level',
    'a level',
    'cambridge',
  ];

  List<NewsItem>? _cache;
  DateTime? _cachedAt;

  Future<List<NewsItem>> fetchEducationNews({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cache != null &&
        _cachedAt != null &&
        DateTime.now().difference(_cachedAt!).inMinutes < 30) {
      return _cache!;
    }

    try {
      final resp = await http
          .get(Uri.parse(_feedUrl), headers: {'User-Agent': 'Mozilla/5.0'})
          .timeout(const Duration(seconds: 14));
      if (resp.statusCode != 200) return _cache ?? [];

      final doc = XmlDocument.parse(resp.body);
      final all = doc.findAllElements('item').map(_parseItem).toList();

      // Education-relevant first, then the rest, capped to a tidy grid.
      bool isEdu(NewsItem n) {
        final hay = '${n.title} ${n.description}'.toLowerCase();
        return _eduKeywords.any(hay.contains);
      }

      final edu = all.where(isEdu).toList();
      final rest = all.where((n) => !isEdu(n)).toList();
      final ordered = [...edu, ...rest]
          .where((n) => n.title.isNotEmpty && n.link.isNotEmpty)
          .take(9)
          .toList();

      _cache = ordered;
      _cachedAt = DateTime.now();
      return ordered;
    } catch (_) {
      return _cache ?? [];
    }
  }

  NewsItem _parseItem(XmlElement node) {
    String tag(String name) {
      final els = node.findElements(name);
      return els.isEmpty ? '' : els.first.innerText.trim();
    }

    // Image: prefer the large media:content image, fall back to thumbnail.
    String? image;
    for (final e in node.findAllElements('content', namespace: '*')) {
      final medium = e.getAttribute('medium');
      final type = e.getAttribute('type') ?? '';
      if (medium == 'image' || type.startsWith('image')) {
        final url = e.getAttribute('url');
        if (url != null && url.isNotEmpty) {
          image = url;
          break;
        }
      }
    }
    if (image == null) {
      for (final e in node.findAllElements('thumbnail', namespace: '*')) {
        final url = e.getAttribute('url');
        if (url != null && url.isNotEmpty) {
          image = url;
          break;
        }
      }
    }

    DateTime? published;
    final pub = tag('pubDate');
    if (pub.isNotEmpty) {
      try {
        published = _parseRfc822(pub);
      } catch (_) {}
    }

    return NewsItem(
      title: _clean(tag('title')),
      link: tag('link'),
      source: 'Dawn',
      imageUrl: image,
      description: _clean(tag('description')),
      published: published,
    );
  }

  /// Strip HTML tags and decode a few common entities for a plain snippet.
  String _clean(String input) {
    var s = input.replaceAll(RegExp(r'<[^>]*>'), ' ');
    s = s
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  DateTime? _parseRfc822(String input) {
    const months = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };
    final parts = input.split(' ');
    if (parts.length < 5) return null;
    final day = int.tryParse(parts[1]);
    final month = months[parts[2]];
    final year = int.tryParse(parts[3]);
    final time = parts[4].split(':');
    if (day == null || month == null || year == null || time.length < 2) {
      return null;
    }
    return DateTime.utc(
      year,
      month,
      day,
      int.tryParse(time[0]) ?? 0,
      int.tryParse(time[1]) ?? 0,
    );
  }
}
