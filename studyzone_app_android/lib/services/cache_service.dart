import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category_model.dart';
import '../models/content_model.dart';
import '../models/support_models.dart';

/// Central caching service for offline-first data management
class CacheService {
  // Category cache keys
  static const String _categoriesKey = 'cached_categories';
  static const String _categoriesTimestampKey = 'cached_categories_timestamp';

  // Content cache keys (per category)
  static const String _contentPrefix = 'cached_content_';
  static const String _contentTimestampPrefix = 'cached_content_timestamp_';

  // FAQ cache keys
  static const String _faqsKey = 'cached_faqs';
  static const String _faqsTimestampKey = 'cached_faqs_timestamp';

  // Support tickets cache keys
  static const String _ticketsKey = 'cached_tickets';
  static const String _ticketsTimestampKey = 'cached_tickets_timestamp';

  // Subcategories cache keys (per parent category)
  static const String _subcategoriesPrefix = 'cached_subcategories_';
  static const String _subcategoriesTimestampPrefix =
      'cached_subcategories_timestamp_';

  // Sync management
  static const String _lastSyncKey = 'last_sync_timestamp';

  // Cache expiry times (in minutes).
  // Categories/content are kept short because the app is content-driven and
  // admins expect edits to appear quickly. Background sync (every 30s) keeps
  // the working set fresh; these TTLs are the backstop for the cache-first
  // reads so navigating after an idle period re-fetches instead of showing
  // indefinitely-stale data.
  static const int _categoryCacheMinutes = 10;
  static const int _subcategoryCacheMinutes = 10;
  static const int _contentCacheMinutes = 10;
  static const int _faqCacheMinutes = 120; // 2 hours
  static const int _ticketCacheMinutes = 15; // 15 minutes

  SharedPreferences? _prefs;

  /// Initialize SharedPreferences
  Future<void> _init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // ==================== CATEGORIES ====================

