import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_theme.dart';
import '../models/category_model.dart';
import '../models/notification_model.dart';
import '../providers/notification_provider.dart';
import '../screens/category/category_screen.dart';
import '../services/category_service.dart';
import '../widgets/category/request_access_sheet.dart';

/// Decides what happens when a user taps a notification.
///
/// One path for the whole app: mark it read, then route to the right place —
/// re-checking access on the way so a paid category opens only for users who
/// actually have it. The server is authoritative: [CategoryService.getCategoryById]
/// returns the category only when the user may see it and flags it `isLocked`
/// when a subscription is required, so a lapsed user is sent to subscribe
/// instead of into locked material.
class NotificationNavigator {
  NotificationNavigator._();

  static final CategoryService _categories = CategoryService();

  static Future<void> handleTap(
    BuildContext context,
    NotificationModel n,
  ) async {
    // Mark read first (also refreshes the unread badge via the provider).
    if (!n.isRead) {
      context.read<NotificationProvider>().markAsRead(n.id);
    }

    // 1) Category-targeted (new material / new sub-category) → open it.
    if (n.categoryId != null) {
      await _openCategory(context, n.categoryId!);
      return;
    }

    // 2) External / web action link.
    final raw = n.actionUrl?.trim() ?? '';
    if (raw.isNotEmpty) {
      final uri = Uri.tryParse(raw);
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    // 3) Nothing to open → show the full message in a sheet.
    if (context.mounted) showDetailSheet(context, n);
  }

  static Future<void> _openCategory(BuildContext context, int categoryId) async {
    // Brief blocking spinner while we re-validate access against the server.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final res = await _categories.getCategoryById(categoryId);

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // close spinner

    if (!res.success || res.data == null) {
      // 403 (no access) or offline / not found → guide to subscribe with a
      // persistent sheet (stays up until the user dismisses it).
      RequestAccessSheet.show(context);
      return;
    }

    final CategoryModel cat = res.data!;
    if (cat.isLocked) {
      RequestAccessSheet.show(context, cat);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CategoryScreen(category: cat)),
    );
  }

  /// A read-only detail sheet for notifications that have nowhere to navigate
  /// (plain announcements, support replies, etc.). Exposed so the list can also
  /// offer a "details" affordance.
  static void showDetailSheet(BuildContext context, NotificationModel n) {
    final colors = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                n.title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                n.message,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
