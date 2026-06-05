import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../config/app_theme.dart';

/// The four primary destinations of the app, shown in [StudyZoneBottomNav].
enum StudyZoneTab { home, search, discover, profile }

/// Shared bottom navigation bar used by the main shell. Modern, theme-aware,
/// and built on the Lucide icon set (not Material) so it matches the rest of
/// the redesigned shell.
class StudyZoneBottomNav extends StatelessWidget {
  final StudyZoneTab current;
  final ValueChanged<StudyZoneTab> onSelect;

  const StudyZoneBottomNav({
    super.key,
    required this.current,
    required this.onSelect,
  });

  static const _items = <_NavItem>[
    _NavItem(StudyZoneTab.home, LucideIcons.house, 'Home'),
    _NavItem(StudyZoneTab.search, LucideIcons.search, 'Search'),
    _NavItem(StudyZoneTab.discover, LucideIcons.compass, 'Discover'),
    _NavItem(StudyZoneTab.profile, LucideIcons.user, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _items
                .map(
                  (item) => _NavButton(
                    item: item,
                    selected: item.tab == current,
                    colors: colors,
                    onTap: () => onSelect(item.tab),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final StudyZoneTab tab;
  final IconData icon;
  final String label;
  const _NavItem(this.tab, this.icon, this.label);
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final ThemeColors colors;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = colors.primary;
    final inactiveColor = colors.textHint;

    return Expanded(
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        highlightColor: activeColor.withValues(alpha: 0.06),
        splashColor: activeColor.withValues(alpha: 0.10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: BoxDecoration(
                color: selected
                    ? activeColor.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                item.icon,
                size: 22,
                color: selected ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 11,
                height: 1,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
