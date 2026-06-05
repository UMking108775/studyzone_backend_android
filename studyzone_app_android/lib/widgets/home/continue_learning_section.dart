import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/content_model.dart';
import '../../services/recent_content_service.dart';
import '../../screens/material/material_detail_screen.dart';
import '../../screens/material/rich_text_screen.dart';
import '../../screens/video/video_player_screen.dart';

/// "Continue learning" — a horizontal strip of recently opened materials.
/// Renders nothing when there's no history.
class ContinueLearningSection extends StatefulWidget {
  const ContinueLearningSection({super.key});

  @override
  State<ContinueLearningSection> createState() =>
      ContinueLearningSectionState();
}

class ContinueLearningSectionState extends State<ContinueLearningSection> {
  final RecentContentService _service = RecentContentService();
  List<ContentModel> _items = [];

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    final items = await _service.get();
    if (mounted) setState(() => _items = items);
  }

  void _open(ContentModel content) {
    Widget screen;
    if (content.isRichText) {
      screen = RichTextScreen(content: content);
    } else if (content.isVideo) {
      screen = VideoPlayerScreen(content: content);
    } else {
      screen = MaterialDetailScreen(content: content);
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) => reload());
  }

  IconData _icon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'video':
        return Icons.play_circle_outline;
      case 'audio':
        return Icons.audiotrack_outlined;
      case 'rich_text':
      case 'article':
        return Icons.article_outlined;
      case 'image':
        return Icons.image_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  Color _color(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return const Color(0xFFE53935);
      case 'video':
        return const Color(0xFF8E24AA);
      case 'audio':
        return const Color(0xFF00ACC1);
      case 'rich_text':
      case 'article':
        return const Color(0xFF3949AB);
      default:
        return const Color(0xFF607D8B);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();
    final colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
          child: Text(
            'Continue learning',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final c = _items[i];
              final color = _color(c.contentType);
              return GestureDetector(
                onTap: () => _open(c),
                child: Container(
                  width: 180,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(_icon(c.contentType), color: color, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.title,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              c.typeDisplayName,
                              style: TextStyle(fontSize: 10.5, color: color),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
