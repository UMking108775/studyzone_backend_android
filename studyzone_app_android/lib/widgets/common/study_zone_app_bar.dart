import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import '../../config/app_routes.dart';
import '../../providers/notification_provider.dart';

/// Shared top app bar used across the whole app: the horizontal Study Zone logo
/// (on a white pill so it reads on any background) and a notification bell with
/// an unread badge. Leading auto-resolves to a menu button (when [onMenu] is
/// given) or a back button (when the route can pop).
class StudyZoneAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// When provided, shows a hamburger that opens the drawer (main shell).
  final VoidCallback? onMenu;
  final bool showBell;

  const StudyZoneAppBar({super.key, this.onMenu, this.showBell = true});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    Widget? leading;
    if (onMenu != null) {
      leading = IconButton(
        icon: const Icon(LucideIcons.menu),
        onPressed: onMenu,
        tooltip: 'Menu',
      );
    } else if (canPop) {
      leading = IconButton(
        icon: const Icon(LucideIcons.arrow_left),
        onPressed: () => Navigator.of(context).maybePop(),
        tooltip: 'Back',
      );
    }

    return AppBar(
      automaticallyImplyLeading: false,
      leading: leading,
      titleSpacing: leading == null ? 16 : 0,
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Image.asset(
          'assets/images/studyzonelogo-horizental.png',
          height: 26,
          fit: BoxFit.contain,
        ),
      ),
      actions: [
        if (showBell) const _NotificationBell(),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        final hasUnread = provider.unreadCount > 0;
        return IconButton(
          tooltip: 'Notifications',
          icon: Badge(
            isLabelVisible: hasUnread,
            label: Text('${provider.unreadCount}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            child: Icon(
              LucideIcons.bell,
              color: hasUnread ? Colors.amber : null,
            ),
          ),
          onPressed: () {
            Navigator.pushNamed(
              context,
              AppRoutes.notifications,
            ).then((_) => provider.fetchUnreadCount());
          },
        );
      },
    );
  }
}
