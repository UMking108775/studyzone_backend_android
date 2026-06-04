import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

/// A single education news article.
class NewsItem {
  final String title;
  final String link;
  final String source;
  final DateTime? published;

  NewsItem({
    required this.title,
    required this.link,
    required this.source,
    this.published,
  });
}

/// Fetches Pakistan education news from Google News RSS.
///
/// Free, no API key required. Google News RSS returns an XML feed which we
/// parse into [NewsItem]s. Results are cached in memory for a short time so
/// we don't hit the network on every home rebuild.
class NewsService {
  NewsService._();
  static final NewsService instance = NewsService._();

  static const String _feedUrl =
      'https://news.google.com/rss/search?q=Pakistan+education+OR+university+OR+exams&hl=en-PK&gl=PK&ceid=PK:en';

  List<NewsItem>? _cache;
  DateTime? _cachedAt;

  Future<List<NewsItem>> fetchEducationNews({bool forceRefresh = false}) async {
    // Serve from memory cache for 30 minutes.
    if (!forceRefresh &&
        _cache != null &&
        _cachedAt != null &&
        DateTime.now().difference(_cachedAt!).inMinutes < 30) {
      return _cache!;
    }

    try {
      final resp = await http
          .get(Uri.parse(_feedUrl))
          .timeout(const Duration(seconds: 12));
      if (resp.statusCode != 200) return _cache ?? [];

      final doc = XmlDocument.parse(resp.body);
      final items = doc.findAllElements('item').take(10).map((node) {
        String tag(String name) {
          final els = node.findElements(name);
          return els.isEmpty ? '' : els.first.innerText.trim();
        }

        // Google News titles look like "Headline - The Source".
        var title = tag('title');
        var source = tag('source');
        if (source.isEmpty && title.contains(' - ')) {
          final idx = title.lastIndexOf(' - ');
          source = title.substring(idx + 3).trim();
          title = title.substring(0, idx).trim();
        }

        DateTime? published;
        final pub = tag('pubDate');
        if (pub.isNotEmpty) {
          try {
            published = _parseRfc822(pub);
          } catch (_) {}
        }

        return NewsItem(
          title: title,
          link: tag('link'),
          source: source,
          published: published,
        );
      }).where((n) => n.title.isNotEmpty && n.link.isNotEmpty).toList();

      _cache = items;
      _cachedAt = DateTime.now();
      return items;
    } catch (_) {
      return _cache ?? [];
    }
  }

  /// Parse an RFC-822 date like "Tue, 02 Jun 2026 10:30:00 GMT".
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
