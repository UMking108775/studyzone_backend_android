import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../config/app_theme.dart';
import '../../models/category_model.dart';
import '../../services/pinned_category_service.dart';

/// A small pin/unpin toggle for a category. Used on category cards and accordion
/// rows so a user can pin either kind to the home "Recently Visited" strip.
///
/// Self-contained: it reads/writes [PinnedCategoryService] and shows a brief
/// confirmation snackbar. [onChanged] lets a parent (e.g. the home grid) refresh
/// the pinned strip immediately.
class CategoryPinButton extends StatefulWidget {
  final CategoryModel category;
  final VoidCallback? onChanged;

  /// Visual style: a filled translucent chip (for image overlays) or a bare
  /// icon (for list rows).
  final bool overlay;
  final double iconSize;

  const CategoryPinButton({
    super.key,
    required this.category,
    this.onChanged,
    this.overlay = false,
    this.iconSize = 18,
  });

  @override
  State<CategoryPinButton> createState() => _CategoryPinButtonState();
}

class _CategoryPinButtonState extends State<CategoryPinButton> {
  final PinnedCategoryService _service = PinnedCategoryService();
  bool _pinned = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await _service.isPinned(widget.category.id);
    if (mounted) setState(() => _pinned = p);
  }

  Future<void> _toggle() async {
    if (_busy) return;
    _busy = true;
    final nowPinned = await _service.toggle(widget.category);
    if (!mounted) return;
    setState(() => _pinned = nowPinned);
    _busy = false;
    widget.onChanged?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        content: Text(
          nowPinned ? 'Pinned to home' : 'Unpinned',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final icon = _pinned ? LucideIcons.pin_off : LucideIcons.pin;

    if (widget.overlay) {
      // Compact chip suitable for sitting on top of a category image.
      return GestureDetector(
        onTap: _toggle,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _pinned
                ? colors.primary
                : Colors.black.withValues(alpha: 0.45),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: widget.iconSize, color: Colors.white),
        ),
      );
    }

    return IconButton(
      onPressed: _toggle,
      visualDensity: VisualDensity.compact,
      tooltip: _pinned ? 'Unpin from home' : 'Pin to home',
      icon: Icon(
        icon,
        size: widget.iconSize,
        color: _pinned ? colors.primary : colors.textHint,
      ),
    );
  }
}
