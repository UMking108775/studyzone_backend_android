import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../config/app_theme.dart';
import '../../screens/news/news_detail_screen.dart';
import '../../services/news_service.dart';
import 'section_header.dart';

/// "Education News" section laid out like a news homepage (BBC-style): one large
/// feature story followed by a responsive multi-grid of smaller stories. Each
/// card has a real thumbnail and opens an in-app reader. Hidden if nothing loads.
class EducationNewsSection extends StatefulWidget {
  const EducationNewsSection({super.key});

  @override
  State<EducationNewsSection> createState() => _EducationNewsSectionState();
}

class _EducationNewsSectionState extends State<EducationNewsSection> {
  List<NewsItem> _news = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final news = await NewsService.instance.fetchEducationNews();
    if (mounted) {
      setState(() {
        _news = news;
        _loading = false;
      });
    }
  }

  void _open(NewsItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NewsDetailScreen(item: item)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 26),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (_news.isEmpty) return const SizedBox.shrink();

    final colors = AppColors.of(context);
    final feature = _news.first;
    final rest = _news.skip(1).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Education News'),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Column(
            children: [
              _FeatureCard(item: feature, colors: colors, onTap: () => _open(feature)),
              if (rest.isNotEmpty) const SizedBox(height: 12),
              if (rest.isNotEmpty)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cols = constraints.maxWidth > 560 ? 3 : 2;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: rest.length,
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        mainAxisExtent: 196,
                      ),
                      itemBuilder: (context, i) {
                        final n = rest[i];
                        return _NewsCard(
                          item: n,
                          colors: colors,
                          onTap: () => _open(n),
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shared rounded thumbnail with placeholder/error fallback.
class _Thumb extends StatelessWidget {
  final String? url;
  final double aspectRatio;
  final ThemeColors colors;

  const _Thumb({
    required this.url,
    required this.aspectRatio,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: (url != null && url!.isNotEmpty)
          ? CachedNetworkImage(
              imageUrl: url!,
              fit: BoxFit.cover,
              placeholder: (_, _) => _ph(),
              errorWidget: (_, _, _) => _ph(),
            )
          : _ph(),
    );
  }

  Widget _ph() => Container(
    color: colors.primary.withValues(alpha: 0.08),
    child: Center(
      child: Icon(
        Icons.newspaper_outlined,
        color: colors.primary.withValues(alpha: 0.6),
        size: 30,
      ),
    ),
  );
}

class _MetaRow extends StatelessWidget {
  final NewsItem item;
  final ThemeColors colors;

  const _MetaRow({required this.item, required this.colors});

  @override
  Widget build(BuildContext context) {
    final time = item.published != null
        ? timeago.format(item.published!)
        : '';
    return Row(
      children: [
        Text(
          item.source,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: colors.primary,
          ),
        ),
        if (time.isNotEmpty) ...[
          Text(
            '  •  ',
            style: TextStyle(fontSize: 10.5, color: colors.textHint),
          ),
          Expanded(
            child: Text(
              time,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10.5, color: colors.textHint),
            ),
          ),
        ],
      ],
    );
  }
}

BoxDecoration _cardDeco(ThemeColors colors) => BoxDecoration(
  color: colors.surface,
  borderRadius: BorderRadius.circular(8),
  border: Border.all(color: colors.border),
  boxShadow: [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.08),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ],
);

class _FeatureCard extends StatelessWidget {
  final NewsItem item;
  final ThemeColors colors;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.item,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: _cardDeco(colors),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Thumb(url: item.imageUrl, aspectRatio: 16 / 9, colors: colors),
            Padding(
              padding: const EdgeInsets.all(11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 7),
                  _MetaRow(item: item, colors: colors),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsItem item;
  final ThemeColors colors;
  final VoidCallback onTap;

  const _NewsCard({
    required this.item,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: _cardDeco(colors),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Thumb(url: item.imageUrl, aspectRatio: 16 / 9, colors: colors),
            Padding(
              padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      height: 1.22,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  _MetaRow(item: item, colors: colors),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
