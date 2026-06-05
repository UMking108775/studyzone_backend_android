import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../config/app_theme.dart';
import '../../models/news_article.dart';
import '../../services/news_service.dart';
import 'news_article_screen.dart';

/// Discover tab: a magazine-style feed of education, technology and world news
/// (incl. Pakistan), pulled live from curated RSS sources. Category chips on
/// top; a featured hero, a horizontal "top picks" rail and a two-column grid
/// below — like a news/blog site.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final NewsService _service = NewsService();
  String _category = NewsService.categories.first;
  bool _loading = true;
  String? _error;
  List<NewsArticle> _articles = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _service.fetch(_category, forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        _articles = list;
        _loading = false;
        _error = list.isEmpty ? 'No articles available right now.' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load news. Pull to retry.';
      });
    }
  }

  void _selectCategory(String c) {
    if (c == _category) return;
    setState(() => _category = c);
    _load();
  }

  void _open(NewsArticle article) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NewsArticleScreen(article: article)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Column(
      children: [
        _CategoryBar(
          categories: NewsService.categories,
          selected: _category,
          onSelect: _selectCategory,
        ),
        Expanded(
          child: RefreshIndicator(
            color: colors.primary,
            onRefresh: () => _load(forceRefresh: true),
            child: _buildBody(colors),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(ThemeColors colors) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_articles.isEmpty) {
      return ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.newspaper, size: 56, color: colors.textHint),
                    const SizedBox(height: 14),
                    Text(
                      _error ?? 'No articles',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _load(forceRefresh: true),
                      icon: const Icon(LucideIcons.refresh_cw, size: 16),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    final hero = _articles.first;
    final rail = _articles.skip(1).take(5).toList();
    final grid = _articles.skip(6).toList();

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Featured hero
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: _HeroCard(article: hero, onTap: () => _open(hero)),
          ),
        ),

        // Horizontal "Top picks" rail
        if (rail.isNotEmpty) ...[
          _sectionTitle(colors, 'Top picks'),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 210,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: rail.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) => _RailCard(
                  article: rail[i],
                  onTap: () => _open(rail[i]),
                ),
              ),
            ),
          ),
        ],

        // Two-column grid for the rest
        if (grid.isNotEmpty) ...[
          _sectionTitle(colors, 'More stories'),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => _GridCard(
                  article: grid[i],
                  onTap: () => _open(grid[i]),
                ),
                childCount: grid.length,
              ),
            ),
          ),
        ] else
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _sectionTitle(ThemeColors colors, String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// Horizontal category selector chips.
class _CategoryBar extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelect;

  const _CategoryBar({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.border, width: 0.5)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final c = categories[i];
          final active = c == selected;
          return GestureDetector(
            onTap: () => onSelect(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? colors.primary : colors.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                c,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  color: active ? Colors.white : colors.primary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Shared image with graceful fallbacks.
class _NewsImage extends StatelessWidget {
  final String? url;
  final double? height;
  final double? width;
  const _NewsImage({this.url, this.height, this.width});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final placeholder = Container(
      height: height,
      width: width,
      color: colors.primary.withValues(alpha: 0.08),
      child: Icon(LucideIcons.newspaper, color: colors.primary.withValues(alpha: 0.4)),
    );
    if (url == null || url!.isEmpty) return placeholder;
    return CachedNetworkImage(
      imageUrl: url!,
      height: height,
      width: width,
      fit: BoxFit.cover,
      placeholder: (_, _) => placeholder,
      errorWidget: (_, _, _) => placeholder,
    );
  }
}

class _MetaRow extends StatelessWidget {
  final NewsArticle article;
  final Color color;
  const _MetaRow({required this.article, required this.color});

  @override
  Widget build(BuildContext context) {
    final parts = <String>[article.source];
    if (article.publishedAt != null) {
      parts.add(timeago.format(article.publishedAt!));
    }
    return Text(
      parts.join(' · '),
      style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _HeroCard extends StatelessWidget {
  final NewsArticle article;
  final VoidCallback onTap;
  const _HeroCard({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            _NewsImage(url: article.imageUrl, height: 210, width: double.infinity),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.82),
                    ],
                    stops: const [0.35, 0.6, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      article.category.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _MetaRow(article: article, color: Colors.white70),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RailCard extends StatelessWidget {
  final NewsArticle article;
  final VoidCallback onTap;
  const _RailCard({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 240,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _NewsImage(url: article.imageUrl, height: 120, width: 240),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _MetaRow(article: article, color: colors.textSecondary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridCard extends StatelessWidget {
  final NewsArticle article;
  final VoidCallback onTap;
  const _GridCard({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _NewsImage(url: article.imageUrl, height: 100, width: double.infinity),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        article.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _MetaRow(article: article, color: colors.textSecondary),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
