import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/content_model.dart';
import '../models/category_model.dart';
import '../providers/subscription_provider.dart';
import 'content_service.dart';
import 'category_service.dart';

/// Central access gate for paid material.
///
/// A user may open paid content/categories only when ONE of these holds:
///  * they have a subscription that is active *right now* (re-evaluated against
///    the clock, so it lapses even offline), or
///  * the server confirms access (covers explicit admin grants).
///
/// Free material (`requires_subscription == false`) is always open. When the
/// user is NOT a current subscriber and the item is paid, the decision is made
/// by the server and we **fail closed** — a 403 or an unreachable network both
/// block, so a lapsed subscriber can't keep opening cached/downloaded content.
class AccessGuard {
  AccessGuard._();

  /// SharedPreferences key holding the active subscription's end date (ISO).
  /// Written by [SubscriptionProvider] so the offline fast-path survives a
  /// cold start. NOTE: keep this string in sync with the provider.
  static const String activeUntilKey = 'sub_active_until';

  static const String blockedContentMessage =
      'Your plan has ended. Subscribe to access this material.';

  static final ContentService _content = ContentService();
  static final CategoryService _category = CategoryService();

  /// True if we can confirm — without the network — that the subscription is
  /// active right now. Checks the in-memory provider flag first, then a
  /// persisted end-date (so an active subscriber still works offline at cold
  /// start). Flips to false the instant the window passes.
  static Future<bool> _hasActiveSub(bool providerActive) async {
    if (providerActive) return true;
    final prefs = await SharedPreferences.getInstance();
    final iso = prefs.getString(activeUntilKey);
    if (iso == null) return false;
    final until = DateTime.tryParse(iso);
    return until != null && until.isAfter(DateTime.now());
  }

  /// Whether [content] may be opened right now. [providerActive] should be
  /// `context.read<SubscriptionProvider>().isCurrentlyActive`.
  static Future<bool> canOpenContent(
    ContentModel content, {
    required bool providerActive,
  }) async {
    // Quizzes have their own server-side gating (auth + category check).
    if (content.isQuiz) return true;
    if (await _hasActiveSub(providerActive)) return true;
    if (!content.requiresSubscription) return true; // free material is open
    // Paid + no active subscription → ask the server (authoritative; catches
    // admin grants). getContentById has no cache fallback, so a 403 or an
    // offline failure both return success=false → blocked.
    final res = await _content.getContentById(content.id);
    return res.success;
  }

  /// Whether [category] may be entered right now.
  static Future<bool> canOpenCategory(
    CategoryModel category, {
    required bool providerActive,
  }) async {
    if (await _hasActiveSub(providerActive)) return true;
    if (!category.requiresSubscription) return true;
    final res = await _category.getCategoryById(category.id);
    return res.success && res.data != null && !res.data!.isLocked;
  }
}

/// Mix into a content-viewer [State] to block paid content for lapsed users.
/// Call [guardContentAccess] from `initState` (it is fire-and-forget).
mixin ContentAccessGuard<T extends StatefulWidget> on State<T> {
  /// Re-validate access to [content]; if denied, show a message and leave the
  /// screen. Safe to call directly from `initState`.
  void guardContentAccess(ContentModel content) {
    unawaited(_runContentGuard(content));
  }

  Future<void> _runContentGuard(ContentModel content) async {
    final active = context.read<SubscriptionProvider>().isCurrentlyActive;
    final ok = await AccessGuard.canOpenContent(
      content,
      providerActive: active,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AccessGuard.blockedContentMessage)),
      );
      Navigator.of(context).maybePop();
    }
  }
}
