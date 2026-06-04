import 'package:flutter/material.dart';

/// Modern hamburger menu button: three rounded bars, the middle one shorter,
/// left-aligned. Cleaner than the default Icons.menu.
class ModernMenuButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color? color;

  const ModernMenuButton({super.key, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final barColor =
        color ?? Theme.of(context).appBarTheme.foregroundColor ?? Colors.white;

    Widget bar(double width) => Container(
      width: width,
      height: 2.4,
      decoration: BoxDecoration(
        color: barColor,
        borderRadius: BorderRadius.circular(3),
      ),
    );

    return IconButton(
      onPressed: onTap,
      splashRadius: 22,
      icon: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bar(22),
          const SizedBox(height: 5),
          bar(13),
          const SizedBox(height: 5),
          bar(22),
        ],
      ),
    );
  }
}
