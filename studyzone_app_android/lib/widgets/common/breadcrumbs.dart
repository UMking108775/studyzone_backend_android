import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/category_model.dart';

/// Breadcrumb navigation for nested category screens. The trailing (current)
/// crumb doubles as the page title, so it is styled larger/bold. Intermediate
/// crumbs ellipsize, and the row auto-scrolls to the end so the current page is
/// always visible on deep trees (instead of being clipped off the right edge).
class Breadcrumbs extends StatefulWidget {
  final List<BreadcrumbItem> items;

  const Breadcrumbs({super.key, required this.items});

  @override
  State<Breadcrumbs> createState() => _BreadcrumbsState();
}

class _BreadcrumbsState extends State<Breadcrumbs> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _jumpToEnd();
  }

  @override
  void didUpdateWidget(covariant Breadcrumbs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) _jumpToEnd();
  }

  /// Keep the current-page crumb in view after layout.
  void _jumpToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.hasClients) {
        _controller.jumpTo(_controller.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: colors.surface,
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Home icon only (no text, more compact)
            GestureDetector(
              onTap: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: Icon(Icons.home_outlined, size: 18, color: colors.primary),
            ),

            // Breadcrumb items with "/" separator
            ...widget.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == widget.items.length - 1;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Web-style "/" separator
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      '/',
                      style: TextStyle(fontSize: 12, color: colors.textHint),
                    ),
                  ),
                  // Breadcrumb text link. Intermediate crumbs ellipsize; the
                  // last crumb is the page title (larger, bold, more room).
                  GestureDetector(
                    onTap: isLast
                        ? null
                        : () {
                            if (item.onTap != null) {
                              item.onTap!();
                            } else {
                              for (
                                int i = 0;
                                i < widget.items.length - index - 1;
                                i++
                              ) {
                                Navigator.pop(context);
                              }
                            }
                          },
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isLast ? 240 : 130,
                      ),
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isLast ? 15 : 12.5,
                          color: isLast ? colors.textPrimary : colors.primary,
                          fontWeight: isLast
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Breadcrumb item model
class BreadcrumbItem {
  final String title;
  final CategoryModel? category;
  final VoidCallback? onTap;

  BreadcrumbItem({required this.title, this.category, this.onTap});
}
