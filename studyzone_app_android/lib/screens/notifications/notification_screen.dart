import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../config/app_theme.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../services/notification_navigator.dart';
import '../../widgets/common/study_zone_app_bar.dart';

/// Modern notification centre: a gradient summary header, All / Unread filter,
/// date-grouped sections (Today / Yesterday / This Week / Earlier) and tappable
/// cards that deep-link to the relevant category (re-checking access) or open
/// the message. Each card animates in with a subtle staggered fade + slide.
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _unreadOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications(refresh: true);
    });
  }

  Future<void> _handleRefresh() =>
      context.read<NotificationProvider>().fetchNotifications(refresh: true);

  /// Buckets notifications into ordered date sections.
  List<_Row> _buildRows(List<NotificationModel> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));

    final groups = <String, List<NotificationModel>>{
      'Today': [],
      'Yesterday': [],
      'This Week': [],
      'Earlier': [],
    };

    for (final n in items) {
      final d = DateTime(
        n.createdAt.year,
        n.createdAt.month,
        n.createdAt.day,
      );
      if (!d.isBefore(today)) {
        groups['Today']!.add(n);
      } else if (d == yesterday) {
        groups['Yesterday']!.add(n);
      } else if (d.isAfter(weekAgo)) {
        groups['This Week']!.add(n);
      } else {
        groups['Earlier']!.add(n);
      }
    }

    final rows = <_Row>[];
    groups.forEach((label, list) {
      if (list.isEmpty) return;
      rows.add(_Row.header(label));
      rows.addAll(list.map(_Row.item));
    });
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: const StudyZoneAppBar(),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          final all = provider.notifications;
          final visible = _unreadOnly
              ? all.where((n) => !n.isRead).toList()
              : all;
          final rows = _buildRows(visible);

          return Column(
            children: [
              _SummaryHeader(
                unread: provider.unreadCount,
                total: all.length,
                unreadOnly: _unreadOnly,
                onToggleFilter: (v) => setState(() => _unreadOnly = v),
                onMarkAll: provider.unreadCount == 0
                    ? null
                    : () => provider.markAllAsRead(),
              ),
              Expanded(
                child: _buildBody(context, provider, rows),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    NotificationProvider provider,
    List<_Row> rows,
  ) {
    if (provider.isLoading && provider.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (rows.isEmpty) {
      return _EmptyState(unreadOnly: _unreadOnly);
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: rows.length,
        itemBuilder: (context, index) {
          final row = rows[index];
          if (row.isHeader) {
            return _SectionLabel(text: row.header!);
          }
          return _FadeSlideIn(
            // Index keys the small entrance delay; once mounted it plays once.
            delayMs: (index * 35).clamp(0, 350),
            child: _NotificationCard(
              notification: row.item!,
              onTap: () =>
                  NotificationNavigator.handleTap(context, row.item!),
            ),
          );
        },
      ),
    );
  }
}

/// A list row is either a section header or a notification.
class _Row {
  final String? header;
  final NotificationModel? item;
  _Row.header(this.header) : item = null;
  _Row.item(this.item) : header = null;
  bool get isHeader => header != null;
}

// ─────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────

class _SummaryHeader extends StatelessWidget {
  final int unread;
  final int total;
  final bool unreadOnly;
  final ValueChanged<bool> onToggleFilter;
  final VoidCallback? onMarkAll;

  const _SummaryHeader({
    required this.unread,
    required this.total,
    required this.unreadOnly,
    required this.onToggleFilter,
    required this.onMarkAll,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final hasUnread = unread > 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, colors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  hasUnread ? LucideIcons.bell_ring : LucideIcons.bell,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasUnread
                          ? "You have $unread unread message${unread == 1 ? '' : 's'}"
                          : "You're all caught up",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _FilterChip(
                label: 'All',
                count: total,
                selected: !unreadOnly,
                onTap: () => onToggleFilter(false),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Unread',
                count: unread,
                selected: unreadOnly,
                onTap: () => onToggleFilter(true),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onMarkAll,
                icon: const Icon(LucideIcons.check_check, size: 15),
                label: const Text('Read all',
                    style: TextStyle(fontSize: 12.5)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white.withValues(alpha: 0.4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          count > 0 ? '$label ($count)' : label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: selected
                ? AppColors.of(context).primary
                : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: colors.textHint,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Card
// ─────────────────────────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final unread = !notification.isRead;
    final accent = _typeColor(notification.type, colors);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: unread
            ? accent.withValues(alpha: 0.06)
            : colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unread
              ? accent.withValues(alpha: 0.28)
              : colors.border,
          width: unread ? 1 : 0.6,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Unread accent stripe.
                  Container(
                    width: 4,
                    color: unread ? accent : Colors.transparent,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(13),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Leading(notification: notification, accent: accent),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notification.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: unread
                                              ? FontWeight.w700
                                              : FontWeight.w600,
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (unread) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: accent,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  notification.message,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.35,
                                    color: colors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      LucideIcons.clock,
                                      size: 11,
                                      color: colors.textHint,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      timeago.format(notification.createdAt),
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: colors.textHint,
                                      ),
                                    ),
                                    if (notification.categoryId != null) ...[
                                      const Spacer(),
                                      Row(
                                        children: [
                                          Text(
                                            'Open',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: accent,
                                            ),
                                          ),
                                          Icon(
                                            LucideIcons.chevron_right,
                                            size: 13,
                                            color: accent,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Leading glyph: a content-type image from assets when we can infer one
/// (PDF / video / audio / quiz / document / new category), otherwise a tinted
/// Lucide icon chosen from the notification type.
class _Leading extends StatelessWidget {
  final NotificationModel notification;
  final Color accent;

  const _Leading({required this.notification, required this.accent});

  @override
  Widget build(BuildContext context) {
    final asset = _assetFor(notification);
    if (asset != null) {
      return Container(
        width: 42,
        height: 42,
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Image.asset(asset, fit: BoxFit.contain),
      );
    }
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(_typeIcon(notification.type), color: accent, size: 20),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool unreadOnly;
  const _EmptyState({required this.unreadOnly});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: colors.info.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              unreadOnly ? LucideIcons.check_check : LucideIcons.bell_off,
              size: 38,
              color: colors.info,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            unreadOnly ? 'No unread notifications' : 'No notifications yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            unreadOnly
                ? "You're all caught up!"
                : "We'll let you know when something arrives.",
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Entrance animation
// ─────────────────────────────────────────────────────────────────────────

class _FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int delayMs;
  const _FadeSlideIn({required this.child, this.delayMs = 0});

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final Animation<double> _fade =
      CurvedAnimation(parent: _c, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.08),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Shared type → icon / colour / asset helpers
// ─────────────────────────────────────────────────────────────────────────

Color _typeColor(String type, ThemeColors colors) {
  switch (type) {
    case 'success':
      return colors.success;
    case 'warning':
      return colors.warning;
    case 'error':
      return colors.error;
    case 'announcement':
      return colors.primary;
    default:
      return colors.info;
  }
}

IconData _typeIcon(String type) {
  switch (type) {
    case 'success':
      return LucideIcons.circle_check;
    case 'warning':
      return LucideIcons.triangle_alert;
    case 'error':
      return LucideIcons.octagon_alert;
    case 'announcement':
      return LucideIcons.megaphone;
    default:
      return LucideIcons.info;
  }
}

/// Best-effort mapping of a notification to one of the bundled content icons.
/// Returns null when no specific asset fits (the caller falls back to a Lucide
/// glyph). Order matters: the most specific content type wins.
String? _assetFor(NotificationModel n) {
  final t = '${n.title} ${n.message}'.toLowerCase();
  if (t.contains('pdf')) return 'assets/images/pdf.png';
  if (t.contains('video')) return 'assets/images/video.png';
  if (t.contains('audio') || t.contains('mp3') || t.contains('lecture')) {
    return 'assets/images/mp3.png';
  }
  if (t.contains('quiz') || t.contains('flashcard')) {
    return 'assets/images/quiz.png';
  }
  if (t.contains('document') || t.contains('notes') || t.contains('text')) {
    return 'assets/images/txt-file.png';
  }
  // New category / subject / chapter / topic that points at a category.
  if (n.categoryId != null &&
      (t.contains('added') ||
          t.contains('categor') ||
          t.contains('subject') ||
          t.contains('chapter') ||
          t.contains('topic'))) {
    return 'assets/images/category-folder.png';
  }
  return null;
}
