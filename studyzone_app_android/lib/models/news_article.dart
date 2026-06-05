/// A single news/blog article parsed from an RSS or Atom feed.
class NewsArticle {
  final String title;
  final String link;
  final String source;
  final String category;
  final String? imageUrl;
  final String summary;
  final DateTime? publishedAt;

  const NewsArticle({
    required this.title,
    required this.link,
    required this.source,
    required this.category,
    this.imageUrl,
    this.summary = '',
    this.publishedAt,
  });
}
