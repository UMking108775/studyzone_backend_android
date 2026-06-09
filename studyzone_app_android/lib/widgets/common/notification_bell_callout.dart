import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../config/app_theme.dart';
import '../../providers/notification_provider.dart';

/// A floating speech-bubble that pops up just below the app-bar bell, with an
/// arrow pointing up at it, whenever unread notifications arrive. It gently
/// bobs to draw the eye, auto-hides after a few seconds, and reappears when a
/// new notification lands. Tapping it opens the notification centre.
///
/// Designed to sit in a [Stack] above the screen body, anchored top-right:
/// ```
/// Stack(children: [ body, const Positioned(top: 6, right: 6,
///   child: NotificationBellCallout()) ])
/// ```
class NotificationBellCallout extends StatefulWidget {
  const NotificationBellCallout({super.key});

  @override
  State<NotificationBellCallout> createState() =>
      _NotificationBellCalloutState();
}

class _NotificationBellCalloutState extends State<NotificationBellCallout>
    with TickerProviderStateMixin {
  static const Duration _autoHideAfter = Duration(seconds: 8);

  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  late final Animation<double> _fade =
      CurvedAnimation(parent: _enter, curve: Curves.easeOut);
  late final Animation<double> _scale = Tween<double>(
    begin: 0.82,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _enter, curve: Curves.easeOutBack));
  late final Animation<double> _bobOffset = Tween<double>(
    begin: -2.5,
    end: 2.5,
  ).animate(CurvedAnimation(parent: _bob, curve: Curves.easeInOut));

  Timer? _autoHide;
  int _lastCount = 0;
  bool _visible = false;

  void _react(int count) {
    if (count <= 0) {
      _lastCount = 0;
      if (_visible) _hide();
      return;
    }
    if (count > _lastCount) _show();
    _lastCount = count;
  }

  void _show() {
    _autoHide?.cancel();
    if (!_visible) setState(() => _visible = true);
    _enter.forward(from: 0);
    _autoHide = Timer(_autoHideAfter, _hide);
  }

  void _hide() {
    _autoHide?.cancel();
    if (!mounted || !_visible) return;
    _enter.reverse().whenComplete(() {
      if (mounted) setState(() => _visible = false);
    });
  }

  void _open() {
    _hide();
    final provider = context.read<NotificationProvider>();
    Navigator.pushNamed(context, AppRoutes.notifications)
        .then((_) => provider.fetchUnreadCount());
  }

  @override
  void dispose() {
    _autoHide?.cancel();
    _enter.dispose();
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        final count = provider.unreadCount;
        // Drive show/hide after the frame so we never setState during build.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _react(count);
        });

        if (!_visible || count <= 0) return const SizedBox.shrink();

        return FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            alignment: Alignment.topRight,
            child: AnimatedBuilder(
              animation: _bobOffset,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, _bobOffset.value),
                child: child,
              ),
              child: _Bubble(count: count, onTap: _open, onClose: _hide),
            ),
          ),
        );
      },
    );
  }
}

class _Bubble extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _Bubble({
    required this.count,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Arrow pointing up at the bell (kept near the right edge, under it).
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: CustomPaint(
            size: const Size(20, 10),
            painter: _ArrowPainter(colors.primary),
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 250),
              padding: const EdgeInsets.fromLTRB(12, 11, 8, 11),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [colors.primary, colors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.bell_ring,
                      color: Colors.amber, size: 20),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          count == 1
                              ? '1 new notification'
                              : '$count new notifications',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Tap to view',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: onClose,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        LucideIcons.x,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Small upward-pointing triangle (apex at top) used as the bubble's pointer.
class _ArrowPainter extends CustomPainter {
  final Color color;
  _ArrowPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width / 2, 0) // apex (points up at the bell)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) =>
      oldDelegate.color != color;
}
