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

/// Notification bell with an unread badge that periodically *rings* (a short
/// pendulum wiggle, anchored at the top so it swings like a real bell) whenever
/// there are unread notifications — a lightweight, repeating attention cue.
class _NotificationBell extends StatefulWidget {
  const _NotificationBell();

  @override
  State<_NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<_NotificationBell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  // Mostly at rest, with a brief swing near the end of each cycle.
  late final Animation<double> _angle = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween(0.0), weight: 60),
    TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.20), weight: 5),
    TweenSequenceItem(tween: Tween(begin: -0.20, end: 0.20), weight: 8),
    TweenSequenceItem(tween: Tween(begin: 0.20, end: -0.14), weight: 8),
    TweenSequenceItem(tween: Tween(begin: -0.14, end: 0.10), weight: 6),
    TweenSequenceItem(tween: Tween(begin: 0.10, end: 0.0), weight: 5),
    TweenSequenceItem(tween: ConstantTween(0.0), weight: 8),
  ]).animate(_shake);

  void _sync(bool hasUnread) {
    if (hasUnread) {
      if (!_shake.isAnimating) _shake.repeat();
    } else {
      if (_shake.isAnimating) {
        _shake.stop();
        _shake.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        final hasUnread = provider.unreadCount > 0;
        // Keep the animation in step with the unread state.
        WidgetsBinding.instance.addPostFrameCallback((_) => _sync(hasUnread));

        return IconButton(
          tooltip: 'Notifications',
          icon: Badge(
            isLabelVisible: hasUnread,
            label: Text('${provider.unreadCount}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            child: AnimatedBuilder(
              animation: _angle,
              builder: (context, child) => Transform.rotate(
                angle: _angle.value,
                alignment: Alignment.topCenter,
                child: child,
              ),
              child: Icon(
                hasUnread ? LucideIcons.bell_ring : LucideIcons.bell,
                color: hasUnread ? Colors.amber : null,
              ),
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
