import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/news_article.dart';

/// A news source feed.
class NewsFeed {
  final String name;
  final String url;
  const NewsFeed(this.name, this.url);
}

/// Fetches and parses RSS/Atom feeds for the Discover tab. Curated, free
/// sources (no API key) covering Pakistan, World, Education and Technology.
/// Results are merged, de-duplicated and sorted newest-first, with a short
/// in-memory cache so switching tabs doesn't re-hit the network constantly.
class NewsService {
  static final NewsService _instance = NewsService._internal();
  factory NewsService() => _instance;
  NewsService._internal();

  /// Category → list of source feeds.
  static const Map<String, List<NewsFeed>> feeds = {
    'Pakistan': [
      NewsFeed('Dawn', 'https://www.dawn.com/feeds/home'),
      NewsFeed('ProPakistani', 'https://propakistani.pk/feed/'),
      NewsFeed('The Express Tribune', 'https://tribune.com.pk/feed/'),
    ],
    'World': [
      NewsFeed('BBC World', 'https://feeds.bbci.co.uk/news/world/rss.xml'),
      NewsFeed('Al Jazeera', 'https://www.aljazeera.com/xml/rss/all.xml'),
    ],
    'Education': [
      NewsFeed('BBC Education', 'https://feeds.bbci.co.uk/news/education/rss.xml'),
      NewsFeed('Edutopia', 'https://www.edutopia.org/rss.xml'),
    ],
    'Technology': [
      NewsFeed('TechCrunch', 'https://techcrunch.com/feed/'),
      NewsFeed('The Verge', 'https://www.theverge.com/rss/index.xml'),
      NewsFeed('Wired', 'https://www.wired.com/feed/rss'),
    ],
  };

  /// Ordered category tabs. "Top Stories" blends a few from every category.
  static const List<String> categories = [
    'Top Stories',
    'Pakistan',
    'World',
    'Education',
    'Technology',
  ];

  final Map<String, List<NewsArticle>> _cache = {};
  final Map<String, DateTime> _cacheTime = {};
  static const Duration _cacheTtl = Duration(minutes: 15);

  /// Fetch articles for a category. Pass [forceRefresh] to bypass the cache.
  Future<List<NewsArticle>> fetch(
    String category, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _isFresh(category)) {
      return _cache[category]!;
    }

    final List<NewsFeed> sources;
    if (category == 'Top Stories') {
      // One or two feeds from each category for a varied front page.
      sources = [
        feeds['Pakistan']!.first,
        feeds['World']!.first,
        feeds['Education']!.first,
        feeds['Technology']!.first,
      ];
    } else {
      sources = feeds[category] ?? const [];
    }

    final results = await Future.wait(
      sources.map((f) => _fetchFeed(f, category)),
    );

    final articles = results.expand((e) => e).toList();

    // De-duplicate by link, then sort newest-first.
    final seen = <String>{};
    final deduped = <NewsArticle>[];
    for (final a in articles) {
      if (a.link.isNotEmpty && seen.add(a.link)) deduped.add(a);
    }
    deduped.sort((a, b) {
      final da = a.publishedAt, db = b.publishedAt;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });

