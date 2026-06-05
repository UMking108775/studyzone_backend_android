import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../config/app_theme.dart';
import '../../models/category_model.dart';
import '../../models/content_model.dart';
import '../../services/category_service.dart';
import '../../services/content_service.dart';
import 'content_type_sections.dart';

/// Renders a list of categories as an inline, expandable accordion tree
/// (instead of pushing a new screen per level). Each node lazy-loads its own
/// subcategories and content the first time it is expanded, and recurses for
/// any depth. Leaf content is grouped by type via [ContentTypeSections].
class CategoryAccordion extends StatelessWidget {
  final List<CategoryModel> categories;
  final void Function(ContentModel) onOpenContent;

  const CategoryAccordion({
    super.key,
    required this.categories,
    required this.onOpenContent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: categories
          .map(
            (c) => CategoryAccordionNode(
              key: ValueKey('cat_${c.id}'),
              category: c,
              onOpenContent: onOpenContent,
            ),
          )
          .toList(),
    );
  }
}

class CategoryAccordionNode extends StatefulWidget {
  final CategoryModel category;
  final void Function(ContentModel) onOpenContent;

  const CategoryAccordionNode({
    super.key,
    required this.category,
    required this.onOpenContent,
  });

  @override
  State<CategoryAccordionNode> createState() => _CategoryAccordionNodeState();
}

class _CategoryAccordionNodeState extends State<CategoryAccordionNode> {
  final CategoryService _categoryService = CategoryService();
  final ContentService _contentService = ContentService();

  bool _loaded = false;
  bool _loading = false;
  List<CategoryModel> _subcategories = [];
  List<ContentModel> _contents = [];

  Future<void> _load() async {
    if (_loaded || _loading) return;
    setState(() => _loading = true);

    final subsResp = await _categoryService.getSubcategories(
      widget.category.id,
    );
    final contentResp = await _contentService.getContentsByCategory(
      widget.category.id,
    );

    if (!mounted) return;
    setState(() {
      _subcategories = subsResp.data ?? [];
      _contents = contentResp.data ?? [];
      _loaded = true;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          onExpansionChanged: (expanded) {
            if (expanded) _load();
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(LucideIcons.folder, color: colors.primary, size: 19),
          ),
          title: Text(
            widget.category.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          children: _buildChildren(colors),
        ),
      ),
    );
  }

  List<Widget> _buildChildren(ThemeColors colors) {
    if (_loading) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ];
    }

    if (_loaded && _subcategories.isEmpty && _contents.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Nothing here yet.',
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
        ),
      ];
    }

    return [
      // Direct content, grouped by type.
      if (_contents.isNotEmpty)
        ContentTypeSections(
          contents: _contents,
          onOpen: widget.onOpenContent,
        ),
      // Nested subcategories — recurse for any depth.
      ..._subcategories.map(
        (sub) => CategoryAccordionNode(
          key: ValueKey('cat_${sub.id}'),
          category: sub,
          onOpenContent: widget.onOpenContent,
        ),
      ),
    ];
  }
}
