import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/content_model.dart';
import '../../models/category_model.dart';
import '../../services/audio_service.dart';
import '../../services/download_service.dart';
import '../../services/recent_content_service.dart';
import '../../screens/audio/audio_player_screen.dart';
import '../../screens/category/category_screen.dart';
import '../../screens/material/material_detail_screen.dart';
import '../../screens/material/rich_text_screen.dart';
import '../../screens/pdf/pdf_viewer_screen.dart';
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

  Future<void> _open(ContentModel content) async {
    // Rich text / article: just open the reader (nothing to download).
    if (content.isRichText) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RichTextScreen(content: content)),
      );
      reload();
      return;
    }

    // If it's downloaded, open the saved file directly.
    final item = await DownloadService().getDownloadedItem(content.id);
    final localPath = (item != null && File(item.localPath).existsSync())
        ? item.localPath
        : null;

    if (!mounted) return;

    if (localPath != null) {
      final type = content.contentType.toLowerCase();
      if (type == 'pdf') {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PdfViewerScreen(content: content, localPath: localPath),
          ),
        );
      } else if (type == 'audio') {
        final audio = context.read<AudioService>();
        audio.initSingle(content, localPath: localPath);
        audio.play();
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AudioPlayerScreen()),
        );
      } else if (content.isVideo) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                VideoPlayerScreen(content: content, localPath: localPath),
          ),
        );
      } else {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MaterialDetailScreen(content: content)),
        );
      }
      reload();
      return;
    }

    // Not downloaded → take the user to the material's category to stream or
    // download it there. Falls back to the detail screen if no category is known.
    final cat = content.category;
    if (cat != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CategoryScreen(
            category: CategoryModel(
              id: cat.id,
              title: cat.title,
              level: cat.level,
              isActive: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
        ),
      );
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MaterialDetailScreen(content: content)),
      );
    }
    reload();
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

  /// Bundled PNG icon for common content types (assets/images/*.png).
  String? _asset(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return 'assets/images/pdf.png';
      case 'video':
        return 'assets/images/video.png';
      case 'audio':
        return 'assets/images/mp3.png';
      case 'quiz':
        return 'assets/images/quiz.png';
      case 'rich_text':
      case 'richtext':
      case 'article':
      case 'doc':
      case 'text':
      case 'txt':
        return 'assets/images/txt-file.png';
      default:
        return null;
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
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
          child: Text(
            'Continue learning',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ),
        SizedBox(
          height: 60,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final c = _items[i];
              final color = _color(c.contentType);
              final asset = _asset(c.contentType);
              return GestureDetector(
                onTap: () => _open(c),
                child: Container(
                  width: 168,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      asset != null
                          ? SizedBox(
                              width: 30,
                              height: 30,
                              child: Image.asset(asset, fit: BoxFit.contain),
                            )
                          : Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Icon(_icon(c.contentType), color: color, size: 18),
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
                                height: 1.15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              c.typeDisplayName,
                              style: TextStyle(fontSize: 10.5, color: color),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
