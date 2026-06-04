import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_theme.dart';
import '../../services/news_service.dart';
import 'section_header.dart';

/// "Education News" multi-grid section. Pulls Pakistan education headlines from
/// a free, keyless Google News RSS feed. Hidden if nothing loads.
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

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Education News'),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _news.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (context, i) {
              final n = _news[i];
              return _NewsCard(
                item: n,
                colors: colors,
                onTap: () => _open(n.link),
              );
            },
          ),
        ),
      ],
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
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
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
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.article_outlined, size: 15, color: colors.primary),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    item.source.isNotEmpty ? item.source : 'News',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: colors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                item.title,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                  color: colors.textPrimary,
                ),
              ),
            ),
            if (item.published != null) ...[
              const SizedBox(height: 6),
              Text(
                timeago.format(item.published!),
                style: TextStyle(fontSize: 10, color: colors.textHint),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