  /// Cache all categories (flat list)
  Future<void> cacheCategories(List<CategoryModel> categories) async {
    await _init();
    final jsonList = categories.map((c) => c.toJson()).toList();
    await _prefs!.setString(_categoriesKey, jsonEncode(jsonList));
    await _prefs!.setInt(
      _categoriesTimestampKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Get cached categories
  Future<List<CategoryModel>?> getCachedCategories() async {
    await _init();
    final jsonStr = _prefs!.getString(_categoriesKey);
    if (jsonStr == null) return null;

    try {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList.map((j) => CategoryModel.fromJson(j)).toList();
    } catch (e) {
      return null;
    }
  }

  /// Check if categories cache is valid (not expired)
  Future<bool> isCategoriesCacheValid() async {
    await _init();
    final timestamp = _prefs!.getInt(_categoriesTimestampKey);
    if (timestamp == null) return false;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    return now.difference(cacheTime).inMinutes < _categoryCacheMinutes;
  }

  /// Check if categories cache exists (regardless of expiry)
  Future<bool> hasCachedCategories() async {
    await _init();
    return _prefs!.containsKey(_categoriesKey);
  }

  // ==================== SUBCATEGORIES (per parent) ====================

  /// Cache subcategories for a specific parent category
  Future<void> cacheSubcategories(
    int parentId,
    List<CategoryModel> subcategories,
  ) async {
    await _init();
    final jsonList = subcategories.map((c) => c.toJson()).toList();
    await _prefs!.setString(
      '$_subcategoriesPrefix$parentId',
      jsonEncode(jsonList),
    );
    await _prefs!.setInt(
      '$_subcategoriesTimestampPrefix$parentId',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Get cached subcategories for a parent category
  Future<List<CategoryModel>?> getCachedSubcategories(int parentId) async {
    await _init();
    final jsonStr = _prefs!.getString('$_subcategoriesPrefix$parentId');
    if (jsonStr == null) return null;

    try {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList.map((j) => CategoryModel.fromJson(j)).toList();
    } catch (e) {
      return null;
    }
  }

  /// Check if subcategories cache exists (regardless of expiry)
  Future<bool> hasCachedSubcategories(int parentId) async {
    await _init();
    return _prefs!.containsKey('$_subcategoriesPrefix$parentId');
  }

  /// Check if subcategories cache is valid (not expired) for a parent
  Future<bool> isSubcategoriesCacheValid(int parentId) async {
    await _init();
    final timestamp = _prefs!.getInt('$_subcategoriesTimestampPrefix$parentId');
    if (timestamp == null) return false;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(cacheTime).inMinutes <
        _subcategoryCacheMinutes;
  }

  // ==================== CONTENT (per category) ====================

  /// Cache content for a specific category
  Future<void> cacheContent(int categoryId, List<ContentModel> content) async {
    await _init();
    final jsonList = content.map((c) => c.toJson()).toList();
    await _prefs!.setString('$_contentPrefix$categoryId', jsonEncode(jsonList));
    await _prefs!.setInt(
      '$_contentTimestampPrefix$categoryId',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Get cached content for a category
  Future<List<ContentModel>?> getCachedContent(int categoryId) async {
    await _init();
    final jsonStr = _prefs!.getString('$_contentPrefix$categoryId');
    if (jsonStr == null) return null;

    try {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList.map((j) => ContentModel.fromJson(j)).toList();
    } catch (e) {
      return null;
    }
  }

  /// Check if content cache is valid for a category
  Future<bool> isContentCacheValid(int categoryId) async {
    await _init();
    final timestamp = _prefs!.getInt('$_contentTimestampPrefix$categoryId');
    if (timestamp == null) return false;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    return now.difference(cacheTime).inMinutes < _contentCacheMinutes;
  }

  /// Check if content cache exists for a category
  Future<bool> hasCachedContent(int categoryId) async {
    await _init();
    return _prefs!.containsKey('$_contentPrefix$categoryId');
  }

  /// Category ids the user has a cached content list for (i.e. has opened),
  /// ordered most-recently-cached first. Used by background sync to keep the
  /// user's working set fresh at any tree depth without re-fetching the world.
  Future<List<int>> cachedContentCategoryIds() async {
    await _init();
    final entries = <MapEntry<int, int>>[]; // (categoryId, timestamp)
    for (final key in _prefs!.getKeys()) {
      if (!key.startsWith(_contentPrefix)) continue;
      final id = int.tryParse(key.substring(_contentPrefix.length));
      if (id == null) continue;
      final ts = _prefs!.getInt('$_contentTimestampPrefix$id') ?? 0;
      entries.add(MapEntry(id, ts));
    }
    entries.sort((a, b) => b.value.compareTo(a.value)); // newest first
    return entries.map((e) => e.key).toList();
  }

  // ==================== FAQs ====================

  /// Cache FAQs
  Future<void> cacheFaqs(List<FaqModel> faqs) async {
    await _init();
    final jsonList = faqs.map((f) => f.toJson()).toList();
    await _prefs!.setString(_faqsKey, jsonEncode(jsonList));
    await _prefs!.setInt(
      _faqsTimestampKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Get cached FAQs
  Future<List<FaqModel>?> getCachedFaqs() async {
    await _init();
    final jsonStr = _prefs!.getString(_faqsKey);
    if (jsonStr == null) return null;

    try {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList.map((e) => FaqModel.fromJson(e)).toList();
    } catch (e) {
      return null;
    }
  }

  /// Check if FAQs cache is valid
  Future<bool> isFaqsCacheValid() async {
    await _init();
    final timestamp = _prefs!.getInt(_faqsTimestampKey);
    if (timestamp == null) return false;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    return now.difference(cacheTime).inMinutes < _faqCacheMinutes;
  }

  // ==================== SUPPORT TICKETS ====================

  /// Cache support tickets
  Future<void> cacheTickets(List<SupportTicket> tickets) async {
    await _init();
    final jsonList = tickets.map((t) => t.toJson()).toList();
    await _prefs!.setString(_ticketsKey, jsonEncode(jsonList));
    await _prefs!.setInt(
      _ticketsTimestampKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Get cached tickets
  Future<List<SupportTicket>?> getCachedTickets() async {
    await _init();
    final jsonStr = _prefs!.getString(_ticketsKey);
    if (jsonStr == null) return null;

    try {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList.map((e) => SupportTicket.fromJson(e)).toList();
    } catch (e) {
      return null;
    }
  }

  /// Check if tickets cache is valid
  Future<bool> isTicketsCacheValid() async {
    await _init();
    final timestamp = _prefs!.getInt(_ticketsTimestampKey);
    if (timestamp == null) return false;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    return now.difference(cacheTime).inMinutes < _ticketCacheMinutes;
  }

  // ==================== IMPORTANT LINKS ====================

  // Important Links cache keys
  static const String _importantLinksKey = 'cached_important_links';
  static const String _importantLinksTimestampKey =
      'cached_important_links_timestamp';
  static const int _importantLinksCacheMinutes = 120; // 2 hours

  /// Cache important links
  Future<void> cacheImportantLinks(List<ImportantLinkModel> links) async {
    await _init();
    final jsonList = links.map((l) => l.toJson()).toList();
    await _prefs!.setString(_importantLinksKey, jsonEncode(jsonList));
    await _prefs!.setInt(
      _importantLinksTimestampKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Get cached important links
  Future<List<ImportantLinkModel>?> getCachedImportantLinks() async {
    await _init();
    final jsonStr = _prefs!.getString(_importantLinksKey);
    if (jsonStr == null) return null;

    try {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList.map((e) => ImportantLinkModel.fromJson(e)).toList();
    } catch (e) {
      return null;
    }
  }

  /// Check if important links cache is valid
  Future<bool> isImportantLinksCacheValid() async {
    await _init();
    final timestamp = _prefs!.getInt(_importantLinksTimestampKey);
    if (timestamp == null) return false;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    return now.difference(cacheTime).inMinutes < _importantLinksCacheMinutes;
  }

  // ==================== SYNC MANAGEMENT ====================

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTime() async {
    await _init();
    final timestamp = _prefs!.getInt(_lastSyncKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// Update last sync timestamp
  Future<void> updateLastSyncTime() async {
    await _init();
    await _prefs!.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Check if sync is needed (more than 5 minutes since last sync)
  Future<bool> needsSync() async {
    final lastSync = await getLastSyncTime();
    if (lastSync == null) return true;

    final now = DateTime.now();
    return now.difference(lastSync).inMinutes >= 5;
  }

  // ==================== CACHE MANAGEMENT ====================

  /// Clear all cache (used on logout)
  Future<void> clearAllCache() async {
    await _init();
    final keys = _prefs!
        .getKeys()
        .where((k) => k.startsWith('cached_') || k == _lastSyncKey)
        .toList();

    for (final key in keys) {
      await _prefs!.remove(key);
    }
  }

  /// Clear categories cache
  Future<void> clearCategoriesCache() async {
    await _init();
    await _prefs!.remove(_categoriesKey);
    await _prefs!.remove(_categoriesTimestampKey);
  }

  /// Force invalidate categories cache (marks as expired)
  Future<void> invalidateCategoriesCache() async {
    await _init();
    await _prefs!.remove(_categoriesTimestampKey);
  }

  /// Force invalidate specific content cache
  Future<void> invalidateContentCache(int categoryId) async {
    await _init(); // Keep _init() as _getPrefs() is not defined in the provided context
    await _prefs!.remove(
      '$_contentTimestampPrefix$categoryId',
    ); // Keep original key format
  }

  /// Clear content cache for a specific category
  Future<void> clearContentCache(int categoryId) async {
    await _init(); // Keep _init() as _getPrefs() is not defined in the provided context
    await _prefs!.remove(
      '$_contentPrefix$categoryId',
    ); // Keep original key format
    await _prefs!.remove(
      '$_contentTimestampPrefix$categoryId',
    ); // Keep original key format
  }

  /// Find allowed content IDs for guest mode (1 PDF, 1 Audio)
  /// Returns a map with 'pdf' and 'audio' keys containing [categoryId, contentId]
  Future<Map<String, Map<String, int>?>> findGuestMaterials() async {
    await _init(); // Use _init() as _getPrefs() is not defined in the provided context
    final keys = _prefs!.getKeys().where(
      (k) => k.startsWith(_contentPrefix),
    ); // Use _contentPrefix

    Map<String, int>? audioMatch;
    Map<String, int>? pdfMatch;

    for (final key in keys) {
      if (audioMatch != null && pdfMatch != null) break;

      // Extract category ID from key "content_{id}"
      final categoryId = int.tryParse(key.split('_')[1]);
      if (categoryId == null) continue;

      final jsonStr = _prefs!.getString(key);
      if (jsonStr == null) continue;

      try {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        final contents = decoded
            .map((e) => ContentModel.fromJson(e as Map<String, dynamic>))
            .toList();

        for (final content in contents) {
          final type = content.contentType.toLowerCase();

          if (audioMatch == null &&
              (type.contains('audio') || type.contains('mp3'))) {
            audioMatch = {'categoryId': categoryId, 'contentId': content.id};
          } else if (pdfMatch == null &&
              (type.contains('pdf') || type.contains('document'))) {
            pdfMatch = {'categoryId': categoryId, 'contentId': content.id};
          }

          if (audioMatch != null && pdfMatch != null) break;
        }
      } catch (e) {
        // Skip malformed cache
        continue;
      }
    }

    return {'audio': audioMatch, 'pdf': pdfMatch};
  }
}
