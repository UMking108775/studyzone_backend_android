import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/content_model.dart';
import '../home/material_card.dart';

/// Groups a category's content by type into collapsible "folders" (PDFs,
/// Videos, Audio, Notes, …) so a mixed category isn't shown as one jumbled
/// list. Each folder expands to reveal its items.
class ContentTypeSections extends StatelessWidget {
  final List<ContentModel> contents;
  final void Function(ContentModel) onOpen;

  const ContentTypeSections({
    super.key,
    required this.contents,
    required this.onOpen,
  });

  /// Folder display order.
  static const List<String> _order = [
    'pdf',
    'video',
    'audio',
    'notes',
    'ppt',
    'doc',
    'image',
    'zip',
    'link',
    'other',
  ];

  String _bucket(ContentModel c) {
    final t = c.contentType.toLowerCase();
    if (t == 'rich_text' || t == 'richtext' || t == 'article') return 'notes';
    if (_order.contains(t)) return t;
    return 'other';
  }

  @override
  Widget build(BuildContext context) {
    // Group, preserving original order within each bucket.
    final groups = <String, List<ContentModel>>{};
    for (final c in contents) {
      groups.putIfAbsent(_bucket(c), () => []).add(c);
    }

    final orderedKeys = _order.where(groups.containsKey).toList();
    // Auto-expand when there's only a single folder.
    final single = orderedKeys.length == 1;

    return Column(
      children: orderedKeys
          .map(
            (key) => _TypeFolder(
              bucket: key,
              items: groups[key]!,
              onOpen: onOpen,
              initiallyExpanded: single,
            ),
          )
          .toList(),
    );
  }
}

class _TypeFolder extends StatelessWidget {
  final String bucket;
  final List<ContentModel> items;
  final void Function(ContentModel) onOpen;
  final bool initiallyExpanded;

  const _TypeFolder({
    required this.bucket,
    required this.items,
    required this.onOpen,
    required this.initiallyExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final meta = _meta(bucket);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: meta.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(meta.icon, color: meta.color, size: 18),
          ),
          title: Text(
            meta.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          subtitle: Text(
            '${items.length} item${items.length == 1 ? '' : 's'}',
            style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
          ),
          children: items
              .map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: MaterialCard(content: c, onTap: () => onOpen(c)),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  _FolderMeta _meta(String bucket) {
    switch (bucket) {
      case 'pdf':
        return const _FolderMeta('PDF Documents', Icons.picture_as_pdf, Color(0xFFE53935));
      case 'video':
        return const _FolderMeta('Videos', Icons.play_circle_outline, Color(0xFF8E24AA));
      case 'audio':
        return const _FolderMeta('Audio', Icons.audiotrack_outlined, Color(0xFF00ACC1));
      case 'notes':
        return const _FolderMeta('Notes & Articles', Icons.article_outlined, Color(0xFF3949AB));
      case 'ppt':
        return const _FolderMeta('Presentations', Icons.slideshow_outlined, Color(0xFFFF7043));
      case 'doc':
        return const _FolderMeta('Documents', Icons.description_outlined, Color(0xFF1E88E5));
      case 'image':
        return const _FolderMeta('Images', Icons.image_outlined, Color(0xFF43A047));
      case 'zip':
        return const _FolderMeta('Archives', Icons.folder_zip_outlined, Color(0xFF8D6E63));
      case 'link':
        return const _FolderMeta('Links', Icons.link, Color(0xFF5C6BC0));
      default:
        return const _FolderMeta('Other Files', Icons.insert_drive_file_outlined, Color(0xFF607D8B));
    }
  }
}

class _FolderMeta {
  final String label;
  final IconData icon;
  final Color color;
  const _FolderMeta(this.label, this.icon, this.color);
}
