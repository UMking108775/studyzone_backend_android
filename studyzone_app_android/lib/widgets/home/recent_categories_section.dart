import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/category_model.dart';
import '../../services/recent_category_service.dart';
import 'section_header.dart';

/// Horizontal "Recently Visited" strip of the last-level categories the user
/// opened. Hidden when there is nothing to show.
class RecentCategoriesSection extends StatefulWidget {
  final void Function(CategoryModel category) onOpen;

  const RecentCategoriesSection({super.key, required this.onOpen});

  @override
  State<RecentCategoriesSection> createState() =>
      RecentCategoriesSectionState();
}

class RecentCategoriesSectionState extends State<RecentCategoriesSection> {
  final RecentCategoryService _service = RecentCategoryService();
  List<CategoryModel> _items = [];

  @override
  void initState() {
    super.initState();
    reload();
  }

  /// Public so the home screen can refresh after returning from a category.
  Future<void> reload() async {
    final items = await _service.getRecent();
    if (mounted) setState(() => _items = items);
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();
    final colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Recently Visited'),
        SizedBox(
          height: 116,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 4),
            itemCount: _items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final c = _items[index];
              return _RecentCard(
                category: c,
                colors: colors,
                onTap: () => widget.onOpen(c),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RecentCard extends StatelessWidget {
  final CategoryModel category;
  final ThemeColors colors;
  final VoidCallback onTap;

  const _RecentCard({
    required this.category,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 112,
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
              child: SizedBox(
                height: 64,
                child: category.image != null && category.image!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: category.image!,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => _placeholder(),
                        placeholder: (_, _) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              child: Text(
                category.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: colors.primary.withValues(alpha: 0.06),
    padding: const EdgeInsets.all(12),
    child: Image.asset(
      'assets/images/default-category.png',
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) =>
          Icon(Icons.folder_open, size: 26, color: colors.primary),
    ),
  );
}
