import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../config/app_theme.dart';
import '../../models/category_model.dart';
import '../category/category_pin_button.dart';

/// Category card widget for displaying a category item - Compact modern design
class CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback? onTap;

  /// Called after the user pins/unpins this category (e.g. to refresh the home
  /// "Recently Visited" strip). When null, no pin button is shown.
  final VoidCallback? onPinChanged;

  /// Whether to show the pin toggle on the card.
  final bool showPin;

  const CategoryCard({
    super.key,
    required this.category,
    this.onTap,
    this.onPinChanged,
    this.showPin = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter to invert colors for dark mode (makes black icons white)
    final darkFilter = const ColorFilter.matrix([
      -1,
      0,
      0,
      0,
      255,
      0,
      -1,
      0,
      0,
      255,
      0,
      0,
      -1,
      0,
      255,
      0,
      0,
      0,
      1,
      0,
    ]);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(8),
          // Clean hairline border, institutional look.
          border: Border.all(color: colors.border, width: 1),
          // Single soft downward shadow — tactile but restrained.
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.40)
                  : AppColors.primary.withValues(alpha: 0.10),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Category Image with gradient overlay
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(7),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    category.image != null
                        ? CachedNetworkImage(
                            imageUrl: category.image!,
                            fit: BoxFit.cover,
                            color: isDark ? Colors.white : null,
                            colorBlendMode: isDark ? BlendMode.srcIn : null,
                            // In dark mode, invert dark icon assets so they read
                            // on the dark surface (light assets pass through).
                            imageBuilder: (context, imageProvider) => Container(
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: imageProvider,
                                  fit: BoxFit.cover,
                                  colorFilter: isDark ? darkFilter : null,
                                ),
                              ),
                            ),
                            placeholder: (context, url) =>
                                _buildLoadingPlaceholder(colors),
                            errorWidget: (context, url, error) =>
                                _buildPlaceholder(colors),
                          )
                        : _buildPlaceholder(colors),

                    // Locked (paid) — dim the image and show a lock.
                    if (category.isLocked) ...[
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.35),
                        ),
                      ),
                      const Positioned(
                        top: 6,
                        right: 6,
                        child: _Badge(
                          icon: LucideIcons.lock,
                          label: 'Locked',
                          background: Colors.black54,
                          foreground: Colors.white,
                        ),
                      ),
                    ] else if (category.isFree)
                      const Positioned(
                        top: 6,
                        right: 6,
                        child: _Badge(
                          icon: LucideIcons.lock_open,
                          label: 'Free',
                          background: Color(0xFF10B981),
                          foreground: Colors.white,
                        ),
                      ),

                    // Pin-to-home toggle (top-left, away from state badges).
                    if (showPin)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: CategoryPinButton(
                          category: category,
                          onChanged: onPinChanged,
                          overlay: true,
                          iconSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Category Info with Arrow - Compact, with a structural top divider
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: colors.border, width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      category.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: colors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ThemeColors colors) {
    return Container(
      color: colors.primary.withValues(alpha: 0.06),
      padding: const EdgeInsets.all(14),
      child: Image.asset(
        'assets/images/default-category.png',
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) =>
            Icon(Icons.category_outlined, size: 48, color: colors.primary),
      ),
    );
  }

  Widget _buildLoadingPlaceholder(ThemeColors colors) {
    return Container(
      color: colors.background,
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}

/// Small corner badge used for Locked / Free state on a category card.
class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  const _Badge({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: foreground),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
