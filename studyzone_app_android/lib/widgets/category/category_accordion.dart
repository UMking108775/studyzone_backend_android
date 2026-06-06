import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../config/app_theme.dart';
import '../../models/category_model.dart';
import '../../models/content_model.dart';
import '../../services/category_service.dart';
import '../../services/content_service.dart';
import '../common/breadcrumbs.dart';
import 'content_list.dart';
import 'request_access_sheet.dart';

/// How many levels the accordion nests inline before deeper categories "re-root"
/// into a fresh screen. `depth` is RELATIVE to the first accordion level.
///
/// The accordion appears on a level-3 screen and shows that screen's CHILDREN,
/// so relative depth 0 == absolute level 4. With a cap of 2 the inline depths
/// are 0 and 1 (absolute levels 4 and 5); a child at depth 2 (absolute level 6)
/// becomes a tappable re-root row that opens a NEW screen — so a single screen
/// never nests more than a couple of levels and deep trees stay readable.
const int kMaxInlineAccordionDepth = 2;

/// Renders a list of categories as an inline, expandable accordion tree. Each
/// node lazy-loads its own subcategories and content the first time it is
/// expanded. Nesting is capped at [kMaxInlineAccordionDepth]; deeper categories
/// call [onOpenCategory] (with the full breadcrumb trail to use) to re-root into
/// a new screen. Leaf content is grouped by type.
class CategoryAccordion extends StatelessWidget {
  final List<CategoryModel> categories;
  final void Function(ContentModel) onOpenContent;

  /// Open [category] in a new screen, using [parentBreadcrumbs] as its parent
  /// trail (already includes every inline ancestor, so the trail stays unbroken).
  final void Function(CategoryModel category, List<BreadcrumbItem> parentBreadcrumbs)
      onOpenCategory;

  /// Relative accordion depth of [categories] (0 == the first accordion level).
  final int depth;

  /// Breadcrumb trail of the inline ancestors above [categories] (begins with
  /// the host screen's breadcrumbs). Used to build correct trails on re-root.
  final List<BreadcrumbItem> trail;

  const CategoryAccordion({
    super.key,
    required this.categories,
    required this.onOpenContent,
    required this.onOpenCategory,
    required this.trail,
    this.depth = 0,
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
              onOpenCategory: onOpenCategory,
              trail: trail,
              depth: depth,
            ),
          )
          .toList(),
    );
  }
}

class CategoryAccordionNode extends StatefulWidget {
  final CategoryModel category;
  final void Function(ContentModel) onOpenContent;
  final void Function(CategoryModel category, List<BreadcrumbItem> parentBreadcrumbs)
      onOpenCategory;
  final List<BreadcrumbItem> trail;
  final int depth;

  const CategoryAccordionNode({
    super.key,
    required this.category,
    required this.onOpenContent,
    required this.onOpenCategory,
    required this.trail,
    this.depth = 0,
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

    // Locked (paid) node — don't expand; offer request-access instead.
    if (widget.category.isLocked) {
      return _ReRootRow(
        category: widget.category,
        locked: true,
        subtitle: 'Locked — tap to request access',
        onTap: () => RequestAccessSheet.show(context, widget.category),
      );
    }

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
          onExpansionChanged: (expanded) {
            if (expanded) _load();
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          leading: _FolderIcon(icon: LucideIcons.folder, color: colors.primary),
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
          padding: EdgeInsets.symmetric(vertical: 14),
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
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            'Nothing here yet.',
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
        ),
      ];
    }

    // Past the inline cap, deeper subcategories open a fresh screen instead of
    // nesting further (keeps deep trees from collapsing into a sliver).
    final nextDepth = widget.depth + 1;
    final reRoot = nextDepth >= kMaxInlineAccordionDepth;
    // The breadcrumb trail the CHILDREN sit under = this node's trail + itself.
    final childTrail = <BreadcrumbItem>[
      ...widget.trail,
      BreadcrumbItem(title: widget.category.title, category: widget.category),
    ];

    return [
      // Direct content, shown as-is in sort order (no type grouping).
      if (_contents.isNotEmpty)
        ContentList(
          contents: _contents,
          onOpen: widget.onOpenContent,
        ),
      // Nested subcategories — recurse inline until the cap, then re-root.
      ..._subcategories.map((sub) {
        if (!reRoot) {
          return CategoryAccordionNode(
            key: ValueKey('cat_${sub.id}'),
            category: sub,
            onOpenContent: widget.onOpenContent,
            onOpenCategory: widget.onOpenCategory,
            trail: childTrail,
            depth: nextDepth,
          );
        }
        if (sub.isLocked) {
          return _ReRootRow(
            category: sub,
            locked: true,
            subtitle: 'Locked — tap to request access',
            onTap: () => RequestAccessSheet.show(context, sub),
          );
        }
        return _ReRootRow(
          category: sub,
          onTap: () => widget.onOpenCategory(sub, childTrail),
        );
      }),
    ];
  }
}

/// Compact 32×32 tinted folder icon used by accordion nodes and re-root rows.
class _FolderIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _FolderIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 17),
    );
  }
}

/// A tappable, non-expanding row that opens a category in a NEW screen (used
/// for re-rooting past the inline depth cap) or, when [locked], to request
/// access. Visually matches an accordion node but ends in a chevron to signal
/// "opens a new screen".
class _ReRootRow extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;
  final bool locked;
  final String? subtitle;

  const _ReRootRow({
    required this.category,
    required this.onTap,
    this.locked = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        minLeadingWidth: 0,
        horizontalTitleGap: 10,
        leading: _FolderIcon(
          icon: locked ? LucideIcons.lock : LucideIcons.folder,
          color: locked ? colors.textSecondary : colors.primary,
        ),
        title: Text(
          category.title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle!,
                style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
              ),
        trailing: Icon(
          LucideIcons.chevron_right,
          size: 18,
          color: colors.textHint,
        ),
      ),
    );
  }
}
