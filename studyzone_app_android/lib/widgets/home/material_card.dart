import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/content_model.dart';

/// Material/Content card widget for displaying study material
class MaterialCard extends StatelessWidget {
  final ContentModel content;
  final VoidCallback? onTap;

  const MaterialCard({super.key, required this.content, this.onTap});

  IconData _getTypeIcon() {
    switch (content.contentType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'video':
        return Icons.play_circle_outline;
      case 'audio':
        return Icons.audiotrack_outlined;
      case 'ppt':
        return Icons.slideshow_outlined;
      case 'doc':
        return Icons.description_outlined;
      case 'image':
        return Icons.image_outlined;
      case 'zip':
        return Icons.folder_zip_outlined;
      case 'link':
        return Icons.link;
      case 'quiz':
        return Icons.quiz_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  /// Subtitle under the title: a quiz shows its question count when known,
  /// everything else shows its type name.
  String _subtitle() {
    if (content.isQuiz && content.questionCount != null) {
      final n = content.questionCount!;
      return 'Quiz · $n question${n == 1 ? '' : 's'}';
    }
    return content.typeDisplayName;
  }

  Color _getTypeColor(ThemeColors colors) {
    switch (content.contentType.toLowerCase()) {
      case 'pdf':
        return const Color(0xFFE53935);
      case 'video':
        return const Color(0xFF8E24AA);
      case 'audio':
        return const Color(0xFF00ACC1);
      case 'ppt':
        return const Color(0xFFFF7043);
      case 'doc':
        return const Color(0xFF1E88E5);
      case 'image':
        return const Color(0xFF43A047);
      case 'zip':
        return const Color(0xFF8D6E63);
      case 'link':
        return const Color(0xFF5C6BC0);
      case 'quiz':
        return const Color(0xFFFFB300); // amber
      default:
        return colors.primary;
    }
  }

  /// Custom PNG icon for the common content types (assets/images/*.png).
  /// Returns null for types without a bundled image (a coloured icon is used).
  String? _assetForType() {
    switch (content.contentType.toLowerCase()) {
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
    final colors = AppColors.of(context);
    final typeColor = _getTypeColor(colors);
    final asset = _assetForType();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            // Type icon — a bundled PNG for common types, else a coloured icon.
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: asset != null
                    ? colors.background
                    : typeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              padding: asset != null ? const EdgeInsets.all(7) : EdgeInsets.zero,
              child: asset != null
                  ? Image.asset(asset, fit: BoxFit.contain)
                  : Icon(_getTypeIcon(), color: typeColor, size: 20),
            ),
            const SizedBox(width: 12),

            // Title and Type
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitle(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      // Brand color stays on the icon chip; the label uses a
                      // neutral tone for comfortable contrast on the surface.
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
