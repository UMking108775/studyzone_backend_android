import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../config/app_theme.dart';
import '../../models/category_model.dart';
import '../../services/pinned_category_service.dart';
import '../../services/recent_category_service.dart';
import 'section_header.dart';

/// Horizontal "Recently Visited" strip. Pinned categories appear first and are
/// highlighted (accent border + pin badge); the rest are the last-level
/// categories the user opened. Hidden when there is nothing to show.
class RecentCategoriesSection extends StatefulWidget {
  final void Function(CategoryModel category) onOpen;

  const RecentCategoriesSection({super.key, required this.onOpen});

  @override
  State<RecentCategoriesSection> createState() =>
      RecentCategoriesSectionState();
}

class RecentCategoriesSectionState extends State<RecentCategoriesSection> {
  final RecentCategoryService _recentService = RecentCategoryService();
  final PinnedCategoryService _pinnedService = PinnedCategoryService();

  List<CategoryModel> _items = [];
  Set<int> _pinnedIds = {};

  @override
  void initState() {
    super.initState();
    reload();
  }

  /// Public so the home screen can refresh after returning from a category or
  /// after a pin toggle.
  Future<void> reload() async {
    final pinned = await _pinnedService.getPinned();
    final recent = await _recentService.getRecent();
    final pinnedIds = pinned.map((c) => c.id).toSet();
    // Pinned first (fixed, prominent), then recent minus anything pinned.
    final merged = <CategoryModel>[
      ...pinned,
      ...recent.where((c) => !pinnedIds.contains(c.id)),
    ];
    if (mounted) {
      setState(() {
        _items = merged;
        _pinnedIds = pinnedIds;
      });
    }
  }

  Future<void> _togglePin(CategoryModel c) async {
    await _pinnedService.toggle(c);
    await reload();
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
          height: 124,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
            itemCount: _items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final c = _items[index];
              return _RecentCard(
                category: c,
                colors: colors,
                pinned: _pinnedIds.contains(c.id),
                onTap: () => widget.onOpen(c),
                onTogglePin: () => _togglePin(c),
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
  final bool pinned;
  final VoidCallback onTap;
  final VoidCallback onTogglePin;

  const _RecentCard({
    required this.category,
    required this.colors,
    required this.pinned,
    required this.onTap,
    required this.onTogglePin,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      // Long-press to pin/unpin straight from the strip.
      onLongPress: onTogglePin,
      child: Container(
        width: 112,
        decoration: BoxDecoration(
          color: pinned
              ? colors.primary.withValues(alpha: 0.05)
              : colors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: pinned ? colors.primary : colors.border,
            width: pinned ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary
                  .withValues(alpha: pinned ? 0.16 : 0.08),
              blurRadius: pinned ? 9 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(7)),
                  child: SizedBox(
                    height: 64,
                    width: double.infinity,
                    child: category.image != null &&
                            category.image!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: category.image!,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => _placeholder(),
                            placeholder: (_, _) => _placeholder(),
                          )
                        : _placeholder(),
                  ),
                ),
                if (pinned)
                  Positioned(
                    top: 5,
                    left: 5,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.pin,
                          size: 11, color: Colors.white),
                    ),
                  ),
              ],
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
        padding: const EdgeInsets.all(10),
        child: Image.asset(
          'assets/images/recently_visited.png',
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) =>
              Icon(Icons.folder_open, size: 26, color: colors.primary),
        ),
      );
}