    if (deduped.isNotEmpty) {
      _cache[category] = deduped;
      _cacheTime[category] = DateTime.now();
    }
    return deduped;
  }

  bool _isFresh(String category) {
    final t = _cacheTime[category];
    return t != null &&
        _cache[category] != null &&
        DateTime.now().difference(t) < _cacheTtl;
  }

  Future<List<NewsArticle>> _fetchFeed(NewsFeed feed, String category) async {
    try {
      final response = await http
          .get(
            Uri.parse(feed.url),
            headers: {
              'User-Agent': 'StudyZone/1.0 (Android)',
              'Accept': 'application/rss+xml, application/xml, text/xml',
            },
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) return const [];
      return _parse(response.body, feed, category);
    } on TimeoutException {
      return const [];
    } on SocketException {
      return const [];
    } catch (e) {
      debugPrint('[NewsService] ${feed.name} failed: $e');
      return const [];
    }
  }

  List<NewsArticle> _parse(String body, NewsFeed feed, String category) {
    final XmlDocument doc;
    try {
      doc = XmlDocument.parse(body);
    } catch (_) {
      return const [];
    }

    // RSS 2.0 → <item>, Atom → <entry>
    final items = doc.findAllElements('item').toList();
    if (items.isNotEmpty) {
      return items
          .map((e) => _parseRssItem(e, feed, category))
          .whereType<NewsArticle>()
          .toList();
    }
    final entries = doc.findAllElements('entry').toList();
    return entries
        .map((e) => _parseAtomEntry(e, feed, category))
        .whereType<NewsArticle>()
        .toList();
  }

  NewsArticle? _parseRssItem(XmlElement item, NewsFeed feed, String category) {
    final title = _text(item, 'title');
    final link = _text(item, 'link');
    if (title.isEmpty || link.isEmpty) return null;

    final description = _text(item, 'description');
    final content = _firstText(item, ['content:encoded', 'encoded']);
    final image = _extractImage(item, '$description $content');
    final pub = _parseDate(_firstText(item, ['pubDate', 'dc:date', 'date']));

    return NewsArticle(
      title: _clean(title),
      link: link.trim(),
      source: feed.name,
      category: category,
      imageUrl: image,
      summary: _stripHtml(description.isNotEmpty ? description : content),
      publishedAt: pub,
    );
  }

  NewsArticle? _parseAtomEntry(
    XmlElement entry,
    NewsFeed feed,
    String category,
  ) {
    final title = _text(entry, 'title');
    // Atom link is in <link href="..."/>; prefer rel="alternate".
    String link = '';
    for (final l in entry.findElements('link')) {
      final rel = l.getAttribute('rel');
      final href = l.getAttribute('href');
      if (href == null) continue;
      if (rel == null || rel == 'alternate') {
        link = href;
        break;
      }
      link = href;
    }
    if (title.isEmpty || link.isEmpty) return null;

    final summary = _firstText(entry, ['summary', 'content']);
    final image = _extractImage(entry, summary);
    final pub = _parseDate(_firstText(entry, ['updated', 'published']));

    return NewsArticle(
      title: _clean(title),
      link: link.trim(),
      source: feed.name,
      category: category,
      imageUrl: image,
      summary: _stripHtml(summary),
      publishedAt: pub,
    );
  }

  // ---- helpers ----------------------------------------------------------

  String _text(XmlElement parent, String name) {
    final el = parent.findElements(name).firstOrNull;
    return el?.innerText.trim() ?? '';
  }

  String _firstText(XmlElement parent, List<String> names) {
    for (final n in names) {
      // Match by local name to tolerate namespace prefixes.
      final el = parent.descendants
          .whereType<XmlElement>()
          .firstWhereOrNull(
        (e) => e.name.qualified == n || e.name.local == n.split(':').last,
      );
      if (el != null && el.innerText.trim().isNotEmpty) {
        return el.innerText.trim();
      }
    }
    return '';
  }

  /// Pull an image URL from media:* tags, an enclosure, or the first <img>.
  String? _extractImage(XmlElement item, String htmlFallback) {
    // media:content / media:thumbnail with a url attribute
    for (final e in item.descendants.whereType<XmlElement>()) {
      final local = e.name.local;
      if (local == 'content' || local == 'thumbnail') {
        final url = e.getAttribute('url');
        if (url != null && _looksLikeImage(url, e.getAttribute('type'))) {
          return url;
        }
      }
      if (local == 'enclosure') {
        final url = e.getAttribute('url');
        final type = e.getAttribute('type');
        if (url != null && _looksLikeImage(url, type)) return url;
      }
    }
    // First <img src="..."> inside the HTML description/content.
    final match = RegExp(
      r'''<img[^>]+src=["']([^"']+)["']''',
      caseSensitive: false,
    ).firstMatch(htmlFallback);
    return match?.group(1);
  }

  bool _looksLikeImage(String url, String? type) {
    if (type != null && type.startsWith('image')) return true;
    final u = url.toLowerCase();
    return u.endsWith('.jpg') ||
        u.endsWith('.jpeg') ||
        u.endsWith('.png') ||
        u.endsWith('.webp') ||
        u.contains('.jpg') ||
        u.contains('.jpeg') ||
        u.contains('.png');
  }

  String _clean(String s) =>
      _stripHtml(s).replaceAll(RegExp(r'\s+'), ' ').trim();

  String _stripHtml(String s) {
    var out = s.replaceAll(RegExp(r'<[^>]*>'), ' ');
    out = out
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&hellip;', '…');
    return out.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  DateTime? _parseDate(String raw) {
    if (raw.isEmpty) return null;
    // Atom/ISO-8601 first.
    final iso = DateTime.tryParse(raw);
    if (iso != null) return iso.toUtc();
    // RFC-822 (RSS pubDate), e.g. "Mon, 05 Jun 2026 10:00:00 GMT".
    try {
      return HttpDate.parse(raw).toUtc();
    } catch (_) {
      return null;
    }
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }

  E? firstWhereOrNull(bool Function(E) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
